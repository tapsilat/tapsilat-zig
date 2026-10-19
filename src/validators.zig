//! Input validation shared with the other Tapsilat SDKs.

const std = @import("std");
const Allocator = std.mem.Allocator;

pub const ValidationError = error{
    InvalidPhoneNumber,
    PhoneNumberTooShort,
    InvalidInstallments,
    InstallmentOutOfRange,
};

/// Validates a phone number and returns it without spaces, dashes and parentheses, allocated
/// with `allocator`. International numbers ("+..." or "00...") and national numbers ("0...")
/// are accepted.
pub fn validateGsmNumber(allocator: Allocator, phone: []const u8) (ValidationError || Allocator.Error)![]u8 {
    var clean: std.ArrayList(u8) = .empty;
    errdefer clean.deinit(allocator);
    for (phone) |c| {
        switch (c) {
            ' ', '-', '(', ')' => {},
            '+', '0'...'9' => try clean.append(allocator, c),
            else => return error.InvalidPhoneNumber,
        }
    }
    const value = clean.items;
    if (value.len == 0) return clean.toOwnedSlice(allocator);

    const plus_count = std.mem.count(u8, value, "+");
    if (plus_count == value.len) return error.InvalidPhoneNumber;
    if (plus_count > 1 or (plus_count == 1 and value[0] != '+')) return error.InvalidPhoneNumber;

    const min_len: usize = if (value[0] == '+')
        8
    else if (std.mem.startsWith(u8, value, "00"))
        9
    else if (value[0] == '0')
        7
    else
        6;
    if (value.len < min_len) return error.PhoneNumberTooShort;

    return clean.toOwnedSlice(allocator);
}

/// Parses a comma-separated installment list such as "1,2,3", allocated with `allocator`.
/// Every value must be between 1 and 12; an empty list means a single installment.
pub fn parseInstallments(allocator: Allocator, installments: []const u8) (ValidationError || Allocator.Error)![]u8 {
    var values: std.ArrayList(u8) = .empty;
    errdefer values.deinit(allocator);
    var it = std.mem.splitScalar(u8, installments, ',');
    while (it.next()) |part| {
        const trimmed = std.mem.trim(u8, part, " \t");
        if (trimmed.len == 0) continue;
        const value = std.fmt.parseInt(i64, trimmed, 10) catch return error.InvalidInstallments;
        if (value < 1 or value > 12) return error.InstallmentOutOfRange;
        try values.append(allocator, @intCast(value));
    }
    if (values.items.len == 0) try values.append(allocator, 1);
    return values.toOwnedSlice(allocator);
}

test "validateGsmNumber cleans formatting" {
    const allocator = std.testing.allocator;
    const cleaned = try validateGsmNumber(allocator, "+90 (555) 123-45-67");
    defer allocator.free(cleaned);
    try std.testing.expectEqualStrings("+905551234567", cleaned);

    const empty = try validateGsmNumber(allocator, "");
    defer allocator.free(empty);
    try std.testing.expectEqualStrings("", empty);
}

test "validateGsmNumber rejects invalid numbers" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(error.InvalidPhoneNumber, validateGsmNumber(allocator, "call me"));
    try std.testing.expectError(error.InvalidPhoneNumber, validateGsmNumber(allocator, "90+5551234567"));
    try std.testing.expectError(error.InvalidPhoneNumber, validateGsmNumber(allocator, "+++"));
    try std.testing.expectError(error.PhoneNumberTooShort, validateGsmNumber(allocator, "+12345"));
    try std.testing.expectError(error.PhoneNumberTooShort, validateGsmNumber(allocator, "0012345"));
}

test "parseInstallments" {
    const allocator = std.testing.allocator;
    const values = try parseInstallments(allocator, "1, 3,6");
    defer allocator.free(values);
    try std.testing.expectEqualSlices(u8, &.{ 1, 3, 6 }, values);

    const default = try parseInstallments(allocator, "");
    defer allocator.free(default);
    try std.testing.expectEqualSlices(u8, &.{1}, default);

    try std.testing.expectError(error.InstallmentOutOfRange, parseInstallments(allocator, "0,13"));
    try std.testing.expectError(error.InvalidInstallments, parseInstallments(allocator, "two"));
}
