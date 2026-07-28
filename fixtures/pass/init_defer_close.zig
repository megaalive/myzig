//! Pass fixture: init paired with defer close (socket-style teardown).

const Sock = struct {
    pub fn init() !Sock {
        return .{};
    }
    pub fn close(_: *Sock) void {}
};

pub fn ok() !void {
    var sock = try Sock.init();
    defer sock.close();
}
