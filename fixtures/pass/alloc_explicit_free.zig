//! Pass fixture: explicit free (no defer) discharges the local allocation.

const std = @import("std");

pub fn freeNow(allocator: std.mem.Allocator, n: usize) !void {
    const buffer = try allocator.alloc(u8, n);
    allocator.free(buffer);
}
