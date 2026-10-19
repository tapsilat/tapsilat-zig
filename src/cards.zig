//! Card installments and saved cards (tokenization).

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;

pub const Cards = struct {
    client: *Client,

    /// Returns the installment options and commission rates for a card BIN and amount.
    pub fn getInstallments(self: Cards, request: models.CardInstallmentsRequest) !Parsed(models.CardInstallmentsResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/card/installments");
        errdefer query.deinit();
        try query.add("bin", request.bin);
        try query.add("amount", request.amount);
        try query.add("currency", request.currency);
        if (request.is_three_d) try query.add("is_three_d", true);
        return self.client.callQuery(models.CardInstallmentsResponse, .v1, &query);
    }

    /// Returns installment options grouped by bank card program, with an interest-free flag per row.
    pub fn getInstallmentTable(self: Cards, request: models.InstallmentTableRequest) !Parsed(models.InstallmentTableResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/card/installment-table");
        errdefer query.deinit();
        try query.add("amount", request.amount);
        try query.add("currency", request.currency);
        if (request.is_three_d) try query.add("is_three_d", true);
        return self.client.callQuery(models.InstallmentTableResponse, .v1, &query);
    }

    /// Tokenizes a card and returns 3D secure form details when required.
    pub fn tokenize(self: Cards, request: models.CardTokenizeRequest) !Parsed(models.CardTokenizeResponse) {
        return self.client.call(models.CardTokenizeResponse, .POST, .v1, "/tokenization/card/tokenize", request);
    }

    pub fn listSaved(self: Cards, page: i64, per_page: i64) !Parsed(models.ListSavedCardsResponse) {
        var query = try client_mod.Query.init(self.client.allocator, "/tokenization/card/list");
        errdefer query.deinit();
        try query.add("page", page);
        try query.add("per_page", per_page);
        return self.client.callQuery(models.ListSavedCardsResponse, .v1, &query);
    }

    pub fn deleteSaved(self: Cards, id: []const u8) !Parsed(models.DeleteSavedCardResponse) {
        return self.client.callAt(models.DeleteSavedCardResponse, .DELETE, .v1, .{ "/tokenization/card/", id }, null);
    }
};
