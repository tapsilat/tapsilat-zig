//! Subscriptions.

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;

pub const Subscriptions = struct {
    client: *Client,

    pub fn get(self: Subscriptions, request: models.SubscriptionGetRequest) !Parsed(models.SubscriptionDetail) {
        return self.client.call(models.SubscriptionDetail, .POST, .v1, "/subscription", request);
    }

    pub fn cancel(self: Subscriptions, request: models.SubscriptionCancelRequest) !void {
        return self.client.callVoid(.POST, .v1, "/subscription/cancel", request);
    }

    pub fn create(self: Subscriptions, request: models.SubscriptionCreateRequest) !Parsed(models.SubscriptionCreateResponse) {
        return self.client.call(models.SubscriptionCreateResponse, .POST, .v1, "/subscription/create", request);
    }

    pub fn list(self: Subscriptions, page: i64, per_page: i64) !Parsed(models.PaginatedData) {
        var query = try client_mod.Query.init(self.client.allocator, "/subscription/list");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        return self.client.callQuery(models.PaginatedData, .v1, &query);
    }

    pub fn redirect(self: Subscriptions, request: models.SubscriptionRedirectRequest) !Parsed(models.SubscriptionRedirectResponse) {
        return self.client.call(models.SubscriptionRedirectResponse, .POST, .v1, "/subscription/redirect", request);
    }
};
