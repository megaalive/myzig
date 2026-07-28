//! Pass fixture: same-line list.append(try dupe) transfers ownership into the collection.

const std = @import("std");

pub fn collect(allocator: std.mem.Allocator, list: *std.ArrayList([]u8), s: []const u8) !void {
    try list.append(allocator, try allocator.dupe(u8, s));
}
