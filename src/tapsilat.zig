const std = @import("std");
const http = std.http;
const Uri = std.Uri;
const Allocator = std.mem.Allocator;

// ============================================================================
// Types
// ============================================================================

pub const Currency = enum {
    TRY,
    USD,
    EUR,
    GBP,

    pub fn jsonStringify(self: Currency, jws: anytype) !void {
        try jws.write(@tagName(self));
    }
};

pub const Locale = enum {
    tr,
    en,

    pub fn jsonStringify(self: Locale, jws: anytype) !void {
        try jws.write(@tagName(self));
    }
};

pub const BillingType = enum {
    PERSONAL,
    COMPANY,

    pub fn jsonStringify(self: BillingType, jws: anytype) !void {
        try jws.write(@tagName(self));
    }
};

pub const PaymentOption = enum {
    PAY_WITH_WALLET,
    PAY_WITH_CARD,
    PAY_WITH_LOAN,
    PAY_WITH_CASH,

    pub fn jsonStringify(self: PaymentOption, jws: anytype) !void {
        try jws.write(@tagName(self));
    }
};

pub const BillingAddress = struct {
    address: []const u8,
    billing_type: BillingType = .PERSONAL,
    city: []const u8,
    contact_name: []const u8,
    contact_phone: []const u8,
    country: []const u8 = "TR",
    vat_number: []const u8,
    zip_code: []const u8,
    district: []const u8,
};

pub const Buyer = struct {
    id: []const u8,
    name: []const u8,
    surname: []const u8,
    email: []const u8,
    gsm_number: []const u8,
    identity_number: []const u8,
    birth_date: []const u8,
    registration_address: []const u8,
    city: []const u8,
    country: []const u8 = "TR",
};

pub const BasketItem = struct {
    id: []const u8,
    name: []const u8,
    category1: []const u8,
    category2: ?[]const u8 = null,
    price: f64,
    coupon_discount: f64 = 0,
    quantity: u32 = 1,
    item_type: []const u8,
    data: ?[]const u8 = null,
    quantity_unit: []const u8 = "PCE",
};

pub const CreateOrderRequest = struct {
    amount: f64,
    paid_amount: f64 = 0,
    currency: Currency = .TRY,
    locale: Locale = .tr,
    payment_methods: bool = true,
    partial_payment: bool = false,
    three_d_force: bool = false,
    billing_address: BillingAddress,
    buyer: Buyer,
    basket_items: []const BasketItem,
    conversation_id: []const u8,
    payment_options: []const PaymentOption = &.{
        .PAY_WITH_WALLET,
        .PAY_WITH_CARD,
        .PAY_WITH_LOAN,
        .PAY_WITH_CASH,
    },
};

pub const ApiError = struct {
    message: ?[]const u8 = null,
    code: ?[]const u8 = null,
};

pub const CreateOrderResponse = struct {
    status: ?[]const u8 = null,
    message: ?[]const u8 = null,
    data: ?OrderData = null,
    errors: ?ApiError = null,
};

pub const OrderData = struct {
    id: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    payment_page_url: ?[]const u8 = null,
    token: ?[]const u8 = null,
    status: ?[]const u8 = null,
};

pub const TapsilatError = error{
    HttpRequestFailed,
    InvalidResponse,
    JsonParseError,
    ConnectionFailed,
    Timeout,
};

// ============================================================================
// Client
// ============================================================================

pub const Config = struct {
    api_key: []const u8,
    base_url: []const u8 = "https://panel.tapsilat.com/api/v1",
};

