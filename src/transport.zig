//! The HTTP transport. Tests replace it through `Config.transport`.

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const user_agent = "tapsilat-zig/0.1.0";

pub const Transport = struct {
    ptr: *anyopaque,
    sendFn: *const fn (ptr: *anyopaque, allocator: Allocator, request: Request) anyerror!Response,

    pub const Request = struct {
        method: std.http.Method,
        url: []const u8,
        /// The Authorization header value, such as "Bearer <token>".
        authorization: []const u8,
        /// The JSON body, if any.
        body: ?[]const u8,
    };

    /// A response whose `content_type` and `body` are owned by the allocator passed to `send`.
    pub const Response = struct {
        status: u16,
        content_type: []u8,
        body: []u8,
    };

    pub fn send(self: Transport, allocator: Allocator, request: Request) anyerror!Response {
        return self.sendFn(self.ptr, allocator, request);
    }
};

/// Sends requests with `std.http.Client`.
pub const HttpTransport = struct {
    client: std.http.Client,

    pub fn transport(self: *HttpTransport) Transport {
        return .{ .ptr = self, .sendFn = send };
    }

    pub fn deinit(self: *HttpTransport) void {
        self.client.deinit();
    }

    fn send(ptr: *anyopaque, allocator: Allocator, request: Transport.Request) anyerror!Transport.Response {
        const self: *HttpTransport = @ptrCast(@alignCast(ptr));
        const client = &self.client;
        const uri = try std.Uri.parse(request.url);

        // POST, PUT and PATCH always carry a body, even an empty one
        const body: ?[]const u8 = request.body orelse switch (request.method) {
            .POST, .PUT, .PATCH => "",
            else => null,
        };

        // std.http.Client refuses a body on DELETE, so its length is sent as a header and the
        // body is written after the head
        const body_after_head = body != null and !request.method.requestHasBody();
        var length_buffer: [20]u8 = undefined;
        const length = std.fmt.bufPrint(&length_buffer, "{d}", .{if (body) |b| b.len else 0}) catch unreachable;
        const accept: std.http.Header = .{ .name = "accept", .value = "application/json" };
        const with_length = [_]std.http.Header{ accept, .{ .name = "content-length", .value = length } };

        var req = try client.request(request.method, uri, .{
            .headers = .{
                .authorization = .{ .override = request.authorization },
                .user_agent = .{ .override = user_agent },
                .content_type = if (body != null) .{ .override = "application/json" } else .default,
            },
            .extra_headers = if (body_after_head) &with_length else with_length[0..1],
            // The API does not redirect; refusing redirects keeps the token on this host
            .redirect_behavior = .not_allowed,
        });
        defer req.deinit();

        if (body_after_head) {
            try req.sendBodilessUnflushed();
            try req.connection.?.writer().writeAll(body.?);
            try req.connection.?.flush();
        } else if (body) |payload| {
            req.transfer_encoding = .{ .content_length = payload.len };
            var writer = try req.sendBodyUnflushed(&.{});
            try writer.writer.writeAll(payload);
            try writer.end();
            try req.connection.?.flush();
        } else {
            try req.sendBodiless();
        }

        var response = try req.receiveHead(&.{});

        // The head strings are invalidated once the body is read
        const content_type = try allocator.dupe(u8, response.head.content_type orelse "");
        errdefer allocator.free(content_type);

        const decompress_buffer: []u8 = switch (response.head.content_encoding) {
            .identity => &.{},
            .zstd => try allocator.alloc(u8, std.compress.zstd.default_window_len),
            .deflate, .gzip => try allocator.alloc(u8, std.compress.flate.max_window_len),
            .compress => return error.UnsupportedCompressionMethod,
        };
        defer allocator.free(decompress_buffer);

        var out: std.Io.Writer.Allocating = .init(allocator);
        defer out.deinit();
        var transfer_buffer: [64]u8 = undefined;
        var decompress: std.http.Decompress = undefined;
        const reader = response.readerDecompressing(&transfer_buffer, &decompress, decompress_buffer);
        _ = reader.streamRemaining(&out.writer) catch |err| switch (err) {
            error.ReadFailed => return response.bodyErr().?,
            else => |e| return e,
        };

        return .{
            .status = @backingInt(response.head.status),
            .content_type = content_type,
            .body = try out.toOwnedSlice(),
        };
    }
};
