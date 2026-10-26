//! Request and response types. Optional fields left null are omitted from requests, and every
//! response field is optional because the server omits empty values.

const std = @import("std");

/// The order-create request. Required: `locale`, a non-zero `amount` and `currency`.
pub const Order = struct {
    locale: ?[]const u8 = null,
    amount: ?f64 = null,
    tax_amount: ?f64 = null,
    currency: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    buyer: ?OrderBuyer = null,
    shipping_address: ?OrderShippingAddress = null,
    billing_address: ?OrderBillingAddress = null,
    basket_items: ?[]const OrderBasketItem = null,
    payment_failure_url: ?[]const u8 = null,
    payment_success_url: ?[]const u8 = null,
    enabled_installments: ?[]const i64 = null,
    payment_options: ?[]const []const u8 = null,
    submerchants: ?[]const OrderSubmerchant = null,
    checkout_design: ?OrderCheckoutDesign = null,
    payment_methods: ?bool = null,
    redirect_success_url: ?[]const u8 = null,
    redirect_failure_url: ?[]const u8 = null,
    pf_sub_merchant: ?OrderPfSubMerchant = null,
    three_d_force: ?bool = null,
    metadata: ?[]const OrderMetadata = null,
    /// Each term needs a `dueDate`; term dates are RFC3339 timestamps such as "2026-01-15T00:00:00Z".
    payment_terms: ?[]const OrderPaymentTerm = null,
    paid_amount: ?f64 = null,
    external_reference_id: ?[]const u8 = null,
    partial_payment: ?bool = null,
    /// "auth" (default) or "preauth".
    payment_mode: ?[]const u8 = null,
    consents: ?[]const OrderConsent = null,
    order_cards: ?[]const OrderCard = null,
    sub_organization: ?OrderSubOrganization = null,
    order_vpos_id: ?[]const u8 = null,
};

pub const OrderBuyer = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    surname: ?[]const u8 = null,
    email: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    registration_date: ?[]const u8 = null,
    registration_address: ?[]const u8 = null,
    last_login_date: ?[]const u8 = null,
    city: ?[]const u8 = null,
    country: ?[]const u8 = null,
    zip_code: ?[]const u8 = null,
    ip: ?[]const u8 = null,
    /// Birth date in YYYY-MM-DD format.
    birth_date: ?[]const u8 = null,
    title: ?[]const u8 = null,
    income_type: ?[]const u8 = null,
    education: ?[]const u8 = null,
    occupation: ?[]const u8 = null,
};

pub const OrderShippingAddress = struct {
    address: ?[]const u8 = null,
    zip_code: ?[]const u8 = null,
    city: ?[]const u8 = null,
    country: ?[]const u8 = null,
    contact_name: ?[]const u8 = null,
    tracking_code: ?[]const u8 = null,
    shipping_date: ?[]const u8 = null,
};

pub const OrderBillingAddress = struct {
    address: ?[]const u8 = null,
    zip_code: ?[]const u8 = null,
    city: ?[]const u8 = null,
    country: ?[]const u8 = null,
    contact_name: ?[]const u8 = null,
    billing_type: ?[]const u8 = null,
    citizenship: ?[]const u8 = null,
    title: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    district: ?[]const u8 = null,
    contact_phone: ?[]const u8 = null,
    vat_number: ?[]const u8 = null,
    neighbourhood: ?[]const u8 = null,
    street1: ?[]const u8 = null,
    street2: ?[]const u8 = null,
    street3: ?[]const u8 = null,
};

pub const OrderBasketItem = struct {
    id: ?[]const u8 = null,
    price: ?f64 = null,
    name: ?[]const u8 = null,
    category1: ?[]const u8 = null,
    category2: ?[]const u8 = null,
    item_type: ?[]const u8 = null,
    quantity: ?i64 = null,
    quantity_float: ?f64 = null,
    quantity_unit: ?[]const u8 = null,
    data: ?[]const u8 = null,
    commission_amount: ?f64 = null,
    sub_merchant_key: ?[]const u8 = null,
    sub_merchant_price: ?[]const u8 = null,
    /// The earliest time the item's payout may be released (RFC3339).
    payout_release_at: ?[]const u8 = null,
    payer: ?OrderBasketItemPayer = null,
    /// The item's merchant category code.
    mcc: ?[]const u8 = null,
    coupon: ?[]const u8 = null,
    coupon_discount: ?f64 = null,
    paid_amount: ?f64 = null,
    /// Response only.
    status: ?i64 = null,
    /// Response only.
    refunded_amount: ?f64 = null,
    /// Response only.
    refundable_amount: ?f64 = null,
    /// Response only.
    paidable_amount: ?f64 = null,
    /// Response only.
    item_payments: ?[]const OrderItemPayment = null,
};

pub const OrderBasketItemPayer = struct {
    address: ?[]const u8 = null,
    reference_id: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    title: ?[]const u8 = null,
    type: ?[]const u8 = null,
    vat: ?[]const u8 = null,
    name: ?[]const u8 = null,
    surname: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    email: ?[]const u8 = null,
    phone: ?[]const u8 = null,
};

pub const OrderSubmerchant = struct {
    amount: ?f64 = null,
    order_basket_item_id: ?[]const u8 = null,
    merchant_reference_id: ?[]const u8 = null,
};

/// Customizes the checkout page branding for one order.
pub const OrderCheckoutDesign = struct {
    logo: ?[]const u8 = null,
    input_background_color: ?[]const u8 = null,
    pay_button_color: ?[]const u8 = null,
    input_text_color: ?[]const u8 = null,
    label_text_color: ?[]const u8 = null,
    left_background_color: ?[]const u8 = null,
    right_background_color: ?[]const u8 = null,
    text_color: ?[]const u8 = null,
    placeholder_color: ?[]const u8 = null,
    pay_button_text_color: ?[]const u8 = null,
    page_background_color: ?[]const u8 = null,
    border_color: ?[]const u8 = null,
    input_border_color: ?[]const u8 = null,
    accent_color: ?[]const u8 = null,
    text_muted_color: ?[]const u8 = null,
    surface_muted_color: ?[]const u8 = null,
    dark_mode_enabled: ?bool = null,
    /// Colors used in dark mode, keyed by the light-mode field's JSON name.
    dark_colors: ?std.json.ArrayHashMap([]const u8) = null,
    /// Deprecated: checkout no longer renders custom order detail HTML; the value is ignored.
    order_detail_html: ?[]const u8 = null,
    /// Deprecated: checkout design no longer carries a redirect URL; the value is ignored.
    /// Use the order's `redirectSuccessUrl` and `redirectFailureUrl`.
    redirect_url: ?[]const u8 = null,
};

pub const OrderPfSubMerchant = struct {
    address: ?[]const u8 = null,
    city: ?[]const u8 = null,
    country: ?[]const u8 = null,
    country_iso_code: ?[]const u8 = null,
    id: ?[]const u8 = null,
    mcc: ?[]const u8 = null,
    name: ?[]const u8 = null,
    org_id: ?[]const u8 = null,
    postal_code: ?[]const u8 = null,
    terminal_no: ?[]const u8 = null,
    submerchant_nin: ?[]const u8 = null,
    submerchant_url: ?[]const u8 = null,
    switch_id: ?[]const u8 = null,
    national_id: ?[]const u8 = null,
};

pub const OrderMetadata = struct {
    key: ?[]const u8 = null,
    value: ?[]const u8 = null,
};

/// A payment term sent with the order. `dueDate` is required and, like `paidDate`, must be an
/// RFC3339 timestamp such as "2026-01-15T00:00:00Z".
pub const OrderPaymentTerm = struct {
    amount: ?f64 = null,
    data: ?[]const u8 = null,
    due_date: ?[]const u8 = null,
    paid_date: ?[]const u8 = null,
    required: ?bool = null,
    status: ?[]const u8 = null,
    term_reference_id: ?[]const u8 = null,
    term_sequence: ?i64 = null,
};

/// A consent text the buyer must accept on the checkout page.
pub const OrderConsent = struct {
    title: ?[]const u8 = null,
    url: ?[]const u8 = null,
};

