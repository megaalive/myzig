//! Pass fixture: one-hop rename still counts as return transfer.

const std = @import("std");

pub fn giveAlias(allocator: std.mem.Allocator, n: usize) ![]u8 {
    const buffer = try allocator.alloc(u8, n);
    const owned = buffer;
    return owned;
}
