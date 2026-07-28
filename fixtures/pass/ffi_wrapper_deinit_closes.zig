//! Pass fixture: wrapper deinit closes the C handle.

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
    pub fn deinit(self: *Db) void {
        c.close(self.handle);
        self.handle = null;
    }
};

pub fn ok() !void {
    var db = try Db.init();
    defer db.deinit();
    _ = db;
}
