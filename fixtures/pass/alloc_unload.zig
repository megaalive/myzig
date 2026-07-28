//! Pass fixture: create discharged by method unload.

pub fn ok(allocator: anytype) !void {
    const mesh = try allocator.create(u32);
    defer mesh.unload();
}