/// Selects a saved card for the order.
pub const OrderCard = struct {
    card_id: []const u8,
    card_sequence: ?i64 = null,
};

pub const OrderSubOrganization = struct {
    organization_name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    iban: ?[]const u8 = null,
    address: ?[]const u8 = null,
    currency: ?[]const u8 = null,
    acquirer: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    tax_number: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    contact_first_name: ?[]const u8 = null,
    contact_last_name: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    legal_company_title: ?[]const u8 = null,
    sub_merchant_key: ?[]const u8 = null,
    sub_merchant_type: ?[]const u8 = null,
    sub_merchant_external_id: ?[]const u8 = null,
};

pub const OrderResponse = struct {
    order_id: ?[]const u8 = null,
    reference_id: ?[]const u8 = null,
    checkout_url: ?[]const u8 = null,
    @"error": ?[]const u8 = null,
};

/// An order as returned by the order detail endpoints. Every field is optional because the
/// server omits empty values.
pub const OrderDetail = struct {
    locale: ?[]const u8 = null,
    @"error": ?[]const u8 = null,
    code: ?i64 = null,
    reference_id: ?[]const u8 = null,
    amount: ?[]const u8 = null,
    total: ?[]const u8 = null,
    paid_amount: ?[]const u8 = null,
    refunded_amount: ?[]const u8 = null,
    customer_paid_amount: ?f64 = null,
    created_at: ?[]const u8 = null,
    currency: ?[]const u8 = null,
    status: ?i64 = null,
    status_enum: ?[]const u8 = null,
    buyer: ?OrderBuyer = null,
    shipping_address: ?OrderShippingAddress = null,
    billing_address: ?OrderBillingAddress = null,
    checkout_design: ?OrderCheckoutDesign = null,
    basket_items: ?[]const OrderBasketItem = null,
    payment_terms: ?[]const OrderPaymentTermDetail = null,
    payment_requests: ?[]const OrderPaymentRequest = null,
    refund_cancel_requests: ?[]const OrderRefundCancelRequest = null,
    metadata: ?[]const OrderMetadata = null,
    payment_failure_url: ?[]const u8 = null,
    payment_success_url: ?[]const u8 = null,
    redirect_success_url: ?[]const u8 = null,
    redirect_failure_url: ?[]const u8 = null,
    checkout_url: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    external_reference_id: ?[]const u8 = null,
    payment_options: ?[]const []const u8 = null,
};

/// A payment term as returned in the order detail.
pub const OrderPaymentTermDetail = struct {
    id: ?[]const u8 = null,
    hash_id: ?[]const u8 = null,
    term_sequence: ?i64 = null,
    required: ?bool = null,
    due_date: ?[]const u8 = null,
    paid_date: ?[]const u8 = null,
    amount: ?f64 = null,
    term_reference_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
    payments: ?[]const OrderItemPayment = null,
    data: ?[]const u8 = null,
};

pub const OrderItemPayment = struct {
    id: ?[]const u8 = null,
    amount: ?f64 = null,
    paid_date: ?[]const u8 = null,
    masked_bin: ?[]const u8 = null,
    card_brand: ?[]const u8 = null,
    refunded_amount: ?f64 = null,
    refundable_amount: ?f64 = null,
    refunded_date: ?[]const u8 = null,
    refunded: ?bool = null,
    status: ?i64 = null,
    type: ?[]const u8 = null,
};

/// A payment attempt recorded on an order.
pub const OrderPaymentRequest = struct {
    id: ?[]const u8 = null,
    date: ?[]const u8 = null,
    payment_mode: ?[]const u8 = null,
    amount: ?[]const u8 = null,
    card_hash: ?[]const u8 = null,
    masked_card: ?[]const u8 = null,
    paid: ?bool = null,
    type: ?[]const u8 = null,
};

/// A refund or cancellation request recorded on an order.
pub const OrderRefundCancelRequest = struct {
    id: ?[]const u8 = null,
    amount: ?[]const u8 = null,
    status: ?i64 = null,
    reason: ?[]const u8 = null,
    type: ?i64 = null,
    term_id: ?[]const u8 = null,
    item_id: ?[]const u8 = null,
    created_at: ?[]const u8 = null,
};

/// The response of `Orders.getStatus`: `status` is a name such as "Waiting for payment".
pub const OrderStatus = struct {
    status: ?[]const u8 = null,
    @"error": ?[]const u8 = null,

    /// The status as an `OrderStatusCode`, or null when it is missing or unknown.
    pub fn code(self: OrderStatus) ?OrderStatusCode {
        return OrderStatusCode.parse(self.status orelse return null);
    }
};

/// The numeric order status that order details and callbacks carry, with the names
/// `Orders.getStatus` returns for them.
pub const OrderStatusCode = enum(u8) {
    received = 1,
    unpaid = 2,
    paid = 3,
    processing = 4,
    shipped = 5,
    on_hold = 6,
    waiting_for_payment = 7,
    cancelled = 8,
    completed = 9,
    refunded = 10,
    fraud = 11,
    rejected = 12,
    failure = 13,
    retrying = 14,
    partially_refunded = 15,
    sub_merchant_payment_approved = 16,
    sub_merchant_payment_disapproved = 17,
    sub_merchant_payment_errored = 18,
    still_has_unpaid_installments = 19,
    still_has_unpaid_terms = 20,
    expired = 21,
    still_has_unpaid_sub_merchant_payments = 22,
    partially_paid = 23,
    terminated = 24,
    card_tokenization = 25,
    pre_authorized = 26,
    disputed = 27,
    partially_disputed = 28,
    suspect = 29,

    /// Statuses of an order whose payment was captured.
    pub const paid_statuses = [_]OrderStatusCode{ .paid, .completed, .sub_merchant_payment_approved };
    /// Statuses of an order that will not be paid.
    pub const failed_statuses = [_]OrderStatusCode{ .cancelled, .fraud, .rejected, .failure, .expired, .terminated };
    /// Statuses of an order whose payment was refunded in full or in part.
    pub const refunded_statuses = [_]OrderStatusCode{ .refunded, .partially_refunded };

    pub fn code(self: OrderStatusCode) u8 {
        return @backingInt(self);
    }

    /// The name `Orders.getStatus` returns, such as "Paid".
    pub fn name(self: OrderStatusCode) []const u8 {
        return switch (self) {
            .received => "Received",
            .unpaid => "Unpaid",
            .paid => "Paid",
            .processing => "Processing",
            .shipped => "Shipped",
            .on_hold => "On hold",
            .waiting_for_payment => "Waiting for payment",
            .cancelled => "Cancelled",
            .completed => "Completed",
            .refunded => "Refunded",
            .fraud => "Fraud",
            .rejected => "Rejected",
            .failure => "Failure",
            .retrying => "Retrying",
            .partially_refunded => "Partially refunded",
            .sub_merchant_payment_approved => "Sub merchant payment approved",
            .sub_merchant_payment_disapproved => "Sub merchant payment disapproved",
            .sub_merchant_payment_errored => "Sub merchant payment errored",
            .still_has_unpaid_installments => "Still has unpaid installments",
            .still_has_unpaid_terms => "Still has unpaid terms",
            .expired => "Expired",
            .still_has_unpaid_sub_merchant_payments => "Still has unpaid sub merchant payments",
            .partially_paid => "Partially Paid",
            .terminated => "Terminated",
            .card_tokenization => "Card Tokenization",
            .pre_authorized => "Pre Authorized",
            .disputed => "Disputed",
            .partially_disputed => "Partially disputed",
            .suspect => "Suspect",
        };
    }

    /// The status with the given numeric code, or null when it is not a status.
    pub fn fromCode(value: i64) ?OrderStatusCode {
        return std.enums.fromInt(OrderStatusCode, value);
    }

    /// Reads a numeric code such as "3", as order_lite callbacks send it, or a status name such
    /// as "Paid" (case-insensitive). Returns null when the text is not a status.
    pub fn parse(text: []const u8) ?OrderStatusCode {
        const trimmed = std.mem.trim(u8, text, " \t\n\r\x00\x0b");
        if (trimmed.len > 0 and isDigits(trimmed)) {
            return fromCode(std.fmt.parseInt(i64, trimmed, 10) catch return null);
        }
        for (std.enums.values(OrderStatusCode)) |status| {
            if (std.ascii.eqlIgnoreCase(status.name(), trimmed)) return status;
        }
        return null;
    }

    /// Reads a decoded JSON status: a number such as 3 or 3.0, or text as `parse` accepts.
    pub fn fromJson(value: std.json.Value) ?OrderStatusCode {
        return switch (value) {
            .integer => |number| fromCode(number),
            .float => |number| if (@floor(number) == number and number >= 0 and number <= std.math.maxInt(u8))
                fromCode(@intFromFloat(number))
            else
                null,
            .string, .number_string => |text| parse(text),
            else => null,
        };
    }

    pub fn isPaid(self: OrderStatusCode) bool {
        return std.mem.findScalar(OrderStatusCode, &paid_statuses, self) != null;
    }

    pub fn isFailed(self: OrderStatusCode) bool {
        return std.mem.findScalar(OrderStatusCode, &failed_statuses, self) != null;
    }

    pub fn isRefunded(self: OrderStatusCode) bool {
        return std.mem.findScalar(OrderStatusCode, &refunded_statuses, self) != null;
    }

    fn isDigits(text: []const u8) bool {
        for (text) |c| {
            if (!std.ascii.isDigit(c)) return false;
        }
        return true;
    }
};

