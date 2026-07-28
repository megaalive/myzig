//! Pass fixture: ownership transferred via out-parameter.

const std = @import("std");

pub fn fill(allocator: std.mem.Allocator, n: usize, out: *[]u8) !void {
    const buffer = try allocator.alloc(u8, n);
    out.* = buffer;
}

pub fn fillDirect(allocator: std.mem.Allocator, n: usize, out: *[]u8) !void {
    out.* = try allocator.alloc(u8, n);
}
