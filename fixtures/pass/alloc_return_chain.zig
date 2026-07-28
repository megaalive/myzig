//! Pass fixture: multi-hop rename still counts as return transfer.

const std = @import("std");

pub fn giveChain(allocator: std.mem.Allocator, n: usize) ![]u8 {
    const buffer = try allocator.alloc(u8, n);
    const mid = buffer;
    const owned = mid;
    return owned;
}
