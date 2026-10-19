# tapsilat-zig

Zig client library for the [Tapsilat](https://tapsilat.com) payment API.

## Requirements

- Zig **0.17.0** or later

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

pub fn main(init: std.process.Init) !void {
    var client = tapsilat.Client.init(init.gpa, init.io, .{
        .api_key = "YOUR_API_KEY",
        // Optional; defaults to https://panel.tapsilat.dev/api/v1
        .base_url = "https://panel.tapsilat.dev/api/v1",
    });
    defer client.deinit();

    const response = client.createOrder(.{
        .amount = 5,
        .currency = "TRY",
        .locale = "tr",
        .conversation_id = "order-0001",
        .buyer = .{
            .name = "John",
            .surname = "Doe",
            .email = "john@example.com",
            .gsm_number = "+90 555 123 45 67", // cleaned to +905551234567
        },
        .basket_items = &.{.{ .id = "item-1", .name = "Product", .category1 = "General", .price = 5, .item_type = "PHYSICAL" }},
        .redirect_success_url = "https://shop.example/success",
    }) catch |err| {
        if (client.last_api_error) |api_error| {
            std.debug.print("{f}\n", .{api_error});
        } else {
            std.debug.print("error: {t}\n", .{err});
        }
        return;
    };
    defer response.deinit();

    std.debug.print("reference: {s}, checkout: {s}\n", .{
        response.value.reference_id orelse "-",
        response.value.checkout_url orelse "-",
    });
}
```

## Usage

`Client.init(allocator, io, config)` takes the allocator and `std.Io` used for requests. The client
is not thread safe.

Calls return `std.json.Parsed(T)`; call `deinit` on the result to free it. Optional request fields
left `null` are omitted from the request body, and every response field is optional because the
server omits empty values.

Services are reached through accessors on the client:

| Accessor | Covers |
|---|---|
| `client.orders()` | Orders, lists with filters, status, payments, transactions, charge, refunds, payment terms, callback and related-order updates |
| `client.cards()` | Card installments, the installment table and saved cards (tokenization) |
| `client.organization()` | Settings, currencies, currency presets, users, user tokens and sub-organizations |
| `client.submerchants()` | Submerchants, settlement approval, payment item updates and payout events |
| `client.vpos()` | Virtual POS, acquirers, card schemes, templates and VPOS submerchants |
| `client.subscriptions()` | Subscriptions |
| `client.marketplace()` | Marketplace sellers, payouts, payout operations and policies (API v2) |

```zig
const order = try client.orders().get("reference-id");
defer order.deinit();

const page = try client.orders().list(.{ .page = 1, .per_page = 50, .start_date = "2026-01-01", .status = 3 });
defer page.deinit();

const charged = try client.orders().charge(.{ .order_reference_id = "reference-id" });
defer charged.deinit();

const options = try client.cards().getInstallments(.{ .bin = "54066200", .amount = 1000, .currency = "TRY" });
defer options.deinit();

// Payment terms: order_id is the order's ID, not its reference ID; dates use YYYY-MM-DD
const term = try client.orders().createTerm(.{ .order_id = "order-id", .required = true, .amount = 50, .due_date = "2026-02-01" });
defer term.deinit();
```

Payment terms sent with an order need a `due_date`, and their dates are RFC3339 timestamps such
as `"2026-01-15T00:00:00Z"`.

A VPOS update replaces the whole configuration: read it with `client.vpos().get` and send every
field back.

### Marketplace (API v2)

Marketplace calls use the `/api/v2` URL derived from `base_url`. Seller and payout revisions are
opaque strings: send them back exactly as received.

```zig
const seller = try client.marketplace().getSubmerchant("seller-id");
defer seller.deinit();
const updated = try client.marketplace().updateSubmerchant("seller-id", .{ .name = "New name", .revision = seller.value.revision.? });
defer updated.deinit();

// The approval policy currency must be a UUID; a unit such as "TRY" is resolved for you
try client.marketplace().createApprovalPolicy(.{ .name = "Large orders", .min_amount = "1000", .currency_id = "TRY", .mode = "manual" });
```

Currency references are otherwise sent as given; the server resolves units. Use
`client.resolveCurrencyId(allocator, "TRY")` where a UUID is required.

### Errors

A call that gets an error status, or a response that is not JSON (such as an HTML page from a
wrong `base_url`), returns `error.ApiError` and leaves the details in `client.last_api_error`:
`status_code`, `status`, `code`, `message`, `errors_json` (per-field validation messages) and
`raw_body`. The client frees them on the next request or on `deinit`. Format the error with
`{f}` for the common message, for example
`API request failed with status 400 (Bad Request): [400000] INVALID_REQUEST_BODY`.

### Timeouts and redirects

`std.http.Client` has no request timeout in Zig 0.17; cancel the request through your `std.Io`
implementation if you need one. Redirects are refused so the API token is never sent to another
host.

### Testing

`Config.transport` replaces the HTTP transport, so tests can record requests and return canned
responses without a network; see `src/tests.zig`.

### Validators

```zig
const cleaned = try tapsilat.validators.validateGsmNumber(allocator, "+90 (555) 123-45-67"); // "+905551234567"
defer allocator.free(cleaned);
const installments = try tapsilat.validators.parseInstallments(allocator, "1,3,6"); // { 1, 3, 6 }
defer allocator.free(installments);
```

## Running the Example

```bash
TAPSILAT_API_KEY=your-key zig build example
```

Set `TAPSILAT_BASE_URL` to use another deployment.

## Running Tests

```bash
zig build test
```

## Project Structure

```
tapsilat-zig/
├── build.zig
├── build.zig.zon
├── src/
│   ├── tapsilat.zig       # Root module and re-exports
│   ├── client.zig         # Client, configuration, query and path helpers
│   ├── transport.zig      # HTTP transport (std.http.Client)
│   ├── errors.zig         # ApiError
│   ├── models.zig         # Request and response types
│   ├── orders.zig, cards.zig, organization.zig, submerchants.zig,
│   │   vpos.zig, subscriptions.zig, marketplace.zig
│   ├── validators.zig
│   └── tests.zig          # Contract tests with a fake transport
├── examples/
│   └── create_order.zig
└── README.md
```

## License

MIT
