//! Request and response contract tests against the panel REST API, using a fake transport.

const std = @import("std");
const tapsilat = @import("tapsilat.zig");
const models = tapsilat.models;

const testing = std.testing;
const Allocator = std.mem.Allocator;

const base_url = "https://panel.example/api/v1";

/// Records requests and answers them with canned responses keyed by "METHOD /path".
const Fake = struct {
    allocator: Allocator,
    replies: std.StringHashMapUnmanaged(Reply) = .empty,
    requests: std.ArrayList(Recorded) = .empty,

    const Reply = struct {
        status: u16 = 200,
        content_type: []const u8 = "application/json",
        body: []const u8 = "{}",
    };

    const Recorded = struct {
        method: std.http.Method,
        path: []u8,
        query: []u8,
        authorization: []u8,
        body: ?[]u8,

        fn json(self: Recorded, allocator: Allocator) !std.json.Parsed(std.json.Value) {
            return std.json.parseFromSlice(std.json.Value, allocator, self.body.?, .{});
        }
    };

    fn init(allocator: Allocator) Fake {
        return .{ .allocator = allocator };
    }

    fn deinit(self: *Fake) void {
        var it = self.replies.keyIterator();
        while (it.next()) |key| self.allocator.free(key.*);
        self.replies.deinit(self.allocator);
        for (self.requests.items) |r| {
            self.allocator.free(r.path);
            self.allocator.free(r.query);
            self.allocator.free(r.authorization);
            if (r.body) |b| self.allocator.free(b);
        }
        self.requests.deinit(self.allocator);
    }

    fn on(self: *Fake, method: std.http.Method, path: []const u8, reply: Reply) !void {
        const key = try std.fmt.allocPrint(self.allocator, "{t} {s}", .{ method, path });
        const entry = try self.replies.getOrPut(self.allocator, key);
        if (entry.found_existing) self.allocator.free(key);
        entry.value_ptr.* = reply;
    }

    fn last(self: *Fake, method: std.http.Method, path: []const u8) ?Recorded {
        var i = self.requests.items.len;
        while (i > 0) {
            i -= 1;
            const r = self.requests.items[i];
            if (r.method == method and std.mem.eql(u8, r.path, path)) return r;
        }
        return null;
    }

    fn client(self: *Fake) tapsilat.Client {
        return tapsilat.Client.init(self.allocator, testing.io, .{
            .api_key = "test-key",
            .base_url = base_url,
            .transport = .{ .ptr = self, .sendFn = send },
        });
    }

    fn send(ptr: *anyopaque, allocator: Allocator, request: tapsilat.Transport.Request) anyerror!tapsilat.Transport.Response {
        const self: *Fake = @ptrCast(@alignCast(ptr));
        const without_host = request.url["https://panel.example".len..];
        const split = std.mem.findScalar(u8, without_host, '?');
        const path = if (split) |i| without_host[0..i] else without_host;
        const query = if (split) |i| without_host[i + 1 ..] else "";

        try self.requests.append(self.allocator, .{
            .method = request.method,
            .path = try self.allocator.dupe(u8, path),
            .query = try self.allocator.dupe(u8, query),
            .authorization = try self.allocator.dupe(u8, request.authorization),
            .body = if (request.body) |b| try self.allocator.dupe(u8, b) else null,
        });

        var key_buffer: [256]u8 = undefined;
        const key = try std.fmt.bufPrint(&key_buffer, "{t} {s}", .{ request.method, path });
        const reply = self.replies.get(key) orelse Reply{ .status = 501, .body = "{\"error\":\"no stub\"}" };
        return .{
            .status = reply.status,
            .content_type = try allocator.dupe(u8, reply.content_type),
            .body = try allocator.dupe(u8, reply.body),
        };
    }
};

fn expectJsonString(object: std.json.ObjectMap, key: []const u8, expected: []const u8) !void {
    const value = object.get(key) orelse return error.MissingField;
    try testing.expectEqualStrings(expected, value.string);
}

test "requests carry the bearer token and decode the order status" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/order/ref-1/status", .{ .body = "{\"status\":\"Paid\"}" });

    const status = try client.orders().getStatus("ref-1");
    defer status.deinit();

    try testing.expectEqualStrings("Paid", status.value.status.?);
    try testing.expectEqualStrings("Bearer test-key", fake.last(.GET, "/api/v1/order/ref-1/status").?.authorization);
}

