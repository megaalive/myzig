//! Pass fixture for `resource.file-undischarged`.

pub fn carefulOpen(dir: anytype) !void {
    const file = try dir.openFile("x.txt", .{});
    defer file.close();
    _ = file;
}
