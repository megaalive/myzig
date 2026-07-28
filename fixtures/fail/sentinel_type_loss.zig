//! Fail fixture: sentinel alloc stored into non-sentinel `[]u8` (type loss).

const std = @import("std");

pub fn loseSentinel(allocator: std.mem.Allocator, s: []const u8) !usize {
    const plain: []u8 = try allocator.dupeZ(u8, s);
    defer allocator.free(plain);
    return plain.len;
}