pub const RefundOrder = struct {
    reference_id: []const u8,
    amount: ?f64 = null,
    /// Limits the refund to one basket item.
    order_item_id: ?[]const u8 = null,
    /// Limits the refund to one item payment.
    order_item_payment_id: ?[]const u8 = null,
};

pub const CancelOrder = struct {
    reference_id: []const u8,
};

pub const RefundCancelOrderResponse = struct {
    status: ?[]const u8 = null,
    message: ?[]const u8 = null,
    is_success: ?bool = null,
    @"error": ?[]const u8 = null,
};

pub const PaginatedData = struct {
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
    rows: ?std.json.Value = null,
    @"error": ?[]const u8 = null,
};

/// Selects orders for `OrderService.getOrderList(filter:)`. The server allows at most 100 orders per page.
pub const OrderListFilter = struct {
    page: i64 = 1,
    per_page: i64 = 10,
    start_date: ?[]const u8 = null,
    end_date: ?[]const u8 = null,
    organization_id: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    related_reference_id: ?[]const u8 = null,
    buyer_id: ?[]const u8 = null,
    /// Numeric order status.
    status: ?i64 = null,
};

pub const OrderSubmerchantListItem = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    submerchant_type: ?[]const u8 = null,
    submerchant_key: ?[]const u8 = null,
    labels: ?[]const u8 = null,
    status: ?[]const u8 = null,
    acquirer: ?[]const u8 = null,
};

/// A page of order submerchants; the rows come in the `row` key.
pub const OrderSubmerchantListResponse = struct {
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
    row: ?[]const OrderSubmerchantListItem = null,
};

/// Selects the order whose payments to list; set at least one identifier.
pub const GetOrderPaymentsRequest = struct {
    order_id: ?[]const u8 = null,
    order_reference_id: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
};

pub const OrderPayment = struct {
    id: ?[]const u8 = null,
    date: ?[]const u8 = null,
    payment_mode: ?[]const u8 = null,
    amount: ?f64 = null,
    card_id: ?[]const u8 = null,
    masked_card: ?[]const u8 = null,
    card_holder_name: ?[]const u8 = null,
    card_type: ?[]const u8 = null,
    card_brand: ?[]const u8 = null,
    card_bank: ?[]const u8 = null,
    card_network: ?[]const u8 = null,
    paid: ?bool = null,
    type: ?[]const u8 = null,
    acquirer_response: ?[]const u8 = null,
    vpos_commission_amount: ?f64 = null,
    vpos_commission_rate: ?f64 = null,
    vpos_commission_fee_type: ?[]const u8 = null,
    organization_commission_amount: ?f64 = null,
    organization_commission_rate: ?f64 = null,
    organization_commission_fee_type: ?[]const u8 = null,
    total_amount: ?f64 = null,
    acquirer_commission_amount: ?f64 = null,
    acquirer_commission_rate: ?f64 = null,
    acquirer_commission_fee_type: ?[]const u8 = null,
    acquirer_name: ?[]const u8 = null,
    customer_paid_commission_amount: ?f64 = null,
    merchant_paid_commission_amount: ?f64 = null,
    merchant_net_amount: ?f64 = null,
};

pub const GetOrderPaymentsResponse = struct {
    payments: ?[]const OrderPayment = null,
    total_amount: ?f64 = null,
    total_customer_paid_commission_amount: ?f64 = null,
    total_merchant_paid_commission_amount: ?f64 = null,
    total_merchant_net_amount: ?f64 = null,
    order_amount: ?f64 = null,
};

/// Charges an order, for example with its saved card.
pub const OrderChargeRequest = struct {
    order_reference_id: []const u8,
    retry: ?bool = null,
};

/// The charge result. The server sends these keys in camelCase, unlike most responses.
pub const OrderChargeResponse = struct {
    isSuccess: ?bool = null,
    message: ?[]const u8 = null,
    statusCode: ?[]const u8 = null,
    errorCode: ?[]const u8 = null,
};

/// Adds a payment term to an existing order. Dates use the YYYY-MM-DD format.
pub const OrderTermCreateRequest = struct {
    /// The order's ID (`OrderResponse.orderId`), not its reference ID.
    order_id: []const u8,
    term_sequence: ?i64 = null,
    required: bool = false,
    amount: f64,
    due_date: []const u8,
    paid_date: ?[]const u8 = null,
    term_reference_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
    data: ?[]const u8 = null,
};

/// Replaces a payment term. The server stores every field as sent, so populate all of them.
/// Dates use the YYYY-MM-DD format.
pub const OrderTermUpdateRequest = struct {
    term_reference_id: []const u8,
    term_sequence: ?i64 = null,
    required: ?bool = null,
    amount: ?f64 = null,
    due_date: ?[]const u8 = null,
    paid_date: ?[]const u8 = null,
    status: ?[]const u8 = null,
};

/// Refunds a payment made against a payment term.
pub const OrderTermRefundRequest = struct {
    /// The order's reference ID.
    reference_id: []const u8,
    /// The payment term's ID (`OrderPaymentTermDetail.id`).
    term_id: []const u8,
    term_payment_id: ?[]const u8 = null,
    amount: f64,
};

pub const OrganizationSettings = struct {
    ttl: ?i64 = null,
    retry_count: ?i64 = null,
    allow_payment: ?bool = null,
    session_ttl: ?i64 = null,
    custom_checkout: ?bool = null,
    domain_address: ?[]const u8 = null,
    checkout_domain: ?[]const u8 = null,
    subscription_domain: ?[]const u8 = null,
    has_kyc_kyx_template: ?bool = null,
    has_kyb_kyx_template: ?bool = null,
    is_money_transfer_partner: ?bool = null,
};

pub const OrganizationCurrency = struct {
    id: ?[]const u8 = null,
    currency_unit: ?[]const u8 = null,
    code: ?[]const u8 = null,
    name: ?[]const u8 = null,
    symbol: ?[]const u8 = null,
};

pub const OrganizationCurrenciesResponse = struct {
    currencies: ?[]const OrganizationCurrency = null,
};

pub const OrganizationCurrencyPreset = struct {
    currency_code: ?[]const u8 = null,
    currency_unit: ?[]const u8 = null,
    name: ?[]const u8 = null,
    minor_unit: ?i64 = null,
};

/// The currencies the organization can add.
pub const OrganizationCurrencyPresetsResponse = struct {
    items: ?[]const OrganizationCurrencyPreset = null,
};

pub const CreateOrganizationCurrencyResponse = struct {
    code: ?i64 = null,
    message: ?[]const u8 = null,
    created: ?bool = null,
    currency: ?OrganizationCurrency = null,
};

pub const OrgCreateUserRequest = struct {
    email: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    phone: ?[]const u8 = null,
    first_name: ?[]const u8 = null,
    last_name: ?[]const u8 = null,
    reference_id: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    is_mail_verified: ?bool = null,
};

