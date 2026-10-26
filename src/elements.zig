//! Tapsilat Elements sessions for the native Android and iOS card sheet.

const std = @import("std");
const client_mod = @import("client.zig");
const models = @import("models.zig");

const Client = client_mod.Client;
const Parsed = std.json.Parsed;

/// Your backend creates a session with its secret API key and hands only the session's
/// `client_secret` to the app, which opens the card sheet with it. Card data goes from the sheet
/// to Tapsilat encrypted and never reaches your backend.
pub const Elements = struct {
    client: *Client,

    /// Creates a session with `POST /elements/sessions`. Hand `client_secret` to the app that
    /// opens the card sheet; only this call returns it. Do not log or store it.
    pub fn createSession(self: Elements, request: models.ElementsSessionCreateRequest) !Parsed(models.ElementsSessionWithSecret) {
        return self.client.call(models.ElementsSessionWithSecret, .POST, .v1, "/elements/sessions", request);
    }

    /// Returns the session's authoritative state and outcome with `GET /elements/sessions/{id}`.
    /// Read it on your backend before fulfilling, rather than trusting what the app reports.
    pub fn getSession(self: Elements, id: []const u8) !Parsed(models.ElementsSession) {
        return self.client.callAt(models.ElementsSession, .GET, .v1, .{ "/elements/sessions/", id }, null);
    }

    /// Cancels a session that is still waiting for a card with
    /// `POST /elements/sessions/{id}/cancel`, which takes no body. A session that is confirming
    /// or has completed comes back unchanged.
    pub fn cancelSession(self: Elements, id: []const u8) !Parsed(models.ElementsSession) {
        return self.client.callAt(models.ElementsSession, .POST, .v1, .{ "/elements/sessions/", id, "/cancel" }, null);
    }
};
