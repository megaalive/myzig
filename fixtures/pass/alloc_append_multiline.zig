//! Pass fixture: multi-line append consumes owned binding.

const std = @import("std");

const Item = struct {
    data: []u8,
};

pub fn addItem(allocator: std.mem.Allocator, list: *std.ArrayList(Item), src: []const u8) !void {
    const data = try allocator.dupe(u8, src);
    try list.append(allocator, .{ .data = data });
}
