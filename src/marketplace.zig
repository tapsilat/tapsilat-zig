//! Marketplace sellers, payouts and policies (API v2). Revisions are opaque strings: send them
//! back exactly as received.

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;

pub const Marketplace = struct {
    client: *Client,

    /// Creates a logical seller; inspect `provisionings` for each VPOS account's readiness.
    pub fn createSubmerchant(self: Marketplace, request: models.MarketplaceSubmerchantCreateRequest) !Parsed(models.MarketplaceSubmerchantCreateResponse) {
        return self.client.call(models.MarketplaceSubmerchantCreateResponse, .POST, .v2, "/submerchants", request);
    }

    /// Returns a page of the seller directory, or an exact external ID match when `external_id` is set.
    pub fn listSubmerchants(self: Marketplace, page: i64, per_page: i64, external_id: ?[]const u8) !Parsed(models.MarketplaceSellerList) {
        var query = try client_mod.Query.init(self.client.allocator, "/submerchants");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        try query.add("external_id", external_id);
        return self.client.callQuery(models.MarketplaceSellerList, .v2, &query);
    }

    /// Returns the current seller profile and its revision.
    pub fn getSubmerchant(self: Marketplace, id: []const u8) !Parsed(models.MarketplaceSeller) {
        return self.client.callAt(models.MarketplaceSeller, .GET, .v2, .{ "/submerchants/", id }, null);
    }

    /// Replaces the profile at the supplied revision and reports whether review is required.
    pub fn updateSubmerchant(self: Marketplace, id: []const u8, request: models.MarketplaceProfileUpdate) !Parsed(models.MarketplaceProfileUpdateResponse) {
        return self.client.callAt(models.MarketplaceProfileUpdateResponse, .PATCH, .v2, .{ "/submerchants/", id }, request);
    }

    /// Returns the selected accounts' requirements for a seller operation.
    pub fn getSellerContracts(self: Marketplace, filter: models.MarketplaceContractFilter) !Parsed(models.MarketplaceContracts) {
        var query = try client_mod.Query.init(self.client.allocator, "/marketplace/seller-contracts");
        errdefer query.deinit();
        try query.add("currency_id", filter.currency_id);
        try query.add("seller_type", filter.seller_type);
        try query.add("operation", filter.operation);
        for (filter.vpos_ids orelse &.{}) |vpos_id| try query.add("vpos_id", vpos_id);
        return self.client.callQuery(models.MarketplaceContracts, .v2, &query);
    }

    /// Returns account registration, synchronization and available actions.
    pub fn getSellerAccounts(self: Marketplace, id: []const u8) !Parsed(models.MarketplaceSellerAccounts) {
        return self.client.callAt(models.MarketplaceSellerAccounts, .GET, .v2, .{ "/submerchants/", id, "/providers" }, null);
    }

    /// Executes an available account action at the supplied revision and environment.
    pub fn runSellerAccountAction(
        self: Marketplace,
        id: []const u8,
        vpos_id: []const u8,
        request: models.MarketplaceAccountAction,
    ) !Parsed(models.MarketplaceSubmerchantProvisioning) {
        return self.client.callAt(models.MarketplaceSubmerchantProvisioning, .POST, .v2, .{ "/submerchants/", id, "/providers/", vpos_id, "/actions" }, request);
    }

    /// Returns filtered organization-scoped payouts and their release state.
    pub fn listPayouts(self: Marketplace, filter: models.MarketplacePayoutFilter) !Parsed(models.MarketplacePayoutList) {
        var query = try client_mod.Query.init(self.client.allocator, "/submerchant-payouts");
        errdefer query.deinit();
        try query.add("order_id", filter.order_id);
        try query.add("submerchant_id", filter.submerchant_id);
        try query.add("vpos_id", filter.vpos_id);
        try query.add("provider", filter.provider);
        try query.add("status", filter.status);
        try query.add("release_status", filter.release_status);
        try query.add("approval_mode", filter.approval_mode);
        try query.add("currency", filter.currency);
        try query.add("eligibility", filter.eligibility);
        try query.add("search", filter.search);
        try query.add("min_amount", filter.min_amount);
        try query.add("max_amount", filter.max_amount);
        try query.add("start_date", filter.start_date);
        try query.add("end_date", filter.end_date);
        try query.add("page", filter.page);
        try query.add("per_page", filter.per_page);
        return self.client.callQuery(models.MarketplacePayoutList, .v2, &query);
    }

    /// Returns a payout's eligibility, approval and settlement state.
    pub fn getPayout(self: Marketplace, id: []const u8) !Parsed(models.MarketplacePayout) {
        return self.client.callAt(models.MarketplacePayout, .GET, .v2, .{ "/submerchant-payouts/", id }, null);
    }

    /// Submits eligible payouts to the approval workflow; the server answers 202 Accepted.
    pub fn approvePayouts(self: Marketplace, request: models.MarketplacePayoutApproval) !Parsed(models.MarketplacePayoutAcceptance) {
        return self.client.call(models.MarketplacePayoutAcceptance, .POST, .v2, "/submerchant-payouts/approve", request);
    }

    /// Changes allocation or withdraws approval; inspect `status` before treating it as complete.
    pub fn runPayoutOperation(self: Marketplace, payout_id: []const u8, request: models.MarketplacePayoutOperationInput) !Parsed(models.MarketplacePayoutOperation) {
        return self.client.callAt(models.MarketplacePayoutOperation, .POST, .v2, .{ "/submerchant-payouts/", payout_id, "/operations" }, request);
    }

    pub fn getPayoutOperation(self: Marketplace, id: []const u8) !Parsed(models.MarketplacePayoutOperation) {
        return self.client.callAt(models.MarketplacePayoutOperation, .GET, .v2, .{ "/marketplace/payout-operations/", id }, null);
    }

    /// Checks the provider result without repeating a mutation.
    pub fn reconcilePayoutOperation(self: Marketplace, id: []const u8) !Parsed(models.MarketplacePayoutOperation) {
        return self.client.callAt(models.MarketplacePayoutOperation, .POST, .v2, .{ "/marketplace/payout-operations/", id, "/reconcile" }, null);
    }

    /// Repeats an unresolved change only after verifying the previous provider state.
    pub fn retryPayoutOperation(self: Marketplace, id: []const u8) !Parsed(models.MarketplacePayoutOperation) {
        return self.client.callAt(models.MarketplacePayoutOperation, .POST, .v2, .{ "/marketplace/payout-operations/", id, "/retry" }, null);
    }

    pub fn getApprovalSettings(self: Marketplace) !Parsed(models.MarketplaceApprovalSettings) {
        return self.client.call(models.MarketplaceApprovalSettings, .GET, .v2, "/marketplace/approval-settings", null);
    }

    pub fn updateApprovalSettings(self: Marketplace, request: models.MarketplaceApprovalSettings) !Parsed(models.MarketplaceApprovalSettings) {
        return self.client.call(models.MarketplaceApprovalSettings, .PATCH, .v2, "/marketplace/approval-settings", request);
    }

    pub fn listApprovalPolicies(self: Marketplace) !Parsed(models.MarketplaceApprovalPolicies) {
        return self.client.call(models.MarketplaceApprovalPolicies, .GET, .v2, "/marketplace/approval-policies", null);
    }

    pub fn getApprovalPolicy(self: Marketplace, id: []const u8) !Parsed(models.MarketplaceApprovalPolicy) {
        return self.client.callAt(models.MarketplaceApprovalPolicy, .GET, .v2, .{ "/marketplace/approval-policies/", id }, null);
    }

    /// Creates an approval rule. A `currency_id` given as a unit such as "TRY" is resolved to its UUID.
    pub fn createApprovalPolicy(self: Marketplace, request: models.MarketplaceApprovalPolicyInput) !void {
        var resolved = request;
        const currency_id = try self.resolveCurrency(request.currency_id);
        defer if (currency_id) |value| self.client.allocator.free(value);
        if (currency_id) |value| resolved.currency_id = value;
        return self.client.callVoid(.POST, .v2, "/marketplace/approval-policies", resolved);
    }

    /// Replaces an approval rule. A `currency_id` given as a unit such as "TRY" is resolved to its UUID.
    pub fn updateApprovalPolicy(self: Marketplace, id: []const u8, request: models.MarketplaceApprovalPolicyInput) !void {
        var resolved = request;
        const currency_id = try self.resolveCurrency(request.currency_id);
        defer if (currency_id) |value| self.client.allocator.free(value);
        if (currency_id) |value| resolved.currency_id = value;
        const joined = try client_mod.path(self.client.allocator, .{ "/marketplace/approval-policies/", id });
        defer self.client.allocator.free(joined);
        return self.client.callVoid(.PATCH, .v2, joined, resolved);
    }

    /// Deletes an approval rule; the server answers 204 No Content.
    pub fn deleteApprovalPolicy(self: Marketplace, id: []const u8) !void {
        const joined = try client_mod.path(self.client.allocator, .{ "/marketplace/approval-policies/", id });
        defer self.client.allocator.free(joined);
        return self.client.callVoid(.DELETE, .v2, joined, null);
    }

    pub fn listReleasePolicies(self: Marketplace) !Parsed(models.MarketplaceReleasePolicies) {
        return self.client.call(models.MarketplaceReleasePolicies, .GET, .v2, "/marketplace/release-policies", null);
    }

    pub fn getReleasePolicy(self: Marketplace, id: []const u8) !Parsed(models.MarketplaceReleasePolicy) {
        return self.client.callAt(models.MarketplaceReleasePolicy, .GET, .v2, .{ "/marketplace/release-policies/", id }, null);
    }

    pub fn createReleasePolicy(self: Marketplace, request: models.MarketplaceReleasePolicyInput) !Parsed(models.MarketplaceReleasePolicy) {
        return self.client.call(models.MarketplaceReleasePolicy, .POST, .v2, "/marketplace/release-policies", request);
    }

    pub fn updateReleasePolicy(self: Marketplace, id: []const u8, request: models.MarketplaceReleasePolicyInput) !Parsed(models.MarketplaceReleasePolicy) {
        return self.client.callAt(models.MarketplaceReleasePolicy, .PATCH, .v2, .{ "/marketplace/release-policies/", id }, request);
    }

    /// Deletes a release policy; the server answers 204 No Content.
    pub fn deleteReleasePolicy(self: Marketplace, id: []const u8) !void {
        const joined = try client_mod.path(self.client.allocator, .{ "/marketplace/release-policies/", id });
        defer self.client.allocator.free(joined);
        return self.client.callVoid(.DELETE, .v2, joined, null);
    }

    fn resolveCurrency(self: Marketplace, reference: []const u8) !?[]u8 {
        if (std.mem.trim(u8, reference, " \t\r\n").len == 0) return null;
        return try self.client.resolveCurrencyId(self.client.allocator, reference);
    }
};
