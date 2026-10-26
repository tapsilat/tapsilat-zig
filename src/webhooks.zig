//! Verifies and decodes the callbacks Tapsilat posts to an organization's callback URLs and to an
//! order's `payment_success_url` and `payment_failure_url`.
//!
//! Every callback carries `Tapsilat-Signature: t=<unix time>,v1=<hex HMAC-SHA256>`, where the HMAC
//! is keyed with the webhook secret from the panel's callback settings and covers the timestamp, a
//! dot and the raw request body.

const std = @import("std");
const models = @import("models.zig");

const Allocator = std.mem.Allocator;
const HmacSha256 = std.crypto.auth.hmac.sha2.HmacSha256;
const OrderStatusCode = models.OrderStatusCode;

/// The header that carries the signature of every callback Tapsilat sends.
pub const signature_header = "Tapsilat-Signature";

/// How many seconds a callback's signature timestamp may differ from the current time.
pub const default_tolerance_seconds: i64 = 300;

pub const VerifyOptions = struct {
    /// Seconds the signature timestamp may differ from `now`; 0 disables the check.
    tolerance_seconds: i64 = default_tolerance_seconds,
    /// The current Unix time in seconds, such as `std.Io.Clock.real.now(io).toSeconds()`.
    now: i64,
};

/// Verifies the `Tapsilat-Signature` header of a callback against the webhook secret.
///
/// The header's timestamp must be within `options.tolerance_seconds` of `options.now`, so that a
/// captured callback cannot be replayed. `payload` must be the raw request body, before any JSON
/// decoding. The signatures are compared in constant time.
///
/// A bare hex HMAC-SHA256 of the payload, with or without a "sha256=" prefix, is still accepted
/// for signatures made the way earlier Tapsilat SDKs documented.
pub fn verify(payload: []const u8, signature: []const u8, secret: []const u8, options: VerifyOptions) bool {
    const header = std.mem.trim(u8, signature, trim_chars);
    if (header.len == 0 or secret.len == 0) return false;

    if (std.mem.startsWith(u8, header, "sha256=") or std.mem.findScalar(u8, header, '=') == null) {
        var mac: [HmacSha256.mac_length]u8 = undefined;
        HmacSha256.create(&mac, payload, secret);
        return hexEql(mac, std.mem.cutPrefix(u8, header, "sha256=") orelse header);
    }

    var timestamp: ?[]const u8 = null;
    var has_signature = false;
    var parts = std.mem.splitScalar(u8, header, ',');
    while (parts.next()) |part| {
        const key, const value = std.mem.cutScalar(u8, std.mem.trim(u8, part, trim_chars), '=') orelse continue;
        if (std.mem.eql(u8, key, "t")) {
            timestamp = value;
        } else if (std.mem.eql(u8, key, "v1")) {
            has_signature = true;
        }
    }
    const t = timestamp orelse return false;
    if (!has_signature or t.len == 0 or !isDigits(t)) return false;

    if (options.tolerance_seconds > 0) {
        const seconds = std.fmt.parseInt(i64, t, 10) catch return false;
        const skew = @as(i128, options.now) - seconds;
        if (skew > options.tolerance_seconds or skew < -options.tolerance_seconds) return false;
    }

    var hmac = HmacSha256.init(secret);
    hmac.update(t);
    hmac.update(".");
    hmac.update(payload);
    const mac = hmac.finalResult();

    parts.reset();
    while (parts.next()) |part| {
        const key, const value = std.mem.cutScalar(u8, std.mem.trim(u8, part, trim_chars), '=') orelse continue;
        if (std.mem.eql(u8, key, "v1") and hexEql(mac, value)) return true;
    }
    return false;
}

/// Calls `verify` with the default tolerance and the current time from `io`'s real-time clock.
pub fn verifyNow(io: std.Io, payload: []const u8, signature: []const u8, secret: []const u8) bool {
    return verify(payload, signature, secret, .{ .now = std.Io.Clock.real.now(io).toSeconds() });
}

/// The callback types an organization can choose in the panel.
pub const EventType = enum { order, order_lite, order_payment_detail, extended_order, payment_facilitator };

pub const ParseError = error{
    /// The body is not a JSON object.
    InvalidWebhookPayload,
} || Allocator.Error;

