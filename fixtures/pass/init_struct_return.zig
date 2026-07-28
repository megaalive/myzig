//! Pass fixture: init values returned in a struct are transferred.

const State = struct {
    pub fn init(_: anytype) !State {
        return .{};
    }
    pub fn deinit(_: *State) void {}
};

const S = struct {
    req_state: State,
    res_state: State,
};

pub fn giveStruct() !S {
    const req_state = try State.init(.{});
    const res_state = try State.init(.{});
    return .{ .req_state = req_state, .res_state = res_state };
}