test "createOrder cleans the GSM number, omits unset fields and fills the checkout URL" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.POST, "/api/v1/order/create", .{ .body = "{\"order_id\":\"order-1\",\"reference_id\":\"ref-1\"}" });
    try fake.on(.GET, "/api/v1/order/ref-1", .{ .body = "{\"reference_id\":\"ref-1\",\"checkout_url\":\"https://checkout.example/ref-1\"}" });

    const response = try client.createOrder(.{
        .locale = "tr",
        .amount = 100,
        .currency = "TRY",
        .buyer = .{ .name = "John", .gsm_number = "+90 (555) 123 45 67", .birth_date = "1990-01-02" },
        .order_cards = &.{.{ .card_id = "card-1", .card_sequence = 1 }},
        .payment_terms = &.{.{ .amount = 50, .due_date = "2026-01-15T00:00:00Z", .term_sequence = 1 }},
    });
    defer response.deinit();

    try testing.expectEqualStrings("order-1", response.value.order_id.?);
    try testing.expectEqualStrings("https://checkout.example/ref-1", response.value.checkout_url.?);

    const sent = try fake.last(.POST, "/api/v1/order/create").?.json(testing.allocator);
    defer sent.deinit();
    const body = sent.value.object;
    try expectJsonString(body.get("buyer").?.object, "gsm_number", "+905551234567");
    try expectJsonString(body.get("buyer").?.object, "birth_date", "1990-01-02");
    try expectJsonString(body.get("order_cards").?.array.items[0].object, "card_id", "card-1");
    try expectJsonString(body.get("payment_terms").?.array.items[0].object, "due_date", "2026-01-15T00:00:00Z");
    try testing.expect(body.get("checkout_design") == null);
    try testing.expect(body.get("redirect_success_url") == null);
}

test "order detail decodes the panel shape and escapes the reference" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/order/ref%2F1", .{ .body =
        \\{"reference_id":"ref/1","status":3,"customer_paid_amount":101.5,"buyer":{"birth_date":"1990-01-02"},
        \\ "basket_items":[{"id":"item-1","mcc":"5411","item_payments":[{"id":"pay-1","type":"CREDIT_CARD"}]}],
        \\ "payment_terms":[{"id":"term-1","due_date":"2026-01-15T00:00:00Z"}],"unknown":{"nested":true}}
    });

    const order = try client.orders().get("ref/1");
    defer order.deinit();

    try testing.expectEqual(@as(i64, 3), order.value.status.?);
    try testing.expectEqual(@as(f64, 101.5), order.value.customer_paid_amount.?);
    try testing.expectEqualStrings("1990-01-02", order.value.buyer.?.birth_date.?);
    try testing.expectEqualStrings("5411", order.value.basket_items.?[0].mcc.?);
    try testing.expectEqualStrings("CREDIT_CARD", order.value.basket_items.?[0].item_payments.?[0].type.?);
    try testing.expectEqualStrings("term-1", order.value.payment_terms.?[0].id.?);
}

test "order list sends every filter" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/order/list", .{ .body = "{\"rows\":[],\"total\":0}" });

    const page = try client.orders().list(.{ .page = 2, .per_page = 50, .start_date = "2026-01-01", .conversation_id = "c+1", .buyer_id = "b-1", .status = 3 });
    defer page.deinit();

    try testing.expectEqualStrings(
        "page=2&per_page=50&start_date=2026-01-01&conversation_id=c%2B1&buyer_id=b-1&status=3",
        fake.last(.GET, "/api/v1/order/list").?.query,
    );
}

test "order submerchants use the row key and transactions are an array or null" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/order/submerchants", .{ .body = "{\"row\":[{\"id\":\"sm-1\",\"submerchant_key\":\"key-1\"}],\"total\":1}" });
    try fake.on(.GET, "/api/v1/order/ref-1/transactions", .{ .body = "[{\"id\":\"tx-1\"}]" });
    try fake.on(.GET, "/api/v1/order/ref-2/transactions", .{ .body = "null" });

    const page = try client.orders().listSubmerchants(1, 10);
    defer page.deinit();
    const transactions = try client.orders().getTransactions("ref-1");
    defer transactions.deinit();
    const none = try client.orders().getTransactions("ref-2");
    defer none.deinit();

    try testing.expectEqualStrings("key-1", page.value.row.?[0].submerchant_key.?);
    try testing.expectEqualStrings("tx-1", transactions.value.array.items[0].object.get("id").?.string);
    try testing.expect(none.value == .null);
}