pub const OrgCreateUserResponse = struct {
    code: ?i64 = null,
    message: ?[]const u8 = null,
    user_id: ?[]const u8 = null,
};

pub const OrgUserTokenCreateRequest = struct {
    email: ?[]const u8 = null,
    /// Token lifetime in minutes.
    expire: ?i64 = null,
    invalidate_old_tokens: ?bool = null,
    user_id: ?[]const u8 = null,
};

pub const OrgUserTokenCreateResponse = struct {
    code: ?i64 = null,
    message: ?[]const u8 = null,
    token: ?[]const u8 = null,
    user_id: ?[]const u8 = null,
};

pub const SuborganizationListItem = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    address: ?[]const u8 = null,
    city: ?[]const u8 = null,
    country: ?[]const u8 = null,
    phone: ?[]const u8 = null,
    currency: ?[]const u8 = null,
    logo: ?[]const u8 = null,
};

pub const SuborganizationListResponse = struct {
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
    rows: ?[]const SuborganizationListItem = null,
};

pub const SuborganizationDetail = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    parent_id: ?[]const u8 = null,
    public_status: ?i64 = null,
    availability_status: ?i64 = null,
    created_at: ?[]const u8 = null,
    updated_at: ?[]const u8 = null,
};

pub const SubmerchantSuborganizationMapping = struct {
    submerchant_id: ?[]const u8 = null,
    suborganization_id: ?[]const u8 = null,
};

pub const SuborganizationSubmerchantMapping = struct {
    suborganization_id: ?[]const u8 = null,
    submerchant_id: ?[]const u8 = null,
};

pub const SubscriptionGetRequest = struct {
    reference_id: ?[]const u8 = null,
    external_reference_id: ?[]const u8 = null,
};

pub const SubscriptionCancelRequest = struct {
    reference_id: ?[]const u8 = null,
    external_reference_id: ?[]const u8 = null,
};

pub const SubscriptionBilling = struct {
    address: ?[]const u8 = null,
    city: ?[]const u8 = null,
    contact_name: ?[]const u8 = null,
    country: ?[]const u8 = null,
    vat_number: ?[]const u8 = null,
    zip_code: ?[]const u8 = null,
};

pub const SubscriptionUser = struct {
    address: ?[]const u8 = null,
    city: ?[]const u8 = null,
    country: ?[]const u8 = null,
    email: ?[]const u8 = null,
    first_name: ?[]const u8 = null,
    id: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    last_name: ?[]const u8 = null,
    phone: ?[]const u8 = null,
    zip_code: ?[]const u8 = null,
};

pub const SubscriptionCreateRequest = struct {
    amount: ?f64 = null,
    billing: ?SubscriptionBilling = null,
    card_id: ?[]const u8 = null,
    currency: ?[]const u8 = null,
    cycle: ?i64 = null,
    external_reference_id: ?[]const u8 = null,
    failure_url: ?[]const u8 = null,
    /// The billing interval, for example "month".
    interval: ?[]const u8 = null,
    /// The number of intervals between payments.
    interval_count: ?i64 = null,
    /// Deprecated: ignored by the server; the subscription start date sets the billing anchor.
    payment_date: ?i64 = null,
    /// Deprecated: the legacy day-count cadence. Use `interval` and `intervalCount`.
    period: ?i64 = null,
    success_url: ?[]const u8 = null,
    title: ?[]const u8 = null,
    user: ?SubscriptionUser = null,
    /// Deprecated: not part of the API; the server ignores it.
    plan_id: ?[]const u8 = null,
};

pub const SubscriptionRedirectRequest = struct {
    subscription_id: ?[]const u8 = null,
};

pub const SubscriptionOrder = struct {
    amount: ?[]const u8 = null,
    currency: ?[]const u8 = null,
    payment_date: ?[]const u8 = null,
    payment_url: ?[]const u8 = null,
    reference_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
};

pub const SubscriptionDetail = struct {
    amount: ?[]const u8 = null,
    cycle: ?i64 = null,
    cycles_completed: ?i64 = null,
    currency: ?[]const u8 = null,
    due_date: ?[]const u8 = null,
    external_reference_id: ?[]const u8 = null,
    interval: ?[]const u8 = null,
    interval_count: ?i64 = null,
    is_active: ?bool = null,
    orders: ?[]const SubscriptionOrder = null,
    payment_date: ?i64 = null,
    payment_status: ?[]const u8 = null,
    period: ?i64 = null,
    title: ?[]const u8 = null,
    /// Deprecated: not returned by the server.
    id: ?[]const u8 = null,
    /// Deprecated: not returned by the server; see `paymentStatus`.
    status: ?[]const u8 = null,
};

pub const SubscriptionListItem = struct {
    amount: ?[]const u8 = null,
    cycle: ?i64 = null,
    cycles_completed: ?i64 = null,
    currency: ?[]const u8 = null,
    external_reference_id: ?[]const u8 = null,
    interval: ?[]const u8 = null,
    interval_count: ?i64 = null,
    is_active: ?bool = null,
    next_payment_date: ?[]const u8 = null,
    payment_date: ?i64 = null,
    payment_status: ?[]const u8 = null,
    period: ?i64 = null,
    reference_id: ?[]const u8 = null,
    title: ?[]const u8 = null,
};

pub const SubscriptionCreateResponse = struct {
    code: ?i64 = null,
    message: ?[]const u8 = null,
    order_reference_id: ?[]const u8 = null,
    reference_id: ?[]const u8 = null,
    /// Deprecated: not returned by the server.
    checkout_url: ?[]const u8 = null,
};

pub const SubscriptionRedirectResponse = struct {
    url: ?[]const u8 = null,
    /// Deprecated: not returned by the server; see `url`.
    checkout_url: ?[]const u8 = null,
};

/// Selects installment options for a card BIN.
pub const CardInstallmentsRequest = struct {
    /// The card's first digits (at least 8).
    bin: []const u8,
    amount: f64,
    /// A currency unit or name, for example "TRY".
    currency: []const u8 = "TRY",
    is_three_d: bool = false,
};

pub const CardInstallment = struct {
    installment: ?i64 = null,
    amount: ?[]const u8 = null,
    total_amount: ?[]const u8 = null,
    commission_rate: ?f64 = null,
    monthly_payment: ?[]const u8 = null,
};

pub const CardInstallmentsResponse = struct {
    is_installment_available: ?bool = null,
    installments: ?[]const CardInstallment = null,
};

/// Selects the installment table for an amount.
pub const InstallmentTableRequest = struct {
    amount: f64,
    /// A currency unit or name, for example "TRY".
    currency: []const u8 = "TRY",
    is_three_d: bool = false,
};

pub const InstallmentTableRow = struct {
    installment: ?i64 = null,
    installment_amount: ?[]const u8 = null,
    total_amount: ?[]const u8 = null,
    commission_rate: ?f64 = null,
    is_interest_free: ?bool = null,
};

pub const InstallmentTableGroup = struct {
    bank: ?[]const u8 = null,
    program: ?[]const u8 = null,
    program_code: ?[]const u8 = null,
    rows: ?[]const InstallmentTableRow = null,
};

pub const InstallmentTableResponse = struct {
    groups: ?[]const InstallmentTableGroup = null,
};

/// Creates a submerchant. Required: `email`, `name`, `locale`, `conversationId` and `gsmNumber`.
pub const SubmerchantCreateRequest = struct {
    locale: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    name: []const u8 = "",
    email: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    address: ?[]const u8 = null,
    iban: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    legal_company_title: ?[]const u8 = null,
    /// A currency UUID or unit such as "TRY".
    currency_id: []const u8 = "",
    sub_merchant_external_id: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    /// PERSONAL (requires `identityNumber`), PRIVATE_COMPANY or LIMITED_OR_JOINT_STOCK_COMPANY
    /// (both require `taxNumber`).
    sub_merchant_type: ?[]const u8 = null,
    tax_number: ?[]const u8 = null,
    sub_merchant_key: ?[]const u8 = null,
    organization_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
    system_time: ?i64 = null,
    contact_name: ?[]const u8 = null,
    contact_surname: ?[]const u8 = null,
};

