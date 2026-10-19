//! The API client: configuration, request helpers and the service accessors.

const std = @import("std");
const Allocator = std.mem.Allocator;

const errors = @import("errors.zig");
const models = @import("models.zig");
const transport_mod = @import("transport.zig");

const Orders = @import("orders.zig").Orders;
const Organization = @import("organization.zig").Organization;
const Submerchants = @import("submerchants.zig").Submerchants;
const VposService = @import("vpos.zig").Vpos;
const Subscriptions = @import("subscriptions.zig").Subscriptions;
const Cards = @import("cards.zig").Cards;
const Marketplace = @import("marketplace.zig").Marketplace;

pub const ApiError = errors.ApiError;
pub const Transport = transport_mod.Transport;

pub const default_base_url = "https://panel.tapsilat.dev/api/v1";

pub const Config = struct {
    api_key: []const u8,
    /// The API v1 base URL. Marketplace calls use API v2, derived from it.
    base_url: []const u8 = default_base_url,
    /// Replaces the HTTP transport, for example with a fake in tests.
    transport: ?Transport = null,
};

pub const Version = enum { v1, v2 };

pub const Error = error{
    /// The API answered with an error status or a body that is not JSON; see `Client.last_api_error`.
    ApiError,
    /// A currency reference is neither a UUID nor one of the organization's currency units.
    UnknownCurrency,
    /// A currency reference is empty.
    CurrencyRequired,
};