test "payment terms use the term routes" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/order/term", .{ .body = "{\"term_sequence\":1}" });
    try fake.on(.POST, "/api/v1/order/term", .{ .body = "{\"message\":\"ok\",\"code\":0}" });
    try fake.on(.DELETE, "/api/v1/order/term", .{ .body = "{\"message\":\"ok\"}" });
    try fake.on(.POST, "/api/v1/order/term/refund", .{ .body = "{\"is_success\":true}" });

    (try client.orders().getTerm("t+1")).deinit();
    (try client.orders().createTerm(.{ .order_id = "order-1", .required = true, .amount = 10, .due_date = "2026-02-01" })).deinit();
    (try client.orders().deleteTerm("order-1", "t-1")).deinit();
    (try client.orders().refundTerm(.{ .reference_id = "ref-1", .term_id = "term-1", .amount = 5 })).deinit();

    try testing.expectEqualStrings("term_reference_id=t%2B1", fake.last(.GET, "/api/v1/order/term").?.query);

    const created = try fake.last(.POST, "/api/v1/order/term").?.json(testing.allocator);
    defer created.deinit();
    try expectJsonString(created.value.object, "order_id", "order-1");
    try expectJsonString(created.value.object, "due_date", "2026-02-01");
    try testing.expect(created.value.object.get("required").?.bool);

    try testing.expectEqualStrings("{\"order_id\":\"order-1\",\"term_reference_id\":\"t-1\"}", fake.last(.DELETE, "/api/v1/order/term").?.body.?);

    const refunded = try fake.last(.POST, "/api/v1/order/term/refund").?.json(testing.allocator);
    defer refunded.deinit();
    try expectJsonString(refunded.value.object, "reference_id", "ref-1");
    try expectJsonString(refunded.value.object, "term_id", "term-1");
}

test "order actions use the panel routes" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.POST, "/api/v1/order/callback", .{ .body = "{\"message\":\"ok\"}" });
    try fake.on(.PATCH, "/api/v1/order/releated", .{ .body = "{\"status\":1,\"is_success\":true}" });
    try fake.on(.POST, "/api/v1/order/refund-all", .{ .body = "{\"status\":\"OK\",\"is_success\":true}" });
    try fake.on(.POST, "/api/v1/order/payment-details", .{ .body = "{\"rows\":[]}" });

    (try client.orders().manualCallback("ref-1", null)).deinit();
    (try client.orders().relatedUpdate("ref-1", "ref-0")).deinit();
    const refunded = try client.orders().refundAll("ref-1");
    defer refunded.deinit();
    (try client.orders().getPaymentDetailsByConversationId("conv-1")).deinit();

    try testing.expectEqualStrings("{\"reference_id\":\"ref-1\"}", fake.last(.POST, "/api/v1/order/callback").?.body.?);
    try testing.expectEqualStrings("{\"reference_id\":\"ref-1\",\"related_reference_id\":\"ref-0\"}", fake.last(.PATCH, "/api/v1/order/releated").?.body.?);
    try testing.expectEqualStrings("{\"reference_id\":\"ref-1\"}", fake.last(.POST, "/api/v1/order/refund-all").?.body.?);
    try testing.expect(refunded.value.is_success.?);
    try testing.expectEqualStrings("{\"conversation_id\":\"conv-1\"}", fake.last(.POST, "/api/v1/order/payment-details").?.body.?);
}

test "payments and charge" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.POST, "/api/v1/order/payments", .{ .body = "{\"payments\":[{\"id\":\"p-1\",\"type\":\"CREDIT_CARD\"}],\"total_merchant_net_amount\":97.5}" });
    try fake.on(.POST, "/api/v1/order/charge", .{ .body = "{\"isSuccess\":true,\"message\":\"charged\",\"statusCode\":\"00\",\"errorCode\":\"\"}" });

    const payments = try client.orders().getPayments(.{ .order_reference_id = "ref-1" });
    defer payments.deinit();
    const charged = try client.orders().charge(.{ .order_reference_id = "ref-1", .retry = true });
    defer charged.deinit();

    try testing.expectEqualStrings("CREDIT_CARD", payments.value.payments.?[0].type.?);
    try testing.expectEqual(@as(f64, 97.5), payments.value.total_merchant_net_amount.?);
    try testing.expect(charged.value.isSuccess.?);
    try testing.expectEqualStrings("00", charged.value.statusCode.?);
    try testing.expectEqualStrings("{\"order_reference_id\":\"ref-1\"}", fake.last(.POST, "/api/v1/order/payments").?.body.?);
    try testing.expectEqualStrings("{\"order_reference_id\":\"ref-1\",\"retry\":true}", fake.last(.POST, "/api/v1/order/charge").?.body.?);
}

