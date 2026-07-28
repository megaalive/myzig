//! Pass fixture: scratch-allocator acquires follow arena-token discharge.

pub fn frame(ctx: anytype) !void {
    const msg = try ctx.scratch_allocator.dupe(u8, "ok");
    _ = msg;
}
