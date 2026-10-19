//! Orders, payments and payment terms.

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");
const validators = @import("validators.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;
const Value = std.json.Value;

pub const Orders = struct {
    client: *Client,

    /// Creates an order. The buyer's GSM number is cleaned first, and the checkout URL is
    /// filled from the created order when it can be read.
    pub fn create(self: Orders, request: models.Order) !Parsed(models.OrderResponse) {
        const allocator = self.client.allocator;
        var normalized = request;
        var cleaned: ?[]u8 = null;
        defer if (cleaned) |value| allocator.free(value);
        if (request.buyer) |buyer| {
            if (buyer.gsm_number) |gsm| {
                if (gsm.len > 0) {
                    cleaned = try validators.validateGsmNumber(allocator, gsm);
                    var copy = buyer;
                    copy.gsm_number = cleaned;
                    normalized.buyer = copy;
                }
            }
        }

        var response = try self.client.call(models.OrderResponse, .POST, .v1, "/order/create", normalized);
        errdefer response.deinit();

        if (response.value.reference_id) |reference_id| {
            if (reference_id.len > 0) {
                // The order is created even when its checkout URL cannot be read
                if (self.getCheckoutUrl(response.arena.allocator(), reference_id)) |checkout_url| {
                    if (checkout_url) |value| response.value.checkout_url = value;
                } else |_| {
                    self.client.clearApiError();
                }
            }
        }
        return response;
    }

    pub fn get(self: Orders, reference_id: []const u8) !Parsed(models.OrderDetail) {
        return self.client.callAt(models.OrderDetail, .GET, .v1, .{ "/order/", reference_id }, null);
    }

    /// Returns the order with the given conversation ID; the server fills a subset of the detail fields.
    pub fn getByConversationId(self: Orders, conversation_id: []const u8) !Parsed(models.OrderDetail) {
        return self.client.callAt(models.OrderDetail, .GET, .v1, .{ "/order/conversation/", conversation_id }, null);
    }

    /// Returns the order's checkout URL, allocated with `allocator`, or null when it has none.
    pub fn getCheckoutUrl(self: Orders, allocator: std.mem.Allocator, reference_id: []const u8) !?[]u8 {
        const order = try self.get(reference_id);
        defer order.deinit();
        const checkout_url = order.value.checkout_url orelse return null;
        if (checkout_url.len == 0) return null;
        return try allocator.dupe(u8, checkout_url);
    }

    /// Lists orders with every filter the order list endpoint accepts.
    pub fn list(self: Orders, filter: models.OrderListFilter) !Parsed(models.PaginatedData) {
        var query = try client_mod.Query.init(self.client.allocator, "/order/list");
        errdefer query.deinit();
        try query.add("page", filter.page);
        try query.add("per_page", filter.per_page);
        try query.add("start_date", filter.start_date);
        try query.add("end_date", filter.end_date);
        try query.add("organization_id", filter.organization_id);
        try query.add("conversation_id", filter.conversation_id);
        try query.add("related_reference_id", filter.related_reference_id);
        try query.add("buyer_id", filter.buyer_id);
        try query.add("status", filter.status);
        return self.client.callQuery(models.PaginatedData, .v1, &query);
    }

    pub fn getStatus(self: Orders, reference_id: []const u8) !Parsed(models.OrderStatus) {
        return self.client.callAt(models.OrderStatus, .GET, .v1, .{ "/order/", reference_id, "/status" }, null);
    }

    pub fn listSubmerchants(self: Orders, page: i64, per_page: i64) !Parsed(models.OrderSubmerchantListResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/order/submerchants");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        return self.client.callQuery(models.OrderSubmerchantListResponse, .v1, &query);
    }

    pub fn getPaymentDetails(self: Orders, reference_id: []const u8) !Parsed(Value) {
        return self.client.callAt(Value, .GET, .v1, .{ "/order/", reference_id, "/payment-details" }, null);
    }

    pub fn getPaymentDetailsByConversationId(self: Orders, conversation_id: []const u8) !Parsed(Value) {
        return self.client.call(Value, .POST, .v1, "/order/payment-details", .{ .conversation_id = conversation_id });
    }

    /// Returns the order's transactions: a JSON array, or null when there are none.
    pub fn getTransactions(self: Orders, reference_id: []const u8) !Parsed(Value) {
        return self.client.callAt(Value, .GET, .v1, .{ "/order/", reference_id, "/transactions" }, null);
    }

    /// Lists the payments made against an order, with commission totals.
    pub fn getPayments(self: Orders, request: models.GetOrderPaymentsRequest) !Parsed(models.GetOrderPaymentsResponse) {
        return self.client.call(models.GetOrderPaymentsResponse, .POST, .v1, "/order/payments", request);
    }

    /// Charges an order, for example with its saved card.
    pub fn charge(self: Orders, request: models.OrderChargeRequest) !Parsed(models.OrderChargeResponse) {
        return self.client.call(models.OrderChargeResponse, .POST, .v1, "/order/charge", request);
    }

    pub fn cancel(self: Orders, reference_id: []const u8) !Parsed(models.RefundCancelOrderResponse) {
        return self.client.call(models.RefundCancelOrderResponse, .POST, .v1, "/order/cancel", .{ .reference_id = reference_id });
    }

    pub fn refund(self: Orders, request: models.RefundOrder) !Parsed(models.RefundCancelOrderResponse) {
        return self.client.call(models.RefundCancelOrderResponse, .POST, .v1, "/order/refund", request);
    }

    /// Refunds the full paid amount of an order.
    pub fn refundAll(self: Orders, reference_id: []const u8) !Parsed(models.RefundCancelOrderResponse) {
        return self.client.call(models.RefundCancelOrderResponse, .POST, .v1, "/order/refund-all", .{ .reference_id = reference_id });
    }

    /// Returns a payment term by its term reference ID.
    pub fn getTerm(self: Orders, term_reference_id: []const u8) !Parsed(Value) {
        var query = try client_mod.Query.init(self.client.allocator, "/order/term");
        errdefer query.deinit();
        try query.add("term_reference_id", term_reference_id);
        return self.client.callQuery(Value, .v1, &query);
    }

    /// Adds a payment term to an existing order; `order_id` is the order's ID.
    pub fn createTerm(self: Orders, request: models.OrderTermCreateRequest) !Parsed(Value) {
        return self.client.call(Value, .POST, .v1, "/order/term", request);
    }

    /// Replaces a payment term; the server stores every field as sent.
    pub fn updateTerm(self: Orders, request: models.OrderTermUpdateRequest) !Parsed(Value) {
        return self.client.call(Value, .PATCH, .v1, "/order/term", request);
    }

    /// Removes a payment term; `order_id` is the order's ID, not its reference ID.
    pub fn deleteTerm(self: Orders, order_id: []const u8, term_reference_id: []const u8) !Parsed(Value) {
        return self.client.call(Value, .DELETE, .v1, "/order/term", .{ .order_id = order_id, .term_reference_id = term_reference_id });
    }

    pub fn refundTerm(self: Orders, request: models.OrderTermRefundRequest) !Parsed(Value) {
        return self.client.call(Value, .POST, .v1, "/order/term/refund", request);
    }

    pub fn terminate(self: Orders, reference_id: []const u8) !Parsed(Value) {
        return self.client.call(Value, .POST, .v1, "/order/terminate", .{ .reference_id = reference_id });
    }

    /// Asks the server to resend the order's callback.
    pub fn manualCallback(self: Orders, reference_id: []const u8, conversation_id: ?[]const u8) !Parsed(Value) {
        const Payload = struct { reference_id: []const u8, conversation_id: ?[]const u8 = null };
        return self.client.call(Value, .POST, .v1, "/order/callback", Payload{ .reference_id = reference_id, .conversation_id = conversation_id });
    }

    /// Links an order to a related reference ID.
    pub fn relatedUpdate(self: Orders, reference_id: []const u8, related_reference_id: []const u8) !Parsed(Value) {
        return self.client.call(Value, .PATCH, .v1, "/order/releated", .{ .reference_id = reference_id, .related_reference_id = related_reference_id });
    }
};
