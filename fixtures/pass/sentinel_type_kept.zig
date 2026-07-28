//! Pass fixture: keep sentinel type from `dupeZ`.

const std = @import("std");

pub fn keepSentinel(allocator: std.mem.Allocator, s: []const u8) !usize {
    const z: [:0]u8 = try allocator.dupeZ(u8, s);
    defer allocator.free(z);
    return z.len;
}
