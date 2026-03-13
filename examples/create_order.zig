const std = @import("std");
const tapsilat = @import("tapsilat");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize client with your API key
    var client = tapsilat.Client.init(allocator, .{
        .api_key = "YOUR_API_KEY_HERE",
    });
    defer client.deinit();

    // Build the order request
    const request = tapsilat.CreateOrderRequest{
        .amount = 5,
        .paid_amount = 0,
        .currency = .TRY,
        .locale = .tr,
        .conversation_id = "dummy-conversation-id-0001",
        .billing_address = .{
            .address = "Dummy Address Line 1",
            .billing_type = .PERSONAL,
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
            .gsm_number = "+900000000000",
            .identity_number = "DUMMY_ID_0001",
            .birth_date = "1990-01-01 00:00:00",
            .registration_address = "Dummy Registration Address",
            .city = "Dummy City",
            .country = "TR",
        },
        .basket_items = &.{
            .{
                .id = "dummy_item_id_0001",
                .name = "Dummy Product",
                .category1 = "Dummy Category",
                .category2 = "Dummy Subcategory",
                .price = 5,
                .coupon_discount = 0,
                .quantity = 1,
                .item_type = "DUMMY_ITEM_TYPE",
                .data = "DUMMY_DATA",
                .quantity_unit = "PCE",
            },
        },
        .payment_options = &.{
            .PAY_WITH_WALLET,
            .PAY_WITH_CARD,
            .PAY_WITH_LOAN,
            .PAY_WITH_CASH,
        },
    };

    // Create the order
    var response = client.createOrder(request) catch |err| {
        std.debug.print("Error creating order: {}\n", .{err});
        return;
    };
    defer response.deinit();

    if (response.isSuccess()) {
        std.debug.print("Order created successfully!\n", .{});
        std.debug.print("Response: {s}\n", .{response.body});

        // Parse the structured response
        if (response.json()) |parsed| {
            var p = parsed;
            defer p.deinit();
            if (p.value.data) |data| {
                if (data.payment_page_url) |url| {
                    std.debug.print("Payment URL: {s}\n", .{url});
                }
            }
        } else |_| {
            std.debug.print("Could not parse response JSON\n", .{});
        }
    } else {
        std.debug.print("Order creation failed (HTTP {d})\n", .{@intFromEnum(response.status)});
        std.debug.print("Response: {s}\n", .{response.body});
    }
}
