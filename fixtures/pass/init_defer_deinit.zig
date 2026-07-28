//! Pass fixture: init paired with defer deinit.

const Loop = struct {
    pub fn init(_: anytype) !Loop {
        return .{};
    }
    pub fn deinit(_: *Loop) void {}
};

pub fn ok() !void {
    var loop = try Loop.init(.{});
    defer loop.deinit();
}