/// Replaces a submerchant; every field is stored as sent.
pub const SubmerchantUpdateRequest = struct {
    locale: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    address: ?[]const u8 = null,
    iban: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    legal_company_title: ?[]const u8 = null,
    currency_id: ?[]const u8 = null,
    sub_merchant_external_id: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    sub_merchant_type: ?[]const u8 = null,
    tax_number: ?[]const u8 = null,
    sub_merchant_key: ?[]const u8 = null,
    organization_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
    system_time: ?i64 = null,
    contact_name: ?[]const u8 = null,
    contact_surname: ?[]const u8 = null,
};

pub const Submerchant = struct {
    id: ?[]const u8 = null,
    locale: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    address: ?[]const u8 = null,
    iban: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    legal_company_title: ?[]const u8 = null,
    currency_id: ?[]const u8 = null,
    sub_merchant_external_id: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    sub_merchant_type: ?[]const u8 = null,
    tax_number: ?[]const u8 = null,
    sub_merchant_key: ?[]const u8 = null,
    organization_id: ?[]const u8 = null,
    labels: ?[]const u8 = null,
    status: ?[]const u8 = null,
    system_time: ?i64 = null,
    acquirer: ?[]const u8 = null,
    contact_name: ?[]const u8 = null,
    contact_surname: ?[]const u8 = null,
};

pub const SubmerchantListItem = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    submerchant_type: ?[]const u8 = null,
    submerchant_key: ?[]const u8 = null,
    labels: ?[]const u8 = null,
    status: ?[]const u8 = null,
    acquirer: ?[]const u8 = null,
};

/// A page of submerchants; the rows come in the `row` key.
pub const SubmerchantListResponse = struct {
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
    row: ?[]const SubmerchantListItem = null,
};

/// Returned by submerchant create, update and delete. Read the submerchant for its key and status.
pub const SubmerchantMutationResponse = struct {
    code: ?i64 = null,
    message: ?[]const u8 = null,
};

/// Records an item business event for marketplace payouts.
pub const SubmerchantPayoutEventRequest = struct {
    idempotency_key: []const u8,
    order_reference: []const u8,
    item_id: []const u8,
    event_type: []const u8,
    /// RFC3339 timestamp; the server uses the current time when it is omitted.
    occurred_at: ?[]const u8 = null,
    payload: ?std.json.Value = null,
};

pub const SubmerchantPayoutEventResponse = struct {
    id: ?[]const u8 = null,
    idempotency_key: ?[]const u8 = null,
    order_reference: ?[]const u8 = null,
    item_id: ?[]const u8 = null,
    event_type: ?[]const u8 = null,
    occurred_at: ?[]const u8 = null,
    payload: ?std.json.Value = null,
};

/// Requests settlement approval or disapproval for an item payment.
pub const SubmerchantPaymentAction = struct {
    locale: []const u8,
    conversation_id: []const u8,
    payment_transaction_id: []const u8,
    acquirer: []const u8,
};

pub const SubmerchantPaymentActionResponse = struct {
    operation_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
    locale: ?[]const u8 = null,
    system_time: ?i64 = null,
    conversation_id: ?[]const u8 = null,
    payment_transaction_id: ?[]const u8 = null,
    acquirer: ?[]const u8 = null,
};

/// Changes the seller or payout of a completed marketplace item.
pub const SubmerchantPaymentItemUpdate = struct {
    locale: []const u8,
    conversation_id: []const u8,
    payment_transaction_id: []const u8,
    sub_merchant_key: []const u8,
    /// A decimal string greater than zero.
    sub_merchant_price: []const u8,
    acquirer: []const u8,
};

pub const SubmerchantPaymentItemUpdateResponse = struct {
    operation_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
    locale: ?[]const u8 = null,
    system_time: ?i64 = null,
    conversation_id: ?[]const u8 = null,
    payment_transaction_id: ?[]const u8 = null,
};

/// Creates a VPOS, or replaces one on update. An update stores fields left unset as empty or false
/// (for example `failover` and `tls`), so read the VPOS first and send every field back.
pub const VposCreateRequest = struct {
    name: ?[]const u8 = null,
    bank_name: ?[]const u8 = null,
    env_mode: ?[]const u8 = null,
    merchant: ?[]const u8 = null,
    merchant_code: ?[]const u8 = null,
    merchant_key: ?[]const u8 = null,
    auth_key: ?[]const u8 = null,
    terminal: ?[]const u8 = null,
    company: ?[]const u8 = null,
    username: ?[]const u8 = null,
    password: ?[]const u8 = null,
    store_key: ?[]const u8 = null,
    api_key: ?[]const u8 = null,
    api_secret: ?[]const u8 = null,
    guid: ?[]const u8 = null,
    pid: ?[]const u8 = null,
    client_id: ?[]const u8 = null,
    client_code: ?[]const u8 = null,
    type: ?[]const u8 = null,
    block_date: ?i64 = null,
    priority: ?i64 = null,
    main: ?bool = null,
    force_three_d: ?bool = null,
    marketplace: ?bool = null,
    pf: ?bool = null,
    payment_mode: ?[]const u8 = null,
    prefix: ?[]const u8 = null,
    acquirer_id: ?[]const u8 = null,
    card_schemes: ?[]const []const u8 = null,
    /// Currency UUIDs or units such as "TRY".
    currencies: ?[]const []const u8 = null,
    failover: ?bool = null,
    pf_id: ?[]const u8 = null,
    redirect_uri: ?[]const u8 = null,
    tls: ?bool = null,
    tls_key: ?[]const u8 = null,
    tls_cert: ?[]const u8 = null,
    root_ca: ?[]const u8 = null,
    main_installment: ?bool = null,
    main_without_installment: ?bool = null,
};

/// Replaces a VPOS configuration; see `VposCreateRequest`.
pub const VposUpdateRequest = VposCreateRequest;

pub const Vpos = struct {
    id: ?[]const u8 = null,
    provider: ?[]const u8 = null,
    name: ?[]const u8 = null,
    bank_name: ?[]const u8 = null,
    env_mode: ?[]const u8 = null,
    merchant: ?[]const u8 = null,
    merchant_code: ?[]const u8 = null,
    merchant_key: ?[]const u8 = null,
    auth_key: ?[]const u8 = null,
    terminal: ?[]const u8 = null,
    company: ?[]const u8 = null,
    username: ?[]const u8 = null,
    password: ?[]const u8 = null,
    store_key: ?[]const u8 = null,
    api_key: ?[]const u8 = null,
    api_secret: ?[]const u8 = null,
    guid: ?[]const u8 = null,
    pid: ?[]const u8 = null,
    client_id: ?[]const u8 = null,
    client_code: ?[]const u8 = null,
    type: ?[]const u8 = null,
    block_date: ?i64 = null,
    priority: ?i64 = null,
    main: ?bool = null,
    force_three_d: ?bool = null,
    marketplace: ?bool = null,
    pf: ?bool = null,
    payment_mode: ?[]const u8 = null,
    prefix: ?[]const u8 = null,
    acquirer_id: ?[]const u8 = null,
    card_schemes: ?[]const []const u8 = null,
    currencies: ?[]const []const u8 = null,
    failover: ?bool = null,
    pf_id: ?[]const u8 = null,
    redirect_uri: ?[]const u8 = null,
    tls: ?bool = null,
    tls_key: ?[]const u8 = null,
    tls_cert: ?[]const u8 = null,
    root_ca: ?[]const u8 = null,
    main_installment: ?bool = null,
    main_without_installment: ?bool = null,
};

pub const VposListFilter = struct {
    suborganization_id: ?[]const u8 = null,
};

pub const VposListResponse = struct {
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
    rows: ?[]const Vpos = null,
};

pub const VposMutationResponse = struct {
    code: ?i64 = null,
    message: ?[]const u8 = null,
};

pub const VposAcquirer = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    prefix: ?[]const u8 = null,
};

pub const VposAcquirerListResponse = struct {
    items: ?[]const VposAcquirer = null,
};

pub const CardScheme = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
};

pub const CardSchemeListResponse = struct {
    items: ?[]const CardScheme = null,
};

