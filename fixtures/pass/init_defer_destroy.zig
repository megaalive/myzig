//! Pass fixture: init paired with defer destroy (protocol-style teardown).

const Decoration = struct {
    pub fn init(_: anytype) !Decoration {
        return .{};
    }
    pub fn destroy(_: *Decoration) void {}
};

pub fn ok() !void {
    var decoration = try Decoration.init(.{});
    defer decoration.destroy();
}
