//! Pass fixture: dupes inside `return .{ ... }` transfer to the caller.

const std = @import("std");

pub const Sesi = struct {
    id: []u8,
    cwd: []u8,
};

pub fn buat(allocator: std.mem.Allocator, id: []const u8, cwd: []const u8) !Sesi {
    return .{
        .id = try allocator.dupe(u8, id),
        .cwd = try allocator.dupe(u8, cwd),
    };
}

pub fn denganPesan(allocator: std.mem.Allocator, n: usize) !struct { pesan: []u8 } {
    const daftar = try allocator.alloc(u8, n);
    return .{
        .pesan = daftar,
    };
}