pub const VposAcquirerTemplateDefaults = struct {
    payment_mode: ?[]const u8 = null,
    main: ?bool = null,
    marketplace: ?bool = null,
    force_three_d: ?bool = null,
    credentials: ?std.json.ArrayHashMap([]const u8) = null,
};

pub const VposAcquirerTemplate = struct {
    acquirer_id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    prefix: ?[]const u8 = null,
    required_fields: ?[]const []const u8 = null,
    optional_fields: ?[]const []const u8 = null,
    defaults: ?VposAcquirerTemplateDefaults = null,
};

pub const VposAcquirerTemplateListResponse = struct {
    items: ?[]const VposAcquirerTemplate = null,
};

pub const VposSubmerchantCreateRequest = struct {
    external_reference_id: ?[]const u8 = null,
    submerchant_id: ?[]const u8 = null,
    terminal_no: ?[]const u8 = null,
    vpos_id: ?[]const u8 = null,
    mcc: ?[]const u8 = null,
    tax_id: ?[]const u8 = null,
    national_id: ?[]const u8 = null,
    title: ?[]const u8 = null,
    switch_id: ?[]const u8 = null,
    city: ?[]const u8 = null,
    country: ?[]const u8 = null,
    country_isocode: ?[]const u8 = null,
    postal_code: ?[]const u8 = null,
    address: ?[]const u8 = null,
    submerchant_url: ?[]const u8 = null,
    submerchant_nin: ?[]const u8 = null,
};

pub const VposSubmerchantUpdateRequest = struct {
    external_reference_id: ?[]const u8 = null,
    submerchant_id: ?[]const u8 = null,
    terminal_no: ?[]const u8 = null,
    mcc: ?[]const u8 = null,
    tax_id: ?[]const u8 = null,
    national_id: ?[]const u8 = null,
    title: ?[]const u8 = null,
    switch_id: ?[]const u8 = null,
};

pub const VposSubmerchant = struct {
    id: ?[]const u8 = null,
    external_reference_id: ?[]const u8 = null,
    submerchant_id: ?[]const u8 = null,
    terminal_no: ?[]const u8 = null,
    vpos_id: ?[]const u8 = null,
    mcc: ?[]const u8 = null,
    tax_id: ?[]const u8 = null,
    national_id: ?[]const u8 = null,
    title: ?[]const u8 = null,
    switch_id: ?[]const u8 = null,
};

pub const VposSubmerchantListItem = struct {
    id: ?[]const u8 = null,
    external_reference_id: ?[]const u8 = null,
    submerchant_id: ?[]const u8 = null,
    terminal_no: ?[]const u8 = null,
    vpos_id: ?[]const u8 = null,
};

pub const VposSubmerchantListResponse = struct {
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
    rows: ?[]const VposSubmerchantListItem = null,
};

pub const CardTokenizeRequest = struct {
    card_number: []const u8,
    holder_name: []const u8,
    expiry_month: []const u8,
    expiry_year: []const u8,
    cvv: []const u8,
    name: ?[]const u8 = null,
    default: ?bool = null,
    mode: ?i64 = null,
    user_id: ?[]const u8 = null,
    user_email: ?[]const u8 = null,
    redirect_success_url: ?[]const u8 = null,
    redirect_failure_url: ?[]const u8 = null,
};

/// The tokenization result, with 3D secure form details when required.
pub const CardTokenizeResponse = struct {
    threedform_url: ?[]const u8 = null,
    threedform_html: ?[]const u8 = null,
    is_success: ?bool = null,
    message: ?[]const u8 = null,
    status_code: ?[]const u8 = null,
    error_code: ?[]const u8 = null,
    order_reference_id: ?[]const u8 = null,
    card_id: ?[]const u8 = null,
};

pub const SavedCard = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    holder_name: ?[]const u8 = null,
    masked_number: ?[]const u8 = null,
    last_four: ?[]const u8 = null,
    brand: ?[]const u8 = null,
    bin: ?[]const u8 = null,
    is_default: ?bool = null,
};

pub const ListSavedCardsResponse = struct {
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
    rows: ?[]const SavedCard = null,
};

pub const DeleteSavedCardResponse = struct {
    success: ?bool = null,
    message: ?[]const u8 = null,
};

pub const MarketplaceAccountTarget = struct {
    vpos_id: []const u8,
    environment: []const u8,
};

/// Creates a marketplace seller. Without `vposId` or `providerAccounts` only the seller is created.
pub const MarketplaceSubmerchantCreateRequest = struct {
    /// Explicitly selects accounts in one environment; an empty list creates only the seller.
    /// It cannot be combined with `vposId`.
    provider_accounts: ?[]const MarketplaceAccountTarget = null,
    locale: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    address: ?[]const u8 = null,
    iban: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    legal_company_title: ?[]const u8 = null,
    /// A currency UUID or unit such as "TRY".
    currency_id: ?[]const u8 = null,
    sub_merchant_external_id: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    sub_merchant_type: ?[]const u8 = null,
    tax_number: ?[]const u8 = null,
    labels: ?[]const []const u8 = null,
    status: ?[]const u8 = null,
    system_time: ?i64 = null,
    contact_name: ?[]const u8 = null,
    contact_surname: ?[]const u8 = null,
    approval_mode: ?[]const u8 = null,
    release_policy_id: ?[]const u8 = null,
    idempotency_key: ?[]const u8 = null,
    /// Targets only this account, using its configured environment.
    vpos_id: ?[]const u8 = null,
};

pub const MarketplaceSubmerchantProvisioning = struct {
    vpos_id: ?[]const u8 = null,
    vpos_submerchant_id: ?[]const u8 = null,
    provider: ?[]const u8 = null,
    status: ?[]const u8 = null,
    provider_submerchant_key: ?[]const u8 = null,
    retryable: ?bool = null,
    error_message: ?[]const u8 = null,
};

/// The created seller; inspect `provisionings` for each VPOS account's readiness.
pub const MarketplaceSubmerchantCreateResponse = struct {
    id: ?[]const u8 = null,
    suborganization_id: ?[]const u8 = null,
    vpos_submerchant_id: ?[]const u8 = null,
    routing_reference: ?[]const u8 = null,
    provisionings: ?[]const MarketplaceSubmerchantProvisioning = null,
};

pub const MarketplaceSeller = struct {
    id: ?[]const u8 = null,
    routing_reference: ?[]const u8 = null,
    /// Opaque revision; send it back unchanged when updating the seller.
    revision: ?[]const u8 = null,
    name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    address: ?[]const u8 = null,
    iban: ?[]const u8 = null,
    currency_id: ?[]const u8 = null,
    sub_merchant_type: ?[]const u8 = null,
    sub_merchant_external_id: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    tax_number: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    legal_company_title: ?[]const u8 = null,
    contact_name: ?[]const u8 = null,
    contact_surname: ?[]const u8 = null,
    locale: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    status: ?[]const u8 = null,
    labels: ?[]const []const u8 = null,
    approval_mode: ?[]const u8 = null,
    release_policy_id: ?[]const u8 = null,
};

pub const MarketplaceSellerList = struct {
    rows: ?[]const MarketplaceSeller = null,
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
};

/// Replaces the saved seller profile at `revision`.
pub const MarketplaceProfileUpdate = struct {
    locale: ?[]const u8 = null,
    conversation_id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    email: ?[]const u8 = null,
    gsm_number: ?[]const u8 = null,
    address: ?[]const u8 = null,
    iban: ?[]const u8 = null,
    tax_office: ?[]const u8 = null,
    legal_company_title: ?[]const u8 = null,
    /// A currency UUID or unit such as "TRY".
    currency_id: ?[]const u8 = null,
    sub_merchant_external_id: ?[]const u8 = null,
    identity_number: ?[]const u8 = null,
    sub_merchant_type: ?[]const u8 = null,
    tax_number: ?[]const u8 = null,
    labels: ?[]const []const u8 = null,
    status: ?[]const u8 = null,
    system_time: ?i64 = null,
    contact_name: ?[]const u8 = null,
    contact_surname: ?[]const u8 = null,
    approval_mode: ?[]const u8 = null,
    release_policy_id: ?[]const u8 = null,
    idempotency_key: ?[]const u8 = null,
    /// The seller's revision, exactly as received.
    revision: []const u8,
};

