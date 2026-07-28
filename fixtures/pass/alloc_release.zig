//! Pass fixture: create discharged by method release (handle-style).

pub fn ok(allocator: anytype) !void {
    const view = try allocator.create(u32);
    defer view.release();
}
