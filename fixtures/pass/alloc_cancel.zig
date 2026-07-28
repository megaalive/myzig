//! Pass fixture: create discharged by cancel (completion-style).

pub fn ok(allocator: anytype) !void {
    const c = try allocator.create(u32);
    defer c.cancel();
}
