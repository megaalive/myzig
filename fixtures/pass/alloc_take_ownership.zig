//! Pass fixture: named ownership-handoff call takes the buffer.

fn takeOwnership(buf: []u8) void {
    _ = buf;
}

pub fn give(allocator: anytype, n: usize) !void {
    const buffer = try allocator.alloc(u8, n);
    takeOwnership(buffer);
}
