//! Fail fixture for `resource.file-undischarged`.

pub fn leakyOpen(dir: anytype) !void {
    const file = try dir.openFile("x.txt", .{});
    _ = file;
}
