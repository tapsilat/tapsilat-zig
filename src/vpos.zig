//! Virtual POS and VPOS submerchants.

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;

pub const Vpos = struct {
    client: *Client,

    pub fn list(self: Vpos, page: i64, per_page: i64, filter: models.VposListFilter) !Parsed(models.VposListResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/vpos");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        try query.add("suborganization_id", filter.suborganization_id);
        return self.client.callQuery(models.VposListResponse, .v1, &query);
    }

    /// Creates a VPOS. `currencies` accepts currency UUIDs or units such as "TRY".
    pub fn create(self: Vpos, request: models.VposCreateRequest) !Parsed(models.VposMutationResponse) {
        return self.client.call(models.VposMutationResponse, .POST, .v1, "/vpos", request);
    }

    pub fn get(self: Vpos, id: []const u8) !Parsed(models.Vpos) {
        return self.client.callAt(models.Vpos, .GET, .v1, .{ "/vpos/", id }, null);
    }

    /// Replaces a VPOS configuration: read it with `get` and send every field back.
    pub fn update(self: Vpos, id: []const u8, request: models.VposUpdateRequest) !Parsed(models.VposMutationResponse) {
        return self.client.callAt(models.VposMutationResponse, .PATCH, .v1, .{ "/vpos/", id }, request);
    }

    pub fn delete(self: Vpos, id: []const u8) !Parsed(models.VposMutationResponse) {
        return self.client.callAt(models.VposMutationResponse, .DELETE, .v1, .{ "/vpos/", id }, null);
    }

    pub fn listAcquirers(self: Vpos) !Parsed(models.VposAcquirerListResponse) {
        return self.client.call(models.VposAcquirerListResponse, .GET, .v1, "/vpos/acquirers", null);
    }

    pub fn listCardSchemes(self: Vpos) !Parsed(models.CardSchemeListResponse) {
        return self.client.call(models.CardSchemeListResponse, .GET, .v1, "/vpos/card-schemes", null);
    }

    pub fn listAcquirerTemplates(self: Vpos) !Parsed(models.VposAcquirerTemplateListResponse) {
        return self.client.call(models.VposAcquirerTemplateListResponse, .GET, .v1, "/vpos/acquirer-templates", null);
    }

    pub fn listSubmerchants(
        self: Vpos,
        page: i64,
        per_page: i64,
        vpos_id: ?[]const u8,
        external_reference_id: ?[]const u8,
    ) !Parsed(models.VposSubmerchantListResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/vpos-submerchant");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        try query.add("vpos_id", vpos_id);
        try query.add("external_reference_id", external_reference_id);
        return self.client.callQuery(models.VposSubmerchantListResponse, .v1, &query);
    }

    pub fn createSubmerchant(self: Vpos, request: models.VposSubmerchantCreateRequest) !Parsed(models.VposMutationResponse) {
        return self.client.call(models.VposMutationResponse, .POST, .v1, "/vpos-submerchant", request);
    }

    /// Returns a VPOS submerchant; the server answers 404 when it does not exist.
    pub fn getSubmerchant(self: Vpos, id: []const u8) !Parsed(models.VposSubmerchant) {
        return self.client.callAt(models.VposSubmerchant, .GET, .v1, .{ "/vpos-submerchant/", id }, null);
    }

    pub fn updateSubmerchant(self: Vpos, id: []const u8, request: models.VposSubmerchantUpdateRequest) !Parsed(models.VposMutationResponse) {
        return self.client.callAt(models.VposMutationResponse, .PATCH, .v1, .{ "/vpos-submerchant/", id }, request);
    }

    pub fn deleteSubmerchant(self: Vpos, id: []const u8) !Parsed(models.VposMutationResponse) {
        return self.client.callAt(models.VposMutationResponse, .DELETE, .v1, .{ "/vpos-submerchant/", id }, null);
    }
};