/// A client for the Tapsilat API. It is not thread safe: `last_api_error` belongs to the
/// last call made through the client.
pub const Client = struct {
    allocator: Allocator,
    io: std.Io,
    config: Config,
    http: transport_mod.HttpTransport,
    /// Details of the last request that returned `error.ApiError`.
    last_api_error: ?ApiError = null,
    currency_ids: std.StringHashMapUnmanaged([]u8) = .empty,
    currency_cache_ready: bool = false,

    pub fn init(allocator: Allocator, io: std.Io, config: Config) Client {
        return .{
            .allocator = allocator,
            .io = io,
            .config = config,
            .http = .{ .client = .{ .allocator = allocator, .io = io } },
        };
    }

    pub fn deinit(self: *Client) void {
        self.clearApiError();
        self.invalidateCurrencyCache();
        self.currency_ids.deinit(self.allocator);
        self.http.deinit();
        self.* = undefined;
    }

    pub fn orders(self: *Client) Orders {
        return .{ .client = self };
    }

    pub fn organization(self: *Client) Organization {
        return .{ .client = self };
    }

    pub fn submerchants(self: *Client) Submerchants {
        return .{ .client = self };
    }

    pub fn vpos(self: *Client) VposService {
        return .{ .client = self };
    }

    pub fn subscriptions(self: *Client) Subscriptions {
        return .{ .client = self };
    }

    /// Card installments and saved cards.
    pub fn cards(self: *Client) Cards {
        return .{ .client = self };
    }

    /// Marketplace sellers, payouts and policies (API v2).
    pub fn marketplace(self: *Client) Marketplace {
        return .{ .client = self };
    }

    /// Creates an order. The buyer's GSM number is cleaned first, and the checkout URL is
    /// filled from the created order when it can be read.
    pub fn createOrder(self: *Client, order: models.Order) !std.json.Parsed(models.OrderResponse) {
        return self.orders().create(order);
    }

    /// Sends a request and decodes the JSON response into `T`. Pass `null` as `payload` for no body.
    /// The caller owns the result and must call `deinit` on it.
    pub fn call(
        self: *Client,
        comptime T: type,
        method: std.http.Method,
        version: Version,
        path_and_query: []const u8,
        payload: anytype,
    ) !std.json.Parsed(T) {
        const body = try self.request(method, version, path_and_query, payload);
        defer self.allocator.free(body);
        const json = if (std.mem.trim(u8, body, " \t\r\n").len == 0) "{}" else body;
        return std.json.parseFromSlice(T, self.allocator, json, .{
            .ignore_unknown_fields = true,
            .allocate = .alloc_always,
        });
    }

    /// Like `call`, with the path joined from `parts` by `path`.
    pub fn callAt(
        self: *Client,
        comptime T: type,
        method: std.http.Method,
        version: Version,
        parts: anytype,
        payload: anytype,
    ) !std.json.Parsed(T) {
        const joined = try path(self.allocator, parts);
        defer self.allocator.free(joined);
        return self.call(T, method, version, joined, payload);
    }

    /// Like `call`, with the query built by `query`, which is consumed.
    pub fn callQuery(self: *Client, comptime T: type, version: Version, query: *Query) !std.json.Parsed(T) {
        defer query.deinit();
        const joined = try query.finish();
        defer self.allocator.free(joined);
        return self.call(T, .GET, version, joined, null);
    }

    /// Sends a request and ignores the response body, such as a delete answered with 204.
    pub fn callVoid(
        self: *Client,
        method: std.http.Method,
        version: Version,
        path_and_query: []const u8,
        payload: anytype,
    ) !void {
        const body = try self.request(method, version, path_and_query, payload);
        self.allocator.free(body);
    }

    /// Sends a request and returns the response body, owned by the caller. An error status or
    /// a body that is not JSON returns `error.ApiError` and fills `last_api_error`.
    pub fn request(
        self: *Client,
        method: std.http.Method,
        version: Version,
        path_and_query: []const u8,
        payload: anytype,
    ) ![]u8 {
        self.clearApiError();

        const body: ?[]u8 = if (@TypeOf(payload) == @TypeOf(null))
            null
        else
            try std.json.Stringify.valueAlloc(self.allocator, payload, .{ .emit_null_optional_fields = false });
        defer if (body) |b| self.allocator.free(b);

        const full_url = try self.buildUrl(version, path_and_query);
        defer self.allocator.free(full_url);
        const authorization = try std.fmt.allocPrint(self.allocator, "Bearer {s}", .{self.config.api_key});
        defer self.allocator.free(authorization);

        const http_transport = self.config.transport orelse self.http.transport();
        const response = try http_transport.send(self.allocator, .{
            .method = method,
            .url = full_url,
            .authorization = authorization,
            .body = body,
        });
        defer self.allocator.free(response.content_type);

        if (response.status >= 400) {
            defer self.allocator.free(response.body);
            self.last_api_error = try ApiError.fromBody(self.allocator, response.status, response.body);
            return error.ApiError;
        }
        // A deployment serving the panel UI answers unknown routes with its HTML page and status 200
        const trimmed = std.mem.trimStart(u8, response.body, " \t\r\n");
        if (std.ascii.findIgnoreCase(response.content_type, "text/html") != null or std.mem.startsWith(u8, trimmed, "<")) {
            defer self.allocator.free(response.body);
            self.last_api_error = try ApiError.unexpectedResponse(self.allocator, response.status, response.content_type, response.body);
            return error.ApiError;
        }
        return response.body;
    }

    /// Returns the base URL for `version`: a trailing `/api/vN` is replaced with `/api/{version}`,
    /// otherwise `/api/{version}` is appended. The caller owns the result.
    pub fn versionedBaseUrl(self: *Client, version: Version) ![]u8 {
        const base = std.mem.trimEnd(u8, self.config.base_url, "/");
        if (version == .v1) return self.allocator.dupe(u8, base);
        if (std.mem.lastIndexOfScalar(u8, base, '/')) |slash| {
            const last = base[slash + 1 ..];
            const head = base[0..slash];
            if (isVersionSegment(last) and std.mem.endsWith(u8, head, "/api")) {
                return std.fmt.allocPrint(self.allocator, "{s}/{t}", .{ head, version });
            }
        }
        return std.fmt.allocPrint(self.allocator, "{s}/api/{t}", .{ base, version });
    }

    fn buildUrl(self: *Client, version: Version, path_and_query: []const u8) ![]u8 {
        const base = try self.versionedBaseUrl(version);
        defer self.allocator.free(base);
        return std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ base, std.mem.trimStart(u8, path_and_query, "/") });
    }

    /// Frees and clears `last_api_error`.
    pub fn clearApiError(self: *Client) void {
        if (self.last_api_error) |*api_error| api_error.deinit(self.allocator);
        self.last_api_error = null;
    }

    /// Returns the organization currency UUID for `reference`, owned by the caller. A UUID is
    /// returned unchanged; a unit such as "TRY" is looked up in the organization's currencies,
    /// which are cached. Most endpoints accept units directly, so this is only needed where a
    /// UUID is required.
    pub fn resolveCurrencyId(self: *Client, allocator: Allocator, reference: []const u8) ![]u8 {
        const trimmed = std.mem.trim(u8, reference, " \t\r\n");
        if (trimmed.len == 0) return error.CurrencyRequired;
        if (isUuid(trimmed)) return allocator.dupe(u8, trimmed);

        if (!self.currency_cache_ready) try self.loadCurrencies();

        var unit_buffer: [16]u8 = undefined;
        if (trimmed.len > unit_buffer.len) return error.UnknownCurrency;
        const unit = std.ascii.upperString(&unit_buffer, trimmed);
        const id = self.currency_ids.get(unit) orelse return error.UnknownCurrency;
        return allocator.dupe(u8, id);
    }

    /// Forgets the cached organization currencies.
    pub fn invalidateCurrencyCache(self: *Client) void {
        var it = self.currency_ids.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            self.allocator.free(entry.value_ptr.*);
        }
        self.currency_ids.clearRetainingCapacity();
        self.currency_cache_ready = false;
    }

    fn loadCurrencies(self: *Client) !void {
        const parsed = try self.call(models.OrganizationCurrenciesResponse, .GET, .v1, "/organization/currencies", null);
        defer parsed.deinit();
        self.invalidateCurrencyCache();
        for (parsed.value.currencies orelse &.{}) |currency| {
            const id = std.mem.trim(u8, currency.id orelse "", " ");
            const unit = std.mem.trim(u8, currency.currency_unit orelse "", " ");
            if (id.len == 0 or unit.len == 0) continue;
            const key = try std.ascii.allocUpperString(self.allocator, unit);
            errdefer self.allocator.free(key);
            const value = try self.allocator.dupe(u8, id);
            errdefer self.allocator.free(value);
            const entry = try self.currency_ids.getOrPut(self.allocator, key);
            if (entry.found_existing) {
                self.allocator.free(key);
                self.allocator.free(entry.value_ptr.*);
            }
            entry.value_ptr.* = value;
        }
        self.currency_cache_ready = true;
    }
};

