//! Fail fixture: helper hides allocation policy behind page_allocator.

const std = @import("std");

pub fn bad() !void {
    const p = try std.heap.page_allocator.alloc(u8, 1);
    defer std.heap.page_allocator.free(p);
}
