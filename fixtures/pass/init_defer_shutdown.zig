//! Pass fixture: init paired with defer shutdown (setup/shutdown-style API).

const Gfx = struct {
    pub fn init() !Gfx {
        return .{};
    }
    pub fn shutdown(_: *Gfx) void {}
};

pub fn ok() !void {
    var gfx = try Gfx.init();
    defer gfx.shutdown();
}
