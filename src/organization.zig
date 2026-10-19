//! Organization settings, currencies, users and sub-organizations.

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;

pub const Organization = struct {
    client: *Client,

    pub fn getSettings(self: Organization) !Parsed(models.OrganizationSettings) {
        return self.client.call(models.OrganizationSettings, .GET, .v1, "/organization/settings", null);
    }

    pub fn getCurrencies(self: Organization) !Parsed(models.OrganizationCurrenciesResponse) {
        return self.client.call(models.OrganizationCurrenciesResponse, .GET, .v1, "/organization/currencies", null);
    }

    /// Lists the currencies the organization can add.
    pub fn listCurrencyPresets(self: Organization) !Parsed(models.OrganizationCurrencyPresetsResponse) {
        return self.client.call(models.OrganizationCurrencyPresetsResponse, .GET, .v1, "/organization/currency-presets", null);
    }

    /// Adds a currency to the organization by its code, such as "EUR".
    pub fn createCurrency(self: Organization, currency_code: []const u8) !Parsed(models.CreateOrganizationCurrencyResponse) {
        const code = try std.ascii.allocUpperString(self.client.allocator, std.mem.trim(u8, currency_code, " \t\r\n"));
        defer self.client.allocator.free(code);
        const response = try self.client.call(models.CreateOrganizationCurrencyResponse, .POST, .v1, "/organization/currencies", .{ .currency_code = code });
        self.client.invalidateCurrencyCache();
        return response;
    }

    pub fn createUser(self: Organization, request: models.OrgCreateUserRequest) !Parsed(models.OrgCreateUserResponse) {
        return self.client.call(models.OrgCreateUserResponse, .POST, .v1, "/organization/user/create", request);
    }

    /// Creates an access token for an organization user; `expire` is given in minutes.
    pub fn createUserToken(self: Organization, request: models.OrgUserTokenCreateRequest) !Parsed(models.OrgUserTokenCreateResponse) {
        return self.client.call(models.OrgUserTokenCreateResponse, .POST, .v1, "/organization/user/token", request);
    }

    pub fn listSuborganizations(self: Organization, page: i64, per_page: i64) !Parsed(models.SuborganizationListResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/organization/suborganizations");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        return self.client.callQuery(models.SuborganizationListResponse, .v1, &query);
    }

    /// Returns a sub-organization; the server answers 404 when it does not exist.
    pub fn getSuborganization(self: Organization, id: []const u8) !Parsed(models.SuborganizationDetail) {
        return self.client.callAt(models.SuborganizationDetail, .GET, .v1, .{ "/organization/suborganizations/", id }, null);
    }

    pub fn getSuborganizationSubmerchant(self: Organization, suborganization_id: []const u8) !Parsed(models.SuborganizationSubmerchantMapping) {
        return self.client.callAt(models.SuborganizationSubmerchantMapping, .GET, .v1, .{ "/organization/suborganizations/", suborganization_id, "/submerchant" }, null);
    }
};
