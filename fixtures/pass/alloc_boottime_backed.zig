//! Pass fixture: boottime allocator acquires are arena-token discharged.

pub fn early(boot: anytype) !void {
    const tmp = try boot.boottime_allocator.dupe(u8, "ok");
    _ = tmp;
}
