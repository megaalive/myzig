//! Pass fixture: init paired with defer unload (Load/Unload-style API).

const Target = struct {
    pub fn init(_: i32, _: i32) !Target {
        return .{};
    }
    pub fn unload(_: Target) void {}
};

pub fn ok() !void {
    const target = try Target.init(64, 64);
    defer target.unload();
}
