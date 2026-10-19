//! API error details.

const std = @import("std");
const Allocator = std.mem.Allocator;

/// Details of the last failed request, kept in `Client.last_api_error` after a call returns
/// `error.ApiError`. The client owns the memory; it is freed by the next request or `deinit`.
pub const ApiError = struct {
    status_code: u16,
    /// The body's `status` field, else the HTTP reason phrase.
    status: []u8,
    /// The body's `code` field as text, such as "400000".
    code: ?[]u8 = null,
    /// The body's `message` field, else its `error` field.
    message: ?[]u8 = null,
    /// The body's `errors` object (per-field validation messages) as JSON text.
    errors_json: ?[]u8 = null,
    raw_body: []u8,

    /// Builds the error from an error response body such as `{"error":"...","code":5}` or
    /// `{"message":"INVALID_REQUEST_BODY","code":400000,"errors":{...}}`.
    pub fn fromBody(allocator: Allocator, status_code: u16, body: []const u8) Allocator.Error!ApiError {
        var result: ApiError = .{
            .status_code = status_code,
            .status = try allocator.dupe(u8, reasonPhrase(status_code)),
            .raw_body = try allocator.dupe(u8, body),
        };
        errdefer result.deinit(allocator);

        const parsed = std.json.parseFromSlice(std.json.Value, allocator, body, .{}) catch return result;
        defer parsed.deinit();
        if (parsed.value != .object) return result;
        const payload = parsed.value.object;

        if (payload.get("status")) |value| {
            if (try text(allocator, value)) |status| {
                allocator.free(result.status);
                result.status = status;
            }
        }
        if (payload.get("code")) |value| result.code = try text(allocator, value);
        if (payload.get("message") orelse payload.get("error")) |value| result.message = try text(allocator, value);
        if (payload.get("errors")) |value| {
            if (value == .object) result.errors_json = try std.json.Stringify.valueAlloc(allocator, value, .{});
        }
        return result;
    }

    /// Builds the error for a response that is not JSON, such as the panel's HTML page.
    pub fn unexpectedResponse(allocator: Allocator, status_code: u16, content_type: []const u8, body: []const u8) Allocator.Error!ApiError {
        const message = try std.fmt.allocPrint(
            allocator,
            "unexpected non-JSON response (Content-Type \"{s}\"); check that the endpoint URL and route are correct",
            .{content_type},
        );
        errdefer allocator.free(message);
        const status = try allocator.dupe(u8, reasonPhrase(status_code));
        errdefer allocator.free(status);
        return .{
            .status_code = status_code,
            .status = status,
            .message = message,
            .raw_body = try allocator.dupe(u8, body),
        };
    }

    pub fn deinit(self: *ApiError, allocator: Allocator) void {
        allocator.free(self.status);
        if (self.code) |value| allocator.free(value);
        if (self.message) |value| allocator.free(value);
        if (self.errors_json) |value| allocator.free(value);
        allocator.free(self.raw_body);
        self.* = undefined;
    }

    /// Writes the message in the SDKs' common format, for example
    /// "API request failed with status 400 (Bad Request): [400000] INVALID_REQUEST_BODY".
    pub fn format(self: ApiError, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("API request failed with status {d} ({s})", .{ self.status_code, self.status });
        if (self.message) |message| {
            if (self.code) |code| {
                try writer.print(": [{s}] {s}", .{ code, message });
            } else {
                try writer.print(": {s}", .{message});
            }
        } else if (self.raw_body.len > 0) {
            try writer.print(": {s}", .{self.raw_body});
        }
    }
};

fn text(allocator: Allocator, value: std.json.Value) Allocator.Error!?[]u8 {
    return switch (value) {
        .null => null,
        .string => |s| try allocator.dupe(u8, s),
        .integer => |n| try std.fmt.allocPrint(allocator, "{d}", .{n}),
        .float => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
        .number_string => |s| try allocator.dupe(u8, s),
        .bool => |b| try allocator.dupe(u8, if (b) "true" else "false"),
        else => try std.json.Stringify.valueAlloc(allocator, value, .{}),
    };
}

fn reasonPhrase(status_code: u16) []const u8 {
    const status: std.http.Status = @fromBackingInt(@intCast(status_code));
    return status.phrase() orelse "";
}