test "card installments and the installment table" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/card/installments", .{ .body = "{\"is_installment_available\":true,\"installments\":[{\"installment\":3,\"commission_rate\":1.5}]}" });
    try fake.on(.GET, "/api/v1/card/installment-table", .{ .body = "{\"groups\":[{\"bank\":\"Bank\",\"rows\":[{\"installment\":2,\"is_interest_free\":true}]}]}" });

    const options = try client.cards().getInstallments(.{ .bin = "54066200", .amount = 100.5, .is_three_d = true });
    defer options.deinit();
    const table = try client.cards().getInstallmentTable(.{ .amount = 100 });
    defer table.deinit();

    try testing.expect(options.value.is_installment_available.?);
    try testing.expectEqual(@as(f64, 1.5), options.value.installments.?[0].commission_rate.?);
    try testing.expect(table.value.groups.?[0].rows.?[0].is_interest_free.?);
    try testing.expectEqualStrings("bin=54066200&amount=100.5&currency=TRY&is_three_d=true", fake.last(.GET, "/api/v1/card/installments").?.query);
    try testing.expectEqualStrings("amount=100&currency=TRY", fake.last(.GET, "/api/v1/card/installment-table").?.query);
}

test "organization, submerchant, VPOS and saved card routes" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/organization/settings", .{ .body = "{\"ttl\":30,\"has_kyb_kyx_template\":true}" });
    try fake.on(.GET, "/api/v1/organization/currency-presets", .{ .body = "{\"items\":[{\"currency_code\":\"EUR\",\"minor_unit\":2}]}" });
    try fake.on(.GET, "/api/v1/submerchants", .{ .body = "{\"row\":[{\"id\":\"sm-1\",\"status\":\"ACTIVE\"}]}" });
    try fake.on(.PUT, "/api/v1/submerchants/payment/item", .{ .body = "{\"operation_id\":\"op-1\"}" });
    try fake.on(.POST, "/api/v1/submerchant-payout-events", .{ .status = 202, .body = "{\"id\":\"ev-1\"}" });
    try fake.on(.PATCH, "/api/v1/vpos/vpos-1", .{ .body = "{\"code\":0,\"message\":\"updated\"}" });
    try fake.on(.DELETE, "/api/v1/tokenization/card/card-1", .{ .body = "{\"success\":true}" });

    const settings = try client.organization().getSettings();
    defer settings.deinit();
    const presets = try client.organization().listCurrencyPresets();
    defer presets.deinit();
    const page = try client.submerchants().list(1, 20);
    defer page.deinit();
    (try client.submerchants().updatePaymentItem(.{
        .locale = "tr",
        .conversation_id = "c-1",
        .payment_transaction_id = "tx-1",
        .sub_merchant_key = "key-1",
        .sub_merchant_price = "10.50",
        .acquirer = "acq",
    })).deinit();
    const event = try client.submerchants().recordPayoutEvent(.{ .idempotency_key = "k-1", .order_reference = "ref-1", .item_id = "item-1", .event_type = "DELIVERED" });
    defer event.deinit();
    (try client.vpos().update("vpos-1", .{ .name = "Main", .type = "BANK", .currencies = &.{"TRY"}, .failover = true, .root_ca = "ca", .main_installment = true })).deinit();
    const deleted = try client.cards().deleteSaved("card-1");
    defer deleted.deinit();

    try testing.expectEqual(@as(i64, 30), settings.value.ttl.?);
    try testing.expect(settings.value.has_kyb_kyx_template.?);
    try testing.expectEqual(@as(i64, 2), presets.value.items.?[0].minor_unit.?);
    try testing.expectEqualStrings("ACTIVE", page.value.row.?[0].status.?);
    try testing.expectEqualStrings("ev-1", event.value.id.?);
    try testing.expect(deleted.value.success.?);

    const vpos = try fake.last(.PATCH, "/api/v1/vpos/vpos-1").?.json(testing.allocator);
    defer vpos.deinit();
    try expectJsonString(vpos.value.object, "type", "BANK");
    try expectJsonString(vpos.value.object, "root_ca", "ca");
    try testing.expect(vpos.value.object.get("failover").?.bool);
    try testing.expect(vpos.value.object.get("main_installment").?.bool);
}