/// A callback: `{"type": "...", "data": {...}, "token": "<delivery id>"}`.
///
/// The shape of `data` depends on the type: "order_lite" (the default), "order",
/// "order_payment_detail", "extended_order" or "payment_facilitator". `reference_id`,
/// `conversation_id` and `status` are read from whichever shape arrived.
///
/// Verify the signature with `verify` before trusting a callback.
pub const Event = struct {
    /// The callback type as sent, such as "order_lite"; see `eventType`.
    type: ?[]const u8,
    /// Unique per delivery.
    token: ?[]const u8,
    /// The callback's "data" object, or the whole payload when it has none.
    data: std.json.ObjectMap,
    /// The decoded payload.
    payload: std.json.ObjectMap,
    /// The order's reference ID, whatever the callback type.
    reference_id: ?[]const u8,
    /// The conversation ID the order was created with.
    conversation_id: ?[]const u8,
    /// The order status, or null when the callback type carries none.
    status: ?OrderStatusCode,

    /// Decodes a raw callback body. Call `deinit` on the result to free it.
    pub fn parse(allocator: Allocator, body: []const u8) ParseError!std.json.Parsed(Event) {
        const parsed = std.json.parseFromSlice(std.json.Value, allocator, body, .{
            .duplicate_field_behavior = .use_last,
        }) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => return error.InvalidWebhookPayload,
        };
        errdefer parsed.deinit();
        if (parsed.value != .object) return error.InvalidWebhookPayload;
        return .{
            .arena = parsed.arena,
            .value = try fromPayload(parsed.arena.allocator(), parsed.value.object),
        };
    }

    fn fromPayload(arena: Allocator, payload: std.json.ObjectMap) Allocator.Error!Event {
        const data = object(payload.get("data")) orelse payload;
        const order = object(data.get("order"));
        return .{
            .type = string(payload.get("type")),
            .token = string(payload.get("token")),
            .data = data,
            .payload = payload,
            .reference_id = try firstId(arena, &.{
                data.get("orderReferenceId"),
                data.get("order_reference_id"),
                data.get("reference_id"),
                if (order) |o| o.get("reference_id") else null,
            }),
            .conversation_id = try firstId(arena, &.{
                data.get("conversationId"),
                data.get("conversation_id"),
            }),
            .status = statusOf(data.get("status")) orelse
                if (order) |o| statusOf(o.get("status")) else null,
        };
    }

    pub fn eventType(self: Event) ?EventType {
        return std.meta.stringToEnum(EventType, self.type orelse return null);
    }

    /// The status name, such as "Paid".
    pub fn statusName(self: Event) ?[]const u8 {
        return (self.status orelse return null).name();
    }

    pub fn isPaid(self: Event) bool {
        return (self.status orelse return false).isPaid();
    }

    pub fn isFailed(self: Event) bool {
        return (self.status orelse return false).isFailed();
    }

    pub fn isRefunded(self: Event) bool {
        return (self.status orelse return false).isRefunded();
    }
};

/// What PHP's trim() strips, so every SDK reads the header the same way.
const trim_chars = " \t\n\r\x00\x0b";

const zero_uuid = "00000000-0000-0000-0000-000000000000";

/// Compares a MAC with a hex signature in constant time, ignoring the signature's case.
fn hexEql(mac: [HmacSha256.mac_length]u8, signature: []const u8) bool {
    const expected = std.fmt.bytesToHex(mac, .lower);
    if (signature.len != expected.len) return false;
    var lowered: [expected.len]u8 = undefined;
    _ = std.ascii.lowerString(&lowered, signature);
    return std.crypto.timing_safe.eql([expected.len]u8, expected, lowered);
}

fn isDigits(text: []const u8) bool {
    for (text) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }
    return true;
}

fn object(value: ?std.json.Value) ?std.json.ObjectMap {
    return switch (value orelse return null) {
        .object => |map| map,
        else => null,
    };
}

fn string(value: ?std.json.Value) ?[]const u8 {
    return switch (value orelse return null) {
        .string => |text| text,
        else => null,
    };
}

fn statusOf(value: ?std.json.Value) ?OrderStatusCode {
    return OrderStatusCode.fromJson(value orelse return null);
}

