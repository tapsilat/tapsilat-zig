const std = @import("std");
const tapsilat = @import("tapsilat");

pub fn main(init: std.process.Init) !void {
    // Set TAPSILAT_API_KEY, and TAPSILAT_BASE_URL to use another deployment
    const api_key = init.environ_map.get("TAPSILAT_API_KEY") orelse "YOUR_API_KEY_HERE";
    const base_url = init.environ_map.get("TAPSILAT_BASE_URL") orelse tapsilat.default_base_url;

    var client = tapsilat.Client.init(init.gpa, init.io, .{
        .api_key = api_key,
        .base_url = base_url,
    });
    defer client.deinit();

    const response = client.createOrder(.{
        .amount = 5,
        .currency = "TRY",
        .locale = "tr",
        .conversation_id = "dummy-conversation-id-0001",
        .billing_address = .{
            .address = "Dummy Address Line 1",
            .billing_type = "PERSONAL",
            .city = "Dummy City",
            .contact_name = "Dummy User",
            .contact_phone = "+900000000000",
            .country = "TR",
            .vat_number = "DUMMY_VAT_0001",
            .zip_code = "00000",
            .district = "Dummy District",
        },
        .buyer = .{
            .id = "dummy_customer_id_0001",
            .name = "Dummy",
            .surname = "User",
            .email = "dummy@example.com",
            .gsm_number = "+90 555 000 00 00",
            .identity_number = "DUMMY_ID_0001",
            .birth_date = "1990-01-01",
            .registration_address = "Dummy Registration Address",
            .city = "Dummy City",
            .country = "TR",
        },
        .basket_items = &.{.{
            .id = "dummy_item_id_0001",
            .name = "Dummy Product",
            .category1 = "Dummy Category",
            .category2 = "Dummy Subcategory",
            .price = 5,
            .quantity = 1,
            .item_type = "PHYSICAL",
        }},
        .payment_options = &.{ "PAY_WITH_WALLET", "PAY_WITH_CARD", "PAY_WITH_LOAN", "PAY_WITH_CASH" },
    }) catch |err| {
        if (client.last_api_error) |api_error| {
            std.debug.print("{f}\n", .{api_error});
        } else {
            std.debug.print("Error creating order: {t}\n", .{err});
        }
        return;
    };
    defer response.deinit();

    std.debug.print("Order created: {s}\n", .{response.value.reference_id orelse "-"});
    std.debug.print("Checkout URL: {s}\n", .{response.value.checkout_url orelse "-"});
}
