//! Fail fixture: mem.concat creates owned memory that is neither freed nor transferred.

const std = @import("std");

pub fn leakyJoin(allocator: std.mem.Allocator) !usize {
    const s = try std.mem.concat(allocator, u8, &.{ "a", "b" });
    return s.len;
}