/// Returns the first non-empty ID; an integer ID becomes its decimal text, allocated in `arena`.
fn firstId(arena: Allocator, values: []const ?std.json.Value) Allocator.Error!?[]const u8 {
    for (values) |value| {
        switch (value orelse continue) {
            .string => |text| if (text.len > 0 and !std.mem.eql(u8, text, zero_uuid)) return text,
            .integer => |number| return try std.fmt.allocPrint(arena, "{d}", .{number}),
            else => {},
        }
    }
    return null;
}

// An order_lite callback and a known-good Tapsilat-Signature for this body and secret; the signature was
// computed with openssl, independently of the SDK.
const test_payload =
    \\{"data":{"id":"5f0c6f1e-1111-4a5b-9c1d-2e3f4a5b6c7d","orderReferenceId":"0b6a4f9e-2222-4c3d-8e9f-a1b2c3d4e5f6","conversationId":"wc-1001","status":"3"},"type":"order_lite","token":"9d8c7b6a-3333-4e5f-a6b7-c8d9e0f1a2b3"}
;
const test_secret = "whsec_test";
const test_timestamp: i64 = 1726480000;
const test_signature = "3e003945e8122172a03ae1aa56fd099b56e6ac11a8472c03e33809c7c480aeb6";
const test_header = std.fmt.comptimePrint("t={d},v1={s}", .{ test_timestamp, test_signature });

fn expectVerified(expected: bool, payload: []const u8, signature: []const u8, secret: []const u8, options: VerifyOptions) !void {
    try std.testing.expectEqual(expected, verify(payload, signature, secret, options));
}

test "verifies the Tapsilat-Signature header" {
    try expectVerified(true, test_payload, test_header, test_secret, .{ .now = test_timestamp + 10 });

    var upper: [test_signature.len]u8 = undefined;
    _ = std.ascii.upperString(&upper, test_signature);
    var buffer: [128]u8 = undefined;
    const spaced = try std.fmt.bufPrint(&buffer, " t={d}, v1={s} ", .{ test_timestamp, &upper });
    try expectVerified(true, test_payload, spaced, test_secret, .{ .now = test_timestamp });
}

test "rejects a tampered body or the wrong secret" {
    const tampered = try std.mem.replaceOwned(u8, std.testing.allocator, test_payload, "\"status\":\"3\"", "\"status\":\"13\"");
    defer std.testing.allocator.free(tampered);

    try expectVerified(false, tampered, test_header, test_secret, .{ .now = test_timestamp });
    try expectVerified(false, test_payload, test_header, "other", .{ .now = test_timestamp });
    try expectVerified(false, test_payload, test_header, "", .{ .now = test_timestamp });
    try expectVerified(false, test_payload, "", test_secret, .{ .now = test_timestamp });
}

test "rejects a replayed or malformed header" {
    try expectVerified(false, test_payload, test_header, test_secret, .{ .now = test_timestamp + 301 });
    try expectVerified(false, test_payload, test_header, test_secret, .{ .now = test_timestamp - 301 });
    try expectVerified(true, test_payload, test_header, test_secret, .{ .now = test_timestamp + 86400, .tolerance_seconds = 0 });
    try expectVerified(false, test_payload, "v1=" ++ test_signature, test_secret, .{ .now = test_timestamp, .tolerance_seconds = 0 });
    try expectVerified(false, test_payload, std.fmt.comptimePrint("t={d}", .{test_timestamp}), test_secret, .{ .now = test_timestamp, .tolerance_seconds = 0 });
    try expectVerified(false, test_payload, "t=1726480000.5,v1=" ++ test_signature, test_secret, .{ .now = test_timestamp, .tolerance_seconds = 0 });

    // A timestamp too large for an i64, or an extreme clock, is rejected rather than overflowing
    try expectVerified(false, test_payload, "t=99999999999999999999999,v1=" ++ test_signature, test_secret, .{ .now = test_timestamp });
    try expectVerified(false, test_payload, test_header, test_secret, .{ .now = std.math.minInt(i64) });
}

test "accepts any of several v1 signatures" {
    const zeros: [64]u8 = @splat('0');
    const header = std.fmt.comptimePrint("t={d},v1={s},v1={s}", .{ test_timestamp, &zeros, test_signature });
    try expectVerified(true, test_payload, header, test_secret, .{ .now = test_timestamp });
}