test "marketplace routes use API v2 and keep revisions opaque" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v2/submerchants/s-1", .{ .body = "{\"id\":\"s-1\",\"revision\":\"2026-10-19T10:00:00.123456789Z\",\"approval_mode\":null}" });
    try fake.on(.PATCH, "/api/v2/submerchants/s-1", .{ .body = "{\"approval_required\":true}" });
    try fake.on(.POST, "/api/v2/submerchant-payouts/approve", .{ .status = 202, .body = "{\"status\":\"accepted\"}" });
    try fake.on(.GET, "/api/v2/marketplace/seller-contracts", .{ .body = "{\"contracts\":{\"v-1\":{\"supported\":true,\"fields\":{\"tax_number\":true}}}}" });
    try fake.on(.DELETE, "/api/v2/marketplace/release-policies/rel-1", .{ .status = 204, .body = "" });

    const seller = try client.marketplace().getSubmerchant("s-1");
    defer seller.deinit();
    const update = try client.marketplace().updateSubmerchant("s-1", .{ .name = "Seller", .revision = seller.value.revision.? });
    defer update.deinit();
    const accepted = try client.marketplace().approvePayouts(.{ .ids = &.{ "p-1", "p-2" } });
    defer accepted.deinit();
    const contracts = try client.marketplace().getSellerContracts(.{ .currency_id = "TRY", .seller_type = "PERSONAL", .vpos_ids = &.{ "v-1", "v-2" } });
    defer contracts.deinit();
    try client.marketplace().deleteReleasePolicy("rel-1");

    try testing.expect(seller.value.approval_mode == null);
    try testing.expect(update.value.approval_required.?);
    try testing.expectEqualStrings("accepted", accepted.value.status.?);
    try testing.expect(contracts.value.contracts.?.map.get("v-1").?.fields.?.map.get("tax_number").?);
    try testing.expectEqualStrings(
        "currency_id=TRY&seller_type=PERSONAL&operation=create&vpos_id=v-1&vpos_id=v-2",
        fake.last(.GET, "/api/v2/marketplace/seller-contracts").?.query,
    );
    const sent = try fake.last(.PATCH, "/api/v2/submerchants/s-1").?.json(testing.allocator);
    defer sent.deinit();
    try expectJsonString(sent.value.object, "revision", "2026-10-19T10:00:00.123456789Z");
    try testing.expectEqualStrings("{\"ids\":[\"p-1\",\"p-2\"]}", fake.last(.POST, "/api/v2/submerchant-payouts/approve").?.body.?);
}

test "approval policy currency units are resolved to UUIDs" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    const uuid = "3fa85f64-5717-4562-b3fc-2c963f66afa6";
    try fake.on(.GET, "/api/v1/organization/currencies", .{ .body = "{\"currencies\":[{\"id\":\"" ++ uuid ++ "\",\"currency_unit\":\"TRY\"}]}" });
    try fake.on(.POST, "/api/v2/marketplace/approval-policies", .{ .status = 201, .body = "{\"id\":\"pol-1\"}" });

    try client.marketplace().createApprovalPolicy(.{ .name = "Large", .priority = 1, .enabled = true, .min_amount = "1000", .currency_id = "try", .mode = "manual" });

    const sent = try fake.last(.POST, "/api/v2/marketplace/approval-policies").?.json(testing.allocator);
    defer sent.deinit();
    try expectJsonString(sent.value.object, "currency_id", uuid);
    try expectJsonString(sent.value.object, "min_amount", "1000");

    const resolved = try client.resolveCurrencyId(testing.allocator, uuid);
    defer testing.allocator.free(resolved);
    try testing.expectEqualStrings(uuid, resolved);
    try testing.expectError(error.UnknownCurrency, client.resolveCurrencyId(testing.allocator, "XYZ"));
}

test "validation errors expose the code and field errors" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.POST, "/api/v1/order/cancel", .{ .status = 400, .body = "{\"message\":\"INVALID_REQUEST_BODY\",\"code\":400000,\"errors\":{\"reference_id\":\"required\"}}" });

    try testing.expectError(error.ApiError, client.orders().cancel(""));
    const api_error = client.last_api_error.?;
    try testing.expectEqual(@as(u16, 400), api_error.status_code);
    try testing.expectEqualStrings("Bad Request", api_error.status);
    try testing.expectEqualStrings("400000", api_error.code.?);
    try testing.expectEqualStrings("INVALID_REQUEST_BODY", api_error.message.?);
    try testing.expectEqualStrings("{\"reference_id\":\"required\"}", api_error.errors_json.?);

    var buffer: [200]u8 = undefined;
    const text = try std.fmt.bufPrint(&buffer, "{f}", .{api_error});
    try testing.expectEqualStrings("API request failed with status 400 (Bad Request): [400000] INVALID_REQUEST_BODY", text);
}

test "gRPC errors use the error field" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v2/submerchant-payouts/missing", .{ .status = 424, .body = "{\"error\":\"payout is not eligible\",\"code\":9}" });

    try testing.expectError(error.ApiError, client.marketplace().getPayout("missing"));
    try testing.expectEqual(@as(u16, 424), client.last_api_error.?.status_code);
    try testing.expectEqualStrings("9", client.last_api_error.?.code.?);
    try testing.expectEqualStrings("payout is not eligible", client.last_api_error.?.message.?);
}

test "an HTML page is reported as an API error" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/order/ref-1/status", .{ .content_type = "text/html; charset=utf-8", .body = "<!doctype html><html></html>" });

    try testing.expectError(error.ApiError, client.orders().getStatus("ref-1"));
    const api_error = client.last_api_error.?;
    try testing.expectEqual(@as(u16, 200), api_error.status_code);
    try testing.expect(std.mem.find(u8, api_error.message.?, "unexpected non-JSON response") != null);
    try testing.expectEqualStrings("<!doctype html><html></html>", api_error.raw_body);
}