pub const MarketplaceProfileUpdateResponse = struct {
    approval_required: ?bool = null,
};

pub const MarketplaceSellerContract = struct {
    supported: ?bool = null,
    remote: ?bool = null,
    fields: ?std.json.ArrayHashMap(bool) = null,
    immutable_fields: ?[]const []const u8 = null,
    currencies: ?[]const []const u8 = null,
};

pub const MarketplaceContracts = struct {
    contracts: ?std.json.ArrayHashMap(MarketplaceSellerContract) = null,
};

pub const MarketplaceContractFilter = struct {
    /// A currency UUID or unit such as "TRY".
    currency_id: []const u8,
    seller_type: []const u8,
    operation: []const u8 = "create",
    vpos_ids: ?[]const []const u8 = null,
};

pub const MarketplaceSynchronization = struct {
    status: ?[]const u8 = null,
    operation: ?[]const u8 = null,
    error_message: ?[]const u8 = null,
    needs_update: ?bool = null,
    attempts: ?i64 = null,
    verified_at: ?[]const u8 = null,
    missing_fields: ?[]const []const u8 = null,
};

pub const MarketplaceSellerAccount = struct {
    vpos_id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    provider: ?[]const u8 = null,
    environment: ?[]const u8 = null,
    eligible: ?bool = null,
    mapped: ?bool = null,
    status: ?[]const u8 = null,
    attempts: ?i64 = null,
    updated_at: ?[]const u8 = null,
    error_message: ?[]const u8 = null,
    retryable: ?bool = null,
    revision: ?[]const u8 = null,
    seller_revision: ?[]const u8 = null,
    account_revision: ?[]const u8 = null,
    actions: ?[]const []const u8 = null,
    contracts: ?std.json.ArrayHashMap(MarketplaceSellerContract) = null,
    contract_error: ?[]const u8 = null,
    sync: ?MarketplaceSynchronization = null,
    registration_profile_changed: ?bool = null,
    registration_missing_fields: ?[]const []const u8 = null,
    provider_submerchant_key: ?[]const u8 = null,
};

pub const MarketplaceSellerAccounts = struct {
    rows: ?[]const MarketplaceSellerAccount = null,
};

/// Confirms a listed account action using the account's latest revision and environment.
/// Retry reuses the original snapshot; resubmit registers the current saved profile.
pub const MarketplaceAccountAction = struct {
    action: []const u8,
    environment: []const u8,
    revision: []const u8,
};

pub const MarketplacePayout = struct {
    /// Opaque revision; send it back unchanged in payout operations.
    revision: ?[]const u8 = null,
    active_operation_id: ?[]const u8 = null,
    id: ?[]const u8 = null,
    provider: ?[]const u8 = null,
    organization_id: ?[]const u8 = null,
    submerchant_id: ?[]const u8 = null,
    submerchant_name: ?[]const u8 = null,
    order_id: ?[]const u8 = null,
    order_reference_id: ?[]const u8 = null,
    order_display: ?[]const u8 = null,
    amount: ?[]const u8 = null,
    currency: ?[]const u8 = null,
    approval_mode: ?[]const u8 = null,
    approval_rule_id: ?[]const u8 = null,
    approval_rule_name: ?[]const u8 = null,
    release_policy_id: ?[]const u8 = null,
    release_policy_name: ?[]const u8 = null,
    eligibility_status: ?[]const u8 = null,
    required_event: ?[]const u8 = null,
    item_id: ?[]const u8 = null,
    business_eligible_at: ?[]const u8 = null,
    eligible_at: ?[]const u8 = null,
    release_status: ?[]const u8 = null,
    status: ?[]const u8 = null,
    provider_reference: ?[]const u8 = null,
    attempts: ?i64 = null,
    released_at: ?[]const u8 = null,
    created_at: ?[]const u8 = null,
    error_message: ?[]const u8 = null,
};

pub const MarketplacePayoutFilter = struct {
    order_id: ?[]const u8 = null,
    submerchant_id: ?[]const u8 = null,
    vpos_id: ?[]const u8 = null,
    provider: ?[]const u8 = null,
    status: ?[]const u8 = null,
    release_status: ?[]const u8 = null,
    approval_mode: ?[]const u8 = null,
    /// A currency unit such as "TRY".
    currency: ?[]const u8 = null,
    eligibility: ?[]const u8 = null,
    search: ?[]const u8 = null,
    min_amount: ?[]const u8 = null,
    max_amount: ?[]const u8 = null,
    /// YYYY-MM-DD.
    start_date: ?[]const u8 = null,
    /// YYYY-MM-DD.
    end_date: ?[]const u8 = null,
    page: i64 = 1,
    per_page: i64 = 20,
};

pub const MarketplacePayoutList = struct {
    rows: ?[]const MarketplacePayout = null,
    page: ?i64 = null,
    per_page: ?i64 = null,
    total: ?i64 = null,
    total_pages: ?i64 = null,
};

pub const MarketplacePayoutApproval = struct {
    ids: []const []const u8,
};

/// Acknowledges local approval; payout completion is reported by the payout status.
pub const MarketplacePayoutAcceptance = struct {
    status: ?[]const u8 = null,
};

/// Changes a payout's allocation or withdraws its approval.
pub const MarketplacePayoutOperationInput = struct {
    kind: []const u8,
    idempotency_key: []const u8,
    /// The payout's revision, exactly as received.
    revision: []const u8,
    seller_reference: ?[]const u8 = null,
    net_amount: ?[]const u8 = null,
};

pub const MarketplacePayoutOperation = struct {
    id: ?[]const u8 = null,
    payout_id: ?[]const u8 = null,
    kind: ?[]const u8 = null,
    status: ?[]const u8 = null,
    attempts: ?i64 = null,
    error_message: ?[]const u8 = null,
    created_at: ?[]const u8 = null,
    updated_at: ?[]const u8 = null,
};

pub const MarketplaceApprovalPolicy = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    priority: ?i64 = null,
    enabled: ?bool = null,
    provider: ?[]const u8 = null,
    min_amount: ?[]const u8 = null,
    max_amount: ?[]const u8 = null,
    currency_id: ?[]const u8 = null,
    submerchant_ids: ?[]const []const u8 = null,
    labels_any: ?[]const []const u8 = null,
    mode: ?[]const u8 = null,
};

pub const MarketplaceApprovalPolicies = struct {
    rows: ?[]const MarketplaceApprovalPolicy = null,
};

/// Creates or replaces an approval rule.
pub const MarketplaceApprovalPolicyInput = struct {
    name: []const u8,
    priority: i64 = 0,
    enabled: ?bool = null,
    provider: []const u8 = "",
    min_amount: ?[]const u8 = null,
    max_amount: ?[]const u8 = null,
    /// A currency UUID or unit such as "TRY"; the SDK resolves a unit to its UUID.
    currency_id: []const u8 = "",
    submerchant_ids: ?[]const []const u8 = null,
    labels_any: ?[]const []const u8 = null,
    mode: []const u8,
};

pub const MarketplaceReleasePolicy = struct {
    id: ?[]const u8 = null,
    name: ?[]const u8 = null,
    enabled: ?bool = null,
    default: ?bool = null,
    minimum_delay_seconds: ?i64 = null,
    explicit_not_before: ?[]const u8 = null,
    required_external_event: ?[]const u8 = null,
};

pub const MarketplaceReleasePolicies = struct {
    rows: ?[]const MarketplaceReleasePolicy = null,
};

pub const MarketplaceReleasePolicyInput = struct {
    name: []const u8,
    enabled: bool = true,
    default: bool = false,
    minimum_delay_seconds: i64 = 0,
    explicit_not_before: []const u8 = "",
    required_external_event: []const u8 = "",
};

pub const MarketplaceApprovalSettings = struct {
    default_mode: ?[]const u8 = null,
};

