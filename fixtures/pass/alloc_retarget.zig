//! Pass fixture: ownership retarget `out = next; return out`.

const std = @import("std");

pub fn trimCopy(allocator: std.mem.Allocator, teks: []const u8) ![]u8 {
    var out = try allocator.dupe(u8, teks);
    if (teks.len == 0) return out;
    const next = try allocator.dupe(u8, teks[1..]);
    allocator.free(out);
    out = next;
    return out;
}
