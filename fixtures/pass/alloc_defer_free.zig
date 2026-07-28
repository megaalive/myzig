//! Ordinary Zig that discharges an allocation obligation with `defer`.
//! Used as a pass fixture for `memory.alloc-undischarged` (M0/M1).
//! This file does not import myzig.

const std = @import("std");

pub fn copyIntoOwnedBuffer(allocator: std.mem.Allocator, src: []const u8) ![]u8 {
    const buffer = try allocator.alloc(u8, src.len);
    defer allocator.free(buffer);
    @memcpy(buffer, src);
    // Return a duplicate so the deferred free is intentional local cleanup.
    return try allocator.dupe(u8, buffer);
}

test "local buffer is freed before return" {
    const gpa = std.testing.allocator;
    const out = try copyIntoOwnedBuffer(gpa, "hello");
    defer gpa.free(out);
    try std.testing.expectEqualStrings("hello", out);
}
