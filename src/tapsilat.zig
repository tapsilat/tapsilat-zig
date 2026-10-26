//! Zig client library for the Tapsilat payment API.
//!
//! ```zig
//! var client = tapsilat.Client.init(allocator, io, .{ .api_key = "YOUR_API_KEY" });
//! defer client.deinit();
//! const order = try client.orders().get("reference-id");
//! defer order.deinit();
//! ```
//!
//! Calls that fail with `error.ApiError` leave the details in `client.last_api_error`.

const std = @import("std");

const client = @import("client.zig");
pub const models = @import("models.zig");
pub const validators = @import("validators.zig");
pub const webhooks = @import("webhooks.zig");

pub const Client = client.Client;
pub const Config = client.Config;
pub const Version = client.Version;
pub const ApiError = client.ApiError;
pub const Transport = client.Transport;
pub const Query = client.Query;
pub const default_base_url = client.default_base_url;
pub const escape = client.escape;
pub const isUuid = client.isUuid;

pub const Orders = @import("orders.zig").Orders;
pub const Organization = @import("organization.zig").Organization;
pub const Submerchants = @import("submerchants.zig").Submerchants;
pub const Vpos = @import("vpos.zig").Vpos;
pub const Subscriptions = @import("subscriptions.zig").Subscriptions;
pub const Cards = @import("cards.zig").Cards;
pub const Marketplace = @import("marketplace.zig").Marketplace;
pub const Elements = @import("elements.zig").Elements;

/// A decoded callback; verify it first with `webhooks.verify`.
pub const WebhookEvent = webhooks.Event;

// Request and response types, also available as `tapsilat.models.*`
pub const Order = models.Order;
pub const CreateOrderRequest = models.CreateOrderRequest;
pub const CreateOrderResponse = models.CreateOrderResponse;
pub const OrderResponse = models.OrderResponse;
pub const OrderDetail = models.OrderDetail;
pub const OrderBuyer = models.OrderBuyer;
pub const OrderBillingAddress = models.OrderBillingAddress;
pub const OrderShippingAddress = models.OrderShippingAddress;
pub const OrderBasketItem = models.OrderBasketItem;
pub const Currency = models.Currency;
pub const Locale = models.Locale;
pub const BillingType = models.BillingType;
pub const PaymentOption = models.PaymentOption;
pub const OrderStatusCode = models.OrderStatusCode;
pub const ElementsSessionCreateRequest = models.ElementsSessionCreateRequest;
pub const ElementsSession = models.ElementsSession;
pub const ElementsSessionWithSecret = models.ElementsSessionWithSecret;
pub const ElementsCardSummary = models.ElementsCardSummary;
pub const ElementsError = models.ElementsError;
pub const ElementsPurpose = models.ElementsPurpose;
pub const ElementsStatus = models.ElementsStatus;
pub const ElementsMode = models.ElementsMode;
pub const ElementsCardBrand = models.ElementsCardBrand;

test {
    // Analyze every public function, including those the tests do not call
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(Client);
    std.testing.refAllDecls(Query);
    std.testing.refAllDecls(ApiError);
    std.testing.refAllDecls(Orders);
    std.testing.refAllDecls(Organization);
    std.testing.refAllDecls(Submerchants);
    std.testing.refAllDecls(Vpos);
    std.testing.refAllDecls(Subscriptions);
    std.testing.refAllDecls(Cards);
    std.testing.refAllDecls(Marketplace);
    std.testing.refAllDecls(Elements);
    std.testing.refAllDecls(validators);
    std.testing.refAllDecls(webhooks);
    std.testing.refAllDecls(webhooks.Event);
    std.testing.refAllDecls(OrderStatusCode);
    std.testing.refAllDecls(models.OrderStatus);
    std.testing.refAllDecls(ElementsSession);
    std.testing.refAllDecls(ElementsSessionWithSecret);
    std.testing.refAllDecls(ElementsCardSummary);
    std.testing.refAllDecls(ElementsPurpose);
    std.testing.refAllDecls(ElementsStatus);
    std.testing.refAllDecls(ElementsMode);
    std.testing.refAllDecls(ElementsCardBrand);
    std.testing.refAllDecls(@import("transport.zig").HttpTransport);
    _ = @import("tests.zig");
}
