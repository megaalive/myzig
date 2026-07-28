//! Pass fixture: allocPrint returned to caller (transfer).

const std = @import("std");

pub fn givePrint(allocator: std.mem.Allocator, n: usize) ![]u8 {
    return try std.fmt.allocPrint(allocator, "n={d}", .{n});
}
