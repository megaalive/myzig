//! Pass fixture: indexed store into caller buffer transfers ownership.

pub fn fill(allocator: anytype, into: [][]u8, src: []const u8) !void {
    into[0] = try allocator.dupe(u8, src);
}
