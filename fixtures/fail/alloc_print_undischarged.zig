//! Fail fixture: allocPrint creates owned memory that is neither freed nor transferred.

const std = @import("std");

pub fn leakyPrint(allocator: std.mem.Allocator) !usize {
    const msg = try std.fmt.allocPrint(allocator, "n={d}", .{1});
    return msg.len;
}