test "versioned base URL" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();

    const v2 = try client.versionedBaseUrl(.v2);
    defer testing.allocator.free(v2);
    try testing.expectEqualStrings("https://panel.example/api/v2", v2);

    client.config.base_url = "https://panel.example/";
    const appended = try client.versionedBaseUrl(.v2);
    defer testing.allocator.free(appended);
    try testing.expectEqualStrings("https://panel.example/api/v2", appended);
}

test "elements createSession posts a pay session and decodes the client secret" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.POST, "/api/v1/elements/sessions", .{ .body =
        \\{"id":"es_test_8Kq2nV0rX4","purpose":"pay","status":"requires_payment_method","order_reference_id":"order-ref-1",
        \\ "attempts":0,"max_attempts":3,"created_at":"2026-10-22T09:00:00Z","expires_at":"2026-10-22T09:30:00Z",
        \\ "client_secret":"es_test_8Kq2nV0rX4_secret_q8Zr0bM1","elements_base_url":"https://checkout.tapsilat.dev"}
    });

    const session = try client.elements().createSession(.{
        .purpose = @tagName(tapsilat.ElementsPurpose.pay),
        .order_reference_id = "order-ref-1",
        .save_card = true,
    });
    defer session.deinit();

    const sent = fake.last(.POST, "/api/v1/elements/sessions").?;
    try testing.expectEqualStrings("Bearer test-key", sent.authorization);
    try testing.expectEqualStrings("{\"purpose\":\"pay\",\"order_reference_id\":\"order-ref-1\",\"save_card\":true}", sent.body.?);

    const value = session.value;
    try testing.expectEqualStrings("es_test_8Kq2nV0rX4", value.id.?);
    try testing.expectEqualStrings("pay", value.purpose.?);
    try testing.expectEqualStrings("requires_payment_method", value.status.?);
    try testing.expectEqual(tapsilat.ElementsStatus.requires_payment_method, value.session().knownStatus().?);
    try testing.expectEqual(tapsilat.ElementsPurpose.pay, value.session().knownPurpose().?);
    try testing.expectEqualStrings("order-ref-1", value.order_reference_id.?);
    try testing.expectEqual(@as(i64, 0), value.attempts.?);
    try testing.expectEqual(@as(i64, 3), value.max_attempts.?);
    try testing.expectEqualStrings("2026-10-22T09:00:00Z", value.created_at.?);
    try testing.expectEqualStrings("2026-10-22T09:30:00Z", value.expires_at.?);
    try testing.expect(value.completed_at == null);
    try testing.expect(value.card == null);
    try testing.expect(value.last_error == null);
    try testing.expectEqualStrings("es_test_8Kq2nV0rX4_secret_q8Zr0bM1", value.client_secret.?);
    try testing.expectEqualStrings("https://checkout.tapsilat.dev", value.elements_base_url.?);
}

test "elements createSession sends a tokenize session's owner and mode" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.POST, "/api/v1/elements/sessions", .{ .body = "{\"id\":\"es_test_1\",\"purpose\":\"tokenize\",\"status\":\"requires_payment_method\",\"user_id\":\"user_123\",\"client_secret\":\"es_test_1_secret_x\"}" });

    const session = try client.elements().createSession(.{
        .purpose = @tagName(tapsilat.ElementsPurpose.tokenize),
        .user_id = "user_123",
        .user_email = "john@doe.com",
        .mode = tapsilat.ElementsMode.non_secure.code(),
    });
    defer session.deinit();

    try testing.expectEqualStrings(
        "{\"purpose\":\"tokenize\",\"user_id\":\"user_123\",\"user_email\":\"john@doe.com\",\"mode\":3}",
        fake.last(.POST, "/api/v1/elements/sessions").?.body.?,
    );
    try testing.expectEqualStrings("user_123", session.value.user_id.?);
    try testing.expectEqualStrings("es_test_1_secret_x", session.value.client_secret.?);
    try testing.expectEqual(tapsilat.ElementsPurpose.tokenize, session.value.session().knownPurpose().?);
    try testing.expectEqual(@as(i64, 1), tapsilat.ElementsMode.secure.code());
    try testing.expectEqual(@as(i64, 2), tapsilat.ElementsMode.half_secure.code());
}

