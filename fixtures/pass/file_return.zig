//! Pass fixture: file handle transferred by return.

pub fn give(dir: anytype) !@TypeOf(try dir.openFile("x.txt", .{})) {
    const file = try dir.openFile("x.txt", .{});
    return file;
}
