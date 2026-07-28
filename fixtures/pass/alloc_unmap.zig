//! Pass fixture: create discharged by unmap (mapped-buffer style).

pub fn ok(allocator: anytype) !void {
    const buf = try allocator.create(u32);
    defer buf.unmap();
}