test "elements getSession decodes the card and the last error" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/elements/sessions/es_test_8Kq2nV0rX4", .{ .body =
        \\{"id":"es_test_8Kq2nV0rX4","purpose":"pay","status":"failed","order_reference_id":"order-ref-1",
        \\ "attempts":3,"max_attempts":3,"completed_at":"2026-10-22T09:12:00Z",
        \\ "card":{"id":"card-1","brand":"visa","last4":"4242","exp_month":12,"exp_year":2030},
        \\ "last_error":{"code":"card_declined","message":"The card was declined.","retryable":false}}
    });

    const session = try client.elements().getSession("es_test_8Kq2nV0rX4");
    defer session.deinit();

    const sent = fake.last(.GET, "/api/v1/elements/sessions/es_test_8Kq2nV0rX4").?;
    try testing.expectEqualStrings("Bearer test-key", sent.authorization);
    try testing.expect(sent.body == null);

    const value = session.value;
    try testing.expectEqual(tapsilat.ElementsStatus.failed, value.knownStatus().?);
    try testing.expectEqual(@as(i64, 3), value.attempts.?);
    try testing.expectEqualStrings("2026-10-22T09:12:00Z", value.completed_at.?);
    const card = value.card.?;
    try testing.expectEqualStrings("card-1", card.id.?);
    try testing.expectEqualStrings("visa", card.brand.?);
    try testing.expectEqual(tapsilat.ElementsCardBrand.visa, card.knownBrand().?);
    try testing.expectEqualStrings("4242", card.last4.?);
    try testing.expectEqual(@as(i64, 12), card.exp_month.?);
    try testing.expectEqual(@as(i64, 2030), card.exp_year.?);
    const last_error = value.last_error.?;
    try testing.expectEqualStrings("card_declined", last_error.code.?);
    try testing.expectEqualStrings("The card was declined.", last_error.message.?);
    try testing.expect(!last_error.retryable.?);
}

test "elements getSession reads a null card and error, and values it does not know" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/elements/sessions/es_mock_1", .{ .body = "{\"id\":\"es_mock_1\",\"purpose\":\"pay\",\"status\":\"requires_payment_method\",\"card\":null,\"last_error\":null}" });
    try fake.on(.GET, "/api/v1/elements/sessions/es_mock_2", .{ .body =
        \\{"id":"es_mock_2","purpose":"subscribe","status":"under_review","created_at":"22/10/2026",
        \\ "card":{"brand":"elo","last4":"0005","network":"elo"},"risk":{"score":12}}
    });

    const empty = try client.elements().getSession("es_mock_1");
    defer empty.deinit();
    try testing.expect(empty.value.card == null);
    try testing.expect(empty.value.last_error == null);

    const future = try client.elements().getSession("es_mock_2");
    defer future.deinit();
    try testing.expectEqualStrings("under_review", future.value.status.?);
    try testing.expect(future.value.knownStatus() == null);
    try testing.expectEqualStrings("subscribe", future.value.purpose.?);
    try testing.expect(future.value.knownPurpose() == null);
    try testing.expectEqualStrings("22/10/2026", future.value.created_at.?);
    try testing.expectEqualStrings("elo", future.value.card.?.brand.?);
    try testing.expect(future.value.card.?.knownBrand() == null);
}

test "elements cancelSession posts no body" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.POST, "/api/v1/elements/sessions/es_test_8Kq2nV0rX4/cancel", .{ .body = "{\"id\":\"es_test_8Kq2nV0rX4\",\"purpose\":\"pay\",\"status\":\"canceled\",\"attempts\":0,\"max_attempts\":3}" });

    const session = try client.elements().cancelSession("es_test_8Kq2nV0rX4");
    defer session.deinit();

    const sent = fake.last(.POST, "/api/v1/elements/sessions/es_test_8Kq2nV0rX4/cancel").?;
    try testing.expectEqualStrings("Bearer test-key", sent.authorization);
    try testing.expect(sent.body == null);
    try testing.expectEqual(tapsilat.ElementsStatus.canceled, session.value.knownStatus().?);
}

test "elements session IDs are escaped in the path" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/elements/sessions/es_test_1%2F..%2Fx", .{ .body = "{\"id\":\"es_test_1\"}" });
    try fake.on(.POST, "/api/v1/elements/sessions/es_test_1%3Fa%3D1/cancel", .{ .body = "{\"id\":\"es_test_1\"}" });

    (try client.elements().getSession("es_test_1/../x")).deinit();
    (try client.elements().cancelSession("es_test_1?a=1")).deinit();

    try testing.expect(fake.last(.GET, "/api/v1/elements/sessions/es_test_1%2F..%2Fx") != null);
    try testing.expectEqualStrings("", fake.last(.POST, "/api/v1/elements/sessions/es_test_1%3Fa%3D1/cancel").?.query);
}

const ElementsCall = enum { create, get, cancel };

fn callElements(client: *tapsilat.Client, call: ElementsCall) !void {
    switch (call) {
        .create => (try client.elements().createSession(.{ .purpose = "pay", .order_reference_id = "order-ref-1" })).deinit(),
        .get => (try client.elements().getSession("es_test_missing")).deinit(),
        .cancel => (try client.elements().cancelSession("es_test_1")).deinit(),
    }
}