test "verifyNow uses the current time" {
    const now = std.Io.Clock.real.now(std.testing.io).toSeconds();
    var hmac = HmacSha256.init(test_secret);
    var timestamp_buffer: [20]u8 = undefined;
    const timestamp = try std.fmt.bufPrint(&timestamp_buffer, "{d}", .{now});
    hmac.update(timestamp);
    hmac.update(".");
    hmac.update(test_payload);
    const signature = std.fmt.bytesToHex(hmac.finalResult(), .lower);
    var header_buffer: [128]u8 = undefined;
    const header = try std.fmt.bufPrint(&header_buffer, "t={s},v1={s}", .{ timestamp, &signature });

    try std.testing.expect(verifyNow(std.testing.io, test_payload, header, test_secret));
    try std.testing.expect(!verifyNow(std.testing.io, test_payload, test_header, test_secret));
}

test "still accepts a bare HMAC of the body" {
    const legacy = "402b9d6616b32be533a4fc0300e8db19c304a56137d3fb274c614f30f9be6fbb";
    try expectVerified(true, test_payload, legacy, test_secret, .{ .now = 0 });
    try expectVerified(true, test_payload, "sha256=" ++ legacy, test_secret, .{ .now = 0 });
    try expectVerified(false, test_payload, legacy, "other", .{ .now = 0 });
    try expectVerified(false, test_payload, test_signature, test_secret, .{ .now = 0 });
}

test "parses an order_lite callback" {
    const event = try Event.parse(std.testing.allocator, test_payload);
    defer event.deinit();

    try std.testing.expectEqual(EventType.order_lite, event.value.eventType().?);
    try std.testing.expectEqualStrings("order_lite", event.value.type.?);
    try std.testing.expectEqualStrings("9d8c7b6a-3333-4e5f-a6b7-c8d9e0f1a2b3", event.value.token.?);
    try std.testing.expectEqualStrings("5f0c6f1e-1111-4a5b-9c1d-2e3f4a5b6c7d", event.value.data.get("id").?.string);
    try std.testing.expectEqualStrings("0b6a4f9e-2222-4c3d-8e9f-a1b2c3d4e5f6", event.value.reference_id.?);
    try std.testing.expectEqualStrings("wc-1001", event.value.conversation_id.?);
    try std.testing.expectEqual(OrderStatusCode.paid, event.value.status.?);
    try std.testing.expectEqualStrings("Paid", event.value.statusName().?);
    try std.testing.expect(event.value.isPaid());
    try std.testing.expect(!event.value.isFailed());
}

test "parses an order callback" {
    const event = try Event.parse(std.testing.allocator,
        \\{"type":"order","token":"t-1","data":{"id":"o-1","reference_id":"ref-1","conversation_id":"c-1","status":13}}
    );
    defer event.deinit();

    try std.testing.expectEqual(EventType.order, event.value.eventType().?);
    try std.testing.expectEqualStrings("ref-1", event.value.reference_id.?);
    try std.testing.expectEqualStrings("c-1", event.value.conversation_id.?);
    try std.testing.expectEqualStrings("Failure", event.value.statusName().?);
    try std.testing.expect(event.value.isFailed());
}

test "parses an order_payment_detail callback" {
    const event = try Event.parse(std.testing.allocator,
        \\{"type":"order_payment_detail","token":"t-2","data":{"id":"d-1","order_reference_id":"ref-2","conversation_id":"c-2",
        \\ "order":{"reference_id":"ref-2","id":"o-2","status":"Paid"},"order_payment_status":{"code":0}}}
    );
    defer event.deinit();

    try std.testing.expectEqualStrings("ref-2", event.value.reference_id.?);
    try std.testing.expectEqualStrings("c-2", event.value.conversation_id.?);
    try std.testing.expectEqual(OrderStatusCode.paid, event.value.status.?);
}

test "parses callbacks without a status" {
    const extended = try Event.parse(std.testing.allocator,
        \\{"type":"extended_order","data":{"id":"o-3","reference_id":"ref-3","terms":[{"reference_id":"term-1","status":2}]}}
    );
    defer extended.deinit();
    try std.testing.expectEqualStrings("ref-3", extended.value.reference_id.?);
    try std.testing.expect(extended.value.conversation_id == null);
    try std.testing.expect(extended.value.token == null);
    try std.testing.expect(extended.value.status == null);
    try std.testing.expect(extended.value.statusName() == null);
    try std.testing.expect(!extended.value.isPaid());

    const facilitator = try Event.parse(std.testing.allocator,
        \\{"type":"payment_facilitator","data":{"id":"p-1","payment_id":"pay-1","reference_id":"ref-4"}}
    );
    defer facilitator.deinit();
    try std.testing.expectEqual(EventType.payment_facilitator, facilitator.value.eventType().?);
    try std.testing.expectEqualStrings("ref-4", facilitator.value.reference_id.?);
}

