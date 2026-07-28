//! Fail fixture: FFI-shaped init without deinit (C handle leak risk).

const c = struct {
    pub fn open() ?*anyopaque {
        return @ptrFromInt(1);
    }
    pub fn close(_: ?*anyopaque) void {}
};

const Db = struct {
    handle: ?*anyopaque,
    pub fn init() !Db {
        return .{ .handle = c.open() };
    }
};

pub fn bad() !void {
    var db = try Db.init();
    _ = db;
}