test "elements errors expose the nested code, message and retryable flag" {
    const Case = struct {
        call: ElementsCall,
        method: std.http.Method,
        path: []const u8,
        status: u16,
        body: []const u8,
        code: []const u8,
        message: []const u8,
        retryable: bool,
        formatted: []const u8,
    };
    const cases = [_]Case{
        .{
            .call = .create,
            .method = .POST,
            .path = "/api/v1/elements/sessions",
            .status = 403,
            .body = "{\"error\":{\"code\":\"elements_not_enabled\",\"message\":\"Elements is not enabled for this organization\"}}",
            .code = "elements_not_enabled",
            .message = "Elements is not enabled for this organization",
            .retryable = false,
            .formatted = "API request failed with status 403 (Forbidden): [elements_not_enabled] Elements is not enabled for this organization",
        },
        .{
            .call = .get,
            .method = .GET,
            .path = "/api/v1/elements/sessions/es_test_missing",
            .status = 404,
            .body = "{\"error\":{\"code\":\"session_not_found\",\"message\":\"session not found\",\"retryable\":false}}",
            .code = "session_not_found",
            .message = "session not found",
            .retryable = false,
            .formatted = "API request failed with status 404 (Not Found): [session_not_found] session not found",
        },
        .{
            .call = .cancel,
            .method = .POST,
            .path = "/api/v1/elements/sessions/es_test_1/cancel",
            .status = 503,
            .body = "{\"error\":{\"code\":\"unavailable\",\"message\":\"try again\",\"retryable\":true}}",
            .code = "unavailable",
            .message = "try again",
            .retryable = true,
            .formatted = "API request failed with status 503 (Service Unavailable): [unavailable] try again",
        },
    };

    for (cases) |case| {
        var fake = Fake.init(testing.allocator);
        defer fake.deinit();
        var client = fake.client();
        defer client.deinit();
        try fake.on(case.method, case.path, .{ .status = case.status, .body = case.body });

        try testing.expectError(error.ApiError, callElements(&client, case.call));
        const api_error = client.last_api_error.?;
        try testing.expectEqual(case.status, api_error.status_code);
        try testing.expectEqualStrings(case.code, api_error.code.?);
        try testing.expectEqualStrings(case.message, api_error.message.?);
        try testing.expectEqual(case.retryable, api_error.retryable);

        var buffer: [200]u8 = undefined;
        try testing.expectEqualStrings(case.formatted, try std.fmt.bufPrint(&buffer, "{f}", .{api_error}));
    }
}

test "top-level error shapes are not retryable" {
    var fake = Fake.init(testing.allocator);
    defer fake.deinit();
    var client = fake.client();
    defer client.deinit();
    try fake.on(.GET, "/api/v1/order/ref-1/status", .{ .status = 503, .body = "{\"error\":\"unavailable\",\"code\":14,\"retryable\":true}" });

    try testing.expectError(error.ApiError, client.orders().getStatus("ref-1"));
    try testing.expectEqualStrings("14", client.last_api_error.?.code.?);
    try testing.expectEqualStrings("unavailable", client.last_api_error.?.message.?);
    try testing.expect(!client.last_api_error.?.retryable);
}

test "a created elements session redacts its client secret when formatted" {
    const session: tapsilat.ElementsSessionWithSecret = .{
        .id = "es_test_1",
        .status = "requires_payment_method",
        .card = .{ .brand = "visa", .last4 = "4242" },
        .client_secret = "es_test_1_secret_x",
        .elements_base_url = "https://checkout.tapsilat.dev",
    };

    var buffer: [512]u8 = undefined;
    const printed = try std.fmt.bufPrint(&buffer, "{f}", .{session});
    try testing.expectEqualStrings(
        ".{ .id = \"es_test_1\", .status = \"requires_payment_method\", .card = .{ .brand = \"visa\", .last4 = \"4242\" }, " ++
            ".client_secret = [redacted], .elements_base_url = \"https://checkout.tapsilat.dev\" }",
        printed,
    );
    try testing.expect(std.mem.find(u8, printed, "secret_x") == null);

    const encoded = try std.json.Stringify.valueAlloc(testing.allocator, session, .{ .emit_null_optional_fields = false });
    defer testing.allocator.free(encoded);
    try testing.expect(std.mem.find(u8, encoded, "\"client_secret\":\"es_test_1_secret_x\"") != null);

    const without_secret = session.session();
    try testing.expectEqualStrings("es_test_1", without_secret.id.?);
    try testing.expectEqualStrings("4242", without_secret.card.?.last4.?);
    try testing.expect(!@hasField(tapsilat.ElementsSession, "client_secret"));
}
