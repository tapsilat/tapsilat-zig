# tapsilat-zig

Zig client library for the [Tapsilat](https://tapsilat.com) payment API.

## Requirements

- Zig **0.15.2** or later

## Installation

Add `tapsilat-zig` as a dependency in your `build.zig.zon`:

```zig
.dependencies = .{
    .tapsilat = .{
        .url = "https://github.com/tapsilat/tapsilat-zig/archive/refs/heads/main.tar.gz",
        // Run `zig fetch` to get the hash:
        // zig fetch https://github.com/tapsilat/tapsilat-zig/archive/refs/heads/main.tar.gz
        .hash = "...",
    },
},
```

Then add the module import in your `build.zig`:

```zig
const tapsilat_dep = b.dependency("tapsilat", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("tapsilat", tapsilat_dep.module("tapsilat"));
```

## Quick Start

```zig
const std = @import("std");
const tapsilat = @import("tapsilat");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = tapsilat.Client.init(allocator, .{
        .api_key = "YOUR_API_KEY",
        // Optional: override for staging/self-hosted environments
        .base_url = "https://panel.tapsilat.dev/api/v1",
    });
    defer client.deinit();

    var response = try client.createOrder(.{
        .amount = 5,
        .currency = .TRY,
        .locale = .tr,
        .conversation_id = "dummy-conversation-id-0001",
        .billing_address = .{
            .address = "Dummy Address Line 1",
            .city = "Dummy City",
            .contact_name = "Dummy User",
            .contact_phone = "+900000000000",
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
        },
        .basket_items = &.{
            .{
                .id = "dummy_item_id_0001",
                .name = "Dummy Product",
                .category1 = "Dummy Category",
                .price = 5,
                .item_type = "DUMMY_ITEM_TYPE",
            },
        },
    });
    defer response.deinit();

    if (response.isSuccess()) {
        std.debug.print("Success: {s}\n", .{response.body});
    } else {
        std.debug.print("Error ({d}): {s}\n", .{ @intFromEnum(response.status), response.body });
    }
}
```

## API Reference

### `Client`

#### `Client.init(allocator, config) -> Client`

Create a new Tapsilat client.

| Config Field | Type | Default | Description |
|---|---|---|---|
| `api_key` | `[]const u8` | *required* | Your Tapsilat API bearer token |
| `base_url` | `[]const u8` | `https://panel.tapsilat.com/api/v1` | API base URL |

#### `client.createOrder(request) -> !ApiResponse`

Create a new payment order.

#### `client.deinit()`

Release HTTP client resources.

### `CreateOrderRequest`

| Field | Type | Default | Description |
|---|---|---|---|
| `amount` | `f64` | *required* | Total order amount |
| `paid_amount` | `f64` | `0` | Already paid amount |
| `currency` | `Currency` | `.TRY` | Currency code (`TRY`, `USD`, `EUR`, `GBP`) |
| `locale` | `Locale` | `.tr` | Locale (`tr`, `en`) |
| `payment_methods` | `bool` | `true` | Show payment method selection |
| `partial_payment` | `bool` | `false` | Allow partial payments |
| `three_d_force` | `bool` | `false` | Force 3D Secure |
| `billing_address` | `BillingAddress` | *required* | Billing address details |
| `buyer` | `Buyer` | *required* | Buyer information |
| `basket_items` | `[]const BasketItem` | *required* | Order line items |
| `conversation_id` | `[]const u8` | *required* | Unique conversation/order ID |
| `payment_options` | `[]const PaymentOption` | all options | Allowed payment methods |

### `ApiResponse`

| Method | Description |
|---|---|
| `isSuccess() -> bool` | Returns `true` for HTTP 2xx status codes |
| `json() -> !Parsed(CreateOrderResponse)` | Parse JSON response body into a typed struct |
| `deinit()` | Free the response body memory |

### Payment Options

- `PAY_WITH_WALLET`
- `PAY_WITH_CARD`
- `PAY_WITH_LOAN`
- `PAY_WITH_CASH`

## Running the Example

```bash
zig build example
```

## Running Tests

```bash
zig build test
```

## Project Structure

```
tapsilat-zig/
├── build.zig          # Build configuration
├── build.zig.zon      # Package manifest
├── src/
│   └── tapsilat.zig   # Library source
├── examples/
│   └── create_order.zig
└── README.md
```

## License

MIT
