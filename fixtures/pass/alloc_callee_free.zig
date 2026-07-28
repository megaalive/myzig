//! Pass fixture: same-file callee frees the matching parameter.

fn adoptBuf(allocator: anytype, buf: []u8) void {
    defer allocator.free(buf);
    _ = buf;
}

pub fn give(allocator: anytype, n: usize) !void {
    const buffer = try allocator.alloc(u8, n);
    adoptBuf(allocator, buffer);
}
