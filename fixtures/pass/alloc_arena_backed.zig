//! Pass fixture: arena-backed acquires are owned by the arena lifetime.

pub fn scratch(analyser: anytype) !void {
    const held = try analyser.arena.dupe(u8, "x");
    _ = held;
}