pub const Client = struct {
    allocator: Allocator,
    config: Config,
    http_client: http.Client,

    pub fn init(allocator: Allocator, config: Config) Client {
        return .{
            .allocator = allocator,
            .config = config,
            .http_client = http.Client{ .allocator = allocator },
        };
    }

    pub fn deinit(self: *Client) void {
        self.http_client.deinit();
    }

    /// Creates a new payment order.
    /// Returns the parsed response. Caller owns the returned parsed result
    /// and must call `std.json.parseFree` or use the arena pattern.
    pub fn createOrder(self: *Client, request: CreateOrderRequest) !ApiResponse {
        return self.post("/order/create", request);
    }

    // ---- internal helpers ----

    fn post(self: *Client, path: []const u8, body: anytype) !ApiResponse {
        // Build URL
        const url_str = try std.fmt.allocPrint(self.allocator, "{s}{s}", .{ self.config.base_url, path });
        defer self.allocator.free(url_str);

        const uri = Uri.parse(url_str) catch return error.HttpRequestFailed;

        // Serialize body
        const body_json = std.json.Stringify.valueAlloc(self.allocator, body, .{}) catch return error.JsonParseError;
        defer self.allocator.free(body_json);

        // Build auth header value
        const auth_value = try std.fmt.allocPrint(self.allocator, "Bearer {s}", .{self.config.api_key});
        defer self.allocator.free(auth_value);

        var response_out: std.Io.Writer.Allocating = .init(self.allocator);
        defer response_out.deinit();

        const fetch_result = self.http_client.fetch(.{
            .location = .{ .uri = uri },
            .method = .POST,
            .payload = body_json,
            .extra_headers = &.{
                .{ .name = "Authorization", .value = auth_value },
                .{ .name = "Content-Type", .value = "application/json" },
                .{ .name = "Accept", .value = "application/json" },
            },
            .response_writer = &response_out.writer,
        }) catch return error.HttpRequestFailed;

        const response_body = self.allocator.dupe(u8, response_out.written()) catch return error.InvalidResponse;

        return .{
            .status = fetch_result.status,
            .body = response_body,
            .allocator = self.allocator,
        };
    }
};

pub const ApiResponse = struct {
    status: http.Status,
    body: []const u8,
    allocator: Allocator,

    pub fn deinit(self: *ApiResponse) void {
        self.allocator.free(self.body);
    }

    /// Returns true if the HTTP status code indicates success (2xx).
    pub fn isSuccess(self: ApiResponse) bool {
        const code = @intFromEnum(self.status);
        return code >= 200 and code < 300;
    }

    /// Parse the response body as JSON into `CreateOrderResponse`.
    pub fn json(self: ApiResponse) !std.json.Parsed(CreateOrderResponse) {
        return std.json.parseFromSlice(
            CreateOrderResponse,
            self.allocator,
            self.body,
            .{ .ignore_unknown_fields = true, .allocate = .alloc_always },
        );
    }
};

// ============================================================================
// Tests
// ============================================================================

test "serialize CreateOrderRequest to JSON" {
    const allocator = std.testing.allocator;

    const request = CreateOrderRequest{
        .amount = 5,
        .paid_amount = 0,
        .currency = .TRY,
        .locale = .tr,
        .conversation_id = "test-conv-123",
        .billing_address = .{
            .address = "test test",
            .billing_type = .PERSONAL,
            .city = "Bursa",
            .contact_name = "Test User",
            .contact_phone = "+905321112233",
            .country = "TR",
            .vat_number = "11111111610",
            .zip_code = "16000",
            .district = "Osmangazi",
        },
        .buyer = .{
            .id = "cus_test",
            .name = "Test",
            .surname = "User",
            .email = "test@test.com",
            .gsm_number = "+905321112233",
            .identity_number = "11111111610",
            .birth_date = "1991-12-20 00:00:00",
            .registration_address = "Test Test",
            .city = "Bursa",
            .country = "TR",
        },
        .basket_items = &.{
            .{
                .id = "item_1",
                .name = "Test Item",
                .category1 = "Test",
                .price = 5,
                .item_type = "Test",
            },
        },
    };

    const json_buf = try std.json.Stringify.valueAlloc(allocator, request, .{});
    defer allocator.free(json_buf);

    // Verify it produced valid JSON by parsing it back
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, json_buf, .{});
    defer parsed.deinit();

    const obj = parsed.value.object;
    const amount_val = obj.get("amount").?;
    switch (amount_val) {
        .integer => |v| try std.testing.expectEqual(@as(i64, 5), v),
        .float => |v| try std.testing.expectApproxEqAbs(@as(f64, 5), v, 0.000001),
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqualStrings("TRY", obj.get("currency").?.string);
    try std.testing.expectEqualStrings("test-conv-123", obj.get("conversation_id").?.string);
}

test "ApiResponse.isSuccess" {
    var resp = ApiResponse{
        .status = .ok,
        .body = "{}",
        .allocator = std.testing.allocator,
    };
    // body is a literal, so we skip deinit for this test
    _ = &resp;

    try std.testing.expect(resp.isSuccess());
}
