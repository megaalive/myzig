//! Pass fixture: allocation transferred by returning the local binding.

const std = @import("std");

pub fn giveLocal(allocator: std.mem.Allocator, n: usize) ![]u8 {
    const buffer = try allocator.alloc(u8, n);
    return buffer;
}
