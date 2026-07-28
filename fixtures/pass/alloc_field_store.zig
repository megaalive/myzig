//! Pass fixture: field store transfers ownership to the struct owner.

const S = struct { name: []u8 };

pub fn store(self: *S, allocator: anytype, src: []const u8) !void {
    self.name = try allocator.dupe(u8, src);
}