test "ignores a zero UUID and reads integer IDs and float statuses" {
    const event = try Event.parse(std.testing.allocator,
        \\{"type":"order_payment_detail","data":{"order_reference_id":"00000000-0000-0000-0000-000000000000","order":{"reference_id":"ref-5"}}}
    );
    defer event.deinit();
    try std.testing.expectEqualStrings("ref-5", event.value.reference_id.?);

    const numeric = try Event.parse(std.testing.allocator,
        \\{"type":"order","data":{"reference_id":"","order":{"reference_id":42},"conversation_id":7,"status":10.0}}
    );
    defer numeric.deinit();
    try std.testing.expectEqualStrings("42", numeric.value.reference_id.?);
    try std.testing.expectEqualStrings("7", numeric.value.conversation_id.?);
    try std.testing.expect(numeric.value.isRefunded());
}

test "a body without a data object is its own data" {
    const event = try Event.parse(std.testing.allocator,
        \\{"reference_id":"ref-6","status":"Expired","data":"none"}
    );
    defer event.deinit();
    try std.testing.expect(event.value.type == null);
    try std.testing.expect(event.value.eventType() == null);
    try std.testing.expectEqualStrings("ref-6", event.value.reference_id.?);
    try std.testing.expectEqual(OrderStatusCode.expired, event.value.status.?);
}

test "rejects a payload that is not a JSON object" {
    try std.testing.expectError(error.InvalidWebhookPayload, Event.parse(std.testing.allocator, "\"order\""));
    try std.testing.expectError(error.InvalidWebhookPayload, Event.parse(std.testing.allocator, "[]"));
    try std.testing.expectError(error.InvalidWebhookPayload, Event.parse(std.testing.allocator, "{\"type\":"));
}

test "order status codes, names and groups" {
    try std.testing.expectEqual(OrderStatusCode.waiting_for_payment, OrderStatusCode.parse("waiting for payment").?);
    try std.testing.expectEqual(OrderStatusCode.expired, OrderStatusCode.parse("21").?);
    try std.testing.expectEqual(@as(u8, 7), OrderStatusCode.waiting_for_payment.code());
    try std.testing.expectEqualStrings("Partially refunded", OrderStatusCode.fromCode(15).?.name());
    try std.testing.expect(OrderStatusCode.parse("SUCCESS") == null);
    try std.testing.expect(OrderStatusCode.parse("99999999999999999999") == null);
    try std.testing.expect(OrderStatusCode.fromCode(99) == null);
    try std.testing.expect(OrderStatusCode.fromCode(0) == null);
    try std.testing.expect(OrderStatusCode.fromJson(.null) == null);
    try std.testing.expectEqual(OrderStatusCode.failure, OrderStatusCode.fromJson(.{ .integer = 13 }).?);
    try std.testing.expectEqual(OrderStatusCode.failure, OrderStatusCode.fromJson(.{ .float = 13.0 }).?);
    try std.testing.expect(OrderStatusCode.fromJson(.{ .float = 13.5 }) == null);

    try std.testing.expect(OrderStatusCode.parse("Sub merchant payment approved").?.isPaid());
    try std.testing.expect(OrderStatusCode.fromCode(9).?.isPaid());
    try std.testing.expect(!OrderStatusCode.parse("Waiting for payment").?.isPaid());
    try std.testing.expect(OrderStatusCode.parse("Expired").?.isFailed());
    try std.testing.expect(!OrderStatusCode.parse("Paid").?.isFailed());
    try std.testing.expect(OrderStatusCode.parse("10").?.isRefunded());

    const status: models.OrderStatus = .{ .status = "Partially Paid" };
    try std.testing.expectEqual(OrderStatusCode.partially_paid, status.code().?);
    try std.testing.expect((models.OrderStatus{}).code() == null);
}