/// The request of `Elements.createSession`. Required: `purpose`, and `order_reference_id` for a
/// "pay" session.
pub const ElementsSessionCreateRequest = struct {
    /// "tokenize" or "pay", such as `@tagName(ElementsPurpose.pay)`.
    purpose: []const u8,
    /// The order the session pays; required for "pay".
    order_reference_id: ?[]const u8 = null,
    /// The card owner of a "tokenize" session, scoped to your organization.
    user_id: ?[]const u8 = null,
    user_email: ?[]const u8 = null,
    /// The tokenize mode, such as `ElementsMode.secure.code()`: 1 = 3D Secure, 2 = half secure,
    /// 3 = non-secure.
    mode: ?i64 = null,
    /// "pay": lets the buyer save the card.
    save_card: ?bool = null,
};

/// The state of an Elements session, as `Elements.getSession` and `Elements.cancelSession` return
/// it. Timestamps are RFC 3339 text, such as "2026-10-22T09:30:00Z".
pub const ElementsSession = struct {
    id: ?[]const u8 = null,
    /// "tokenize" or "pay"; see `knownPurpose`.
    purpose: ?[]const u8 = null,
    /// Such as "requires_payment_method" or "succeeded"; see `knownStatus`.
    status: ?[]const u8 = null,
    order_reference_id: ?[]const u8 = null,
    user_id: ?[]const u8 = null,
    attempts: ?i64 = null,
    max_attempts: ?i64 = null,
    created_at: ?[]const u8 = null,
    expires_at: ?[]const u8 = null,
    completed_at: ?[]const u8 = null,
    /// The card the buyer entered, once there is one.
    card: ?ElementsCardSummary = null,
    /// Why the last attempt failed.
    last_error: ?ElementsError = null,

    /// The status as an `ElementsStatus`, or null when it is missing or unknown to this SDK.
    pub fn knownStatus(self: ElementsSession) ?ElementsStatus {
        return ElementsStatus.parse(self.status orelse return null);
    }

    /// The purpose as an `ElementsPurpose`, or null when it is missing or unknown to this SDK.
    pub fn knownPurpose(self: ElementsSession) ?ElementsPurpose {
        return ElementsPurpose.parse(self.purpose orelse return null);
    }
};

/// A newly created Elements session: the `ElementsSession` fields plus the client secret.
///
/// Hand `client_secret` to the app that opens the card sheet; only `Elements.createSession`
/// returns it. Do not log or store it. Formatting with `{f}` writes it as `[redacted]`, while
/// `std.json.Stringify` keeps it so you can send it to the app. `{any}` prints every field, the
/// secret included, so do not use it on this type.
pub const ElementsSessionWithSecret = struct {
    id: ?[]const u8 = null,
    purpose: ?[]const u8 = null,
    status: ?[]const u8 = null,
    order_reference_id: ?[]const u8 = null,
    user_id: ?[]const u8 = null,
    attempts: ?i64 = null,
    max_attempts: ?i64 = null,
    created_at: ?[]const u8 = null,
    expires_at: ?[]const u8 = null,
    completed_at: ?[]const u8 = null,
    card: ?ElementsCardSummary = null,
    last_error: ?ElementsError = null,
    /// The secret the app opens the card sheet with.
    client_secret: ?[]const u8 = null,
    /// The Elements host for this session, such as "https://checkout.tapsilat.dev".
    elements_base_url: ?[]const u8 = null,

    /// The session without its client secret.
    pub fn session(self: ElementsSessionWithSecret) ElementsSession {
        var result: ElementsSession = .{};
        inline for (@typeInfo(ElementsSession).@"struct".field_names) |name| {
            @field(result, name) = @field(self, name);
        }
        return result;
    }

    /// Writes the fields that are set, like `{any}` with quoted strings, and the client secret
    /// as `[redacted]`.
    pub fn format(self: ElementsSessionWithSecret, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writeRedacted(writer, self, "client_secret");
    }
};

pub const ElementsCardSummary = struct {
    id: ?[]const u8 = null,
    /// Such as "visa" or "troy"; see `knownBrand`.
    brand: ?[]const u8 = null,
    last4: ?[]const u8 = null,
    exp_month: ?i64 = null,
    exp_year: ?i64 = null,

    /// The brand as an `ElementsCardBrand`, or null when it is missing or unknown to this SDK.
    pub fn knownBrand(self: ElementsCardSummary) ?ElementsCardBrand {
        return ElementsCardBrand.parse(self.brand orelse return null);
    }
};

/// An Elements error object, as a session's `last_error` carries it.
pub const ElementsError = struct {
    /// A stable code such as "card_declined" or "attempts_exhausted".
    code: ?[]const u8 = null,
    message: ?[]const u8 = null,
    retryable: ?bool = null,
};

/// Purposes of an Elements session. Requests take the purpose as text, such as
/// `@tagName(ElementsPurpose.pay)`.
pub const ElementsPurpose = enum {
    /// Save a card for `user_id`.
    tokenize,
    /// Pay an order.
    pay,

    /// Returns the purpose named `text`, or null when it is not one this SDK knows.
    pub fn parse(text: []const u8) ?ElementsPurpose {
        return std.meta.stringToEnum(ElementsPurpose, text);
    }
};

/// Statuses of an Elements session.
pub const ElementsStatus = enum {
    requires_payment_method,
    processing,
    requires_action,
    succeeded,
    failed,
    expired,
    canceled,

    /// Returns the status named `text`, or null when it is not one this SDK knows.
    pub fn parse(text: []const u8) ?ElementsStatus {
        return std.meta.stringToEnum(ElementsStatus, text);
    }
};

/// Tokenize modes of an Elements session. Requests take the number, such as
/// `ElementsMode.secure.code()`.
pub const ElementsMode = enum(i64) {
    /// 3D Secure.
    secure = 1,
    half_secure = 2,
    non_secure = 3,

    pub fn code(self: ElementsMode) i64 {
        return @backingInt(self);
    }
};

/// Card brands an Elements session reports.
pub const ElementsCardBrand = enum {
    visa,
    mastercard,
    amex,
    troy,
    discover,
    unionpay,
    unknown,

    /// Returns the brand named `text`, or null when it is not one this SDK knows.
    pub fn parse(text: []const u8) ?ElementsCardBrand {
        return std.meta.stringToEnum(ElementsCardBrand, text);
    }
};

/// Writes a struct like `{any}` does, but with strings quoted, null fields left out and the field
/// named `redacted` written as `[redacted]`.
fn writeRedacted(writer: *std.Io.Writer, value: anytype, comptime redacted: []const u8) std.Io.Writer.Error!void {
    switch (@typeInfo(@TypeOf(value))) {
        .@"struct" => |info| {
            try writer.writeAll(".{");
            var first = true;
            inline for (info.field_names) |name| {
                const field = @field(value, name);
                if (!isNull(field)) {
                    try writer.writeAll(if (first) " ." else ", .");
                    first = false;
                    try writer.writeAll(name);
                    try writer.writeAll(" = ");
                    if (comptime std.mem.eql(u8, name, redacted)) {
                        try writer.writeAll("[redacted]");
                    } else {
                        try writeRedacted(writer, field, "");
                    }
                }
            }
            try writer.writeAll(if (first) "}" else " }");
        },
        .optional => if (value) |inner| try writeRedacted(writer, inner, redacted) else try writer.writeAll("null"),
        .pointer => try writer.print("\"{f}\"", .{std.zig.fmtString(value)}),
        else => try writer.print("{any}", .{value}),
    }
}

fn isNull(value: anytype) bool {
    return switch (@typeInfo(@TypeOf(value))) {
        .optional => value == null,
        else => false,
    };
}

/// The order-create request; see `Order`.
pub const CreateOrderRequest = Order;

/// The order-create response; see `OrderResponse`.
pub const CreateOrderResponse = OrderResponse;

/// Currency units accepted by the API. Requests take the unit as text, such as `@tagName(Currency.TRY)`.
pub const Currency = enum { TRY, USD, EUR, GBP };

pub const Locale = enum { tr, en };

pub const BillingType = enum { PERSONAL, COMPANY };

pub const PaymentOption = enum { PAY_WITH_WALLET, PAY_WITH_CARD, PAY_WITH_LOAN, PAY_WITH_CASH };