fn isVersionSegment(segment: []const u8) bool {
    if (segment.len < 2 or segment[0] != 'v') return false;
    for (segment[1..]) |c| {
        if (!std.ascii.isDigit(c)) return false;
    }
    return true;
}

pub fn isUuid(value: []const u8) bool {
    if (value.len != 36) return false;
    for (value, 0..) |c, i| {
        switch (i) {
            8, 13, 18, 23 => if (c != '-') return false,
            else => if (!std.ascii.isHex(c)) return false,
        }
    }
    return true;
}

fn isUnreserved(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '-' or c == '.' or c == '_' or c == '~';
}

fn writeEscaped(writer: *std.Io.Writer, value: []const u8) std.Io.Writer.Error!void {
    for (value) |c| {
        if (isUnreserved(c)) {
            try writer.writeByte(c);
        } else {
            try writer.print("%{X:0>2}", .{c});
        }
    }
}

/// Escapes `value` for use as a single URL path segment. The caller owns the result.
pub fn escape(allocator: Allocator, value: []const u8) Allocator.Error![]u8 {
    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();
    writeEscaped(&out.writer, value) catch return error.OutOfMemory;
    return out.toOwnedSlice();
}

/// Joins path parts, escaping the odd-numbered ones (the IDs): `path(a, .{ "/vpos/", id })`.
pub fn path(allocator: Allocator, parts: anytype) Allocator.Error![]u8 {
    var out: std.Io.Writer.Allocating = .init(allocator);
    defer out.deinit();
    inline for (parts, 0..) |part, i| {
        if (i % 2 == 0) {
            out.writer.writeAll(part) catch return error.OutOfMemory;
        } else {
            writeEscaped(&out.writer, part) catch return error.OutOfMemory;
        }
    }
    return out.toOwnedSlice();
}

/// Builds a path with a query string, skipping null and empty values and keeping the order
/// in which parameters are added.
pub const Query = struct {
    out: std.Io.Writer.Allocating,
    has_params: bool = false,

    pub fn init(allocator: Allocator, base_path: []const u8) Allocator.Error!Query {
        var query: Query = .{ .out = .init(allocator) };
        query.out.writer.writeAll(base_path) catch return error.OutOfMemory;
        return query;
    }

    pub fn deinit(self: *Query) void {
        self.out.deinit();
    }

    /// Adds `name=value`. Strings, integers, floats and bools are supported; null and empty
    /// strings are skipped.
    pub fn add(self: *Query, name: []const u8, value: anytype) Allocator.Error!void {
        const T = @TypeOf(value);
        switch (@typeInfo(T)) {
            .optional => if (value) |inner| try self.add(name, inner),
            .null => {},
            .bool => try self.addText(name, if (value) "true" else "false"),
            .int, .comptime_int => try self.addFormatted(name, "{d}", value),
            .float, .comptime_float => try self.addFormatted(name, "{d}", value),
            .pointer => if (value.len > 0) try self.addText(name, value),
            else => @compileError("unsupported query value type " ++ @typeName(T)),
        }
    }

    fn addFormatted(self: *Query, name: []const u8, comptime fmt: []const u8, value: anytype) Allocator.Error!void {
        var buffer: [64]u8 = undefined;
        const text = std.fmt.bufPrint(&buffer, fmt, .{value}) catch unreachable;
        try self.addText(name, text);
    }

    fn addText(self: *Query, name: []const u8, value: []const u8) Allocator.Error!void {
        const writer = &self.out.writer;
        writer.writeByte(if (self.has_params) '&' else '?') catch return error.OutOfMemory;
        writeEscaped(writer, name) catch return error.OutOfMemory;
        writer.writeByte('=') catch return error.OutOfMemory;
        writeEscaped(writer, value) catch return error.OutOfMemory;
        self.has_params = true;
    }

    /// Returns the path with its query string; the caller owns it.
    pub fn finish(self: *Query) Allocator.Error![]u8 {
        return self.out.toOwnedSlice();
    }
};
