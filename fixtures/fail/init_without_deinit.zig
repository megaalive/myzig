//! Fail fixture: init without matching deinit.

const Loop = struct {
    pub fn init(_: anytype) !Loop {
        return .{};
    }
    pub fn deinit(_: *Loop) void {}
};

pub fn bad() !void {
    var loop = try Loop.init(.{});
    _ = loop;
}
