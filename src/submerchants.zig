//! Submerchants, settlement approval and payout events.

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;

pub const Submerchants = struct {
    client: *Client,

    /// Creates a submerchant. `currency_id` accepts a currency UUID or unit such as "TRY".
    pub fn create(self: Submerchants, request: models.SubmerchantCreateRequest) !Parsed(models.SubmerchantMutationResponse) {
        return self.client.call(models.SubmerchantMutationResponse, .POST, .v1, "/submerchants", request);
    }

    pub fn get(self: Submerchants, id: []const u8) !Parsed(models.Submerchant) {
        return self.client.callAt(models.Submerchant, .GET, .v1, .{ "/submerchants/", id }, null);
    }

    /// Lists submerchants; the rows come in the `row` field.
    pub fn list(self: Submerchants, page: i64, per_page: i64) !Parsed(models.SubmerchantListResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/submerchants");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        return self.client.callQuery(models.SubmerchantListResponse, .v1, &query);
    }

    /// Replaces a submerchant; every field is stored as sent.
    pub fn update(self: Submerchants, id: []const u8, request: models.SubmerchantUpdateRequest) !Parsed(models.SubmerchantMutationResponse) {
        return self.client.callAt(models.SubmerchantMutationResponse, .PATCH, .v1, .{ "/submerchants/", id }, request);
    }

    pub fn delete(self: Submerchants, id: []const u8) !Parsed(models.SubmerchantMutationResponse) {
        return self.client.callAt(models.SubmerchantMutationResponse, .DELETE, .v1, .{ "/submerchants/", id }, null);
    }

    pub fn getSuborganization(self: Submerchants, id: []const u8) !Parsed(models.SubmerchantSuborganizationMapping) {
        return self.client.callAt(models.SubmerchantSuborganizationMapping, .GET, .v1, .{ "/submerchants/", id, "/suborganization" }, null);
    }

    /// Records an item business event; the server answers 202 Accepted.
    pub fn recordPayoutEvent(self: Submerchants, request: models.SubmerchantPayoutEventRequest) !Parsed(models.SubmerchantPayoutEventResponse) {
        return self.client.call(models.SubmerchantPayoutEventResponse, .POST, .v1, "/submerchant-payout-events", request);
    }

    /// Approves settlement of an item payment to its submerchant.
    pub fn approvePayment(self: Submerchants, request: models.SubmerchantPaymentAction) !Parsed(models.SubmerchantPaymentActionResponse) {
        return self.client.call(models.SubmerchantPaymentActionResponse, .POST, .v1, "/submerchants/payment/approve", request);
    }

    /// Withdraws settlement approval of an item payment.
    pub fn disapprovePayment(self: Submerchants, request: models.SubmerchantPaymentAction) !Parsed(models.SubmerchantPaymentActionResponse) {
        return self.client.call(models.SubmerchantPaymentActionResponse, .POST, .v1, "/submerchants/payment/disapprove", request);
    }

    /// Changes the seller or payout of a completed marketplace item.
    pub fn updatePaymentItem(self: Submerchants, request: models.SubmerchantPaymentItemUpdate) !Parsed(models.SubmerchantPaymentItemUpdateResponse) {
        return self.client.call(models.SubmerchantPaymentItemUpdateResponse, .PUT, .v1, "/submerchants/payment/item", request);
    }
};
