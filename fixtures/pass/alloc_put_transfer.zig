//! Pass fixture: map put transfers ownership of the allocated value.

pub fn putOwned(map: anytype, allocator: anytype, key: u32, src: []const u8) !void {
    const value = try allocator.dupe(u8, src);
    try map.put(key, value);
}

pub fn putSameLine(map: anytype, allocator: anytype, key: u32, src: []const u8) !void {
    try map.put(key, try allocator.dupe(u8, src));
}
