//! `myzig limits` — print published honest limits (text, updatable without code).

const std = @import("std");
const compat = @import("compat.zig");

pub const embedded_limits =
    \\# myzig honest limits (embedded stub)
    \\
    \\No on-disk `docs/LIMITS.md` found. Vendor myzig docs or set
    \\`MYZIG_LIMITS_PATH`. Prefer publishing limits as text so agents can read
    \\ceilings without guessing.
    \\
;

pub const Bundle = struct {
    body: []const u8,
    path: []const u8,
    owned: ?[]u8,

    pub fn deinit(self: *Bundle, gpa: std.mem.Allocator) void {
        if (self.owned) |b| gpa.free(b);
        self.* = undefined;
    }
};

pub fn load(io: compat.Io, gpa: std.mem.Allocator) !Bundle {
    if (compat.envGet(gpa, "MYZIG_LIMITS_PATH")) |env_path| {
        defer gpa.free(env_path);
        if (compat.readFileAlloc(io, gpa, env_path, 2 * 1024 * 1024)) |body| {
            return .{ .body = body, .path = "env:MYZIG_LIMITS_PATH", .owned = body };
        } else |_| {}
    } else |_| {}

    const candidates = [_][]const u8{
        "docs/LIMITS.md",
        "myzig/docs/LIMITS.md",
    };
    for (candidates) |cand| {
        if (compat.readFileAlloc(io, gpa, cand, 2 * 1024 * 1024)) |body| {
            return .{ .body = body, .path = cand, .owned = body };
        } else |_| {}
    }
    return .{ .body = embedded_limits, .path = "(builtin)", .owned = null };
}

pub fn write(writer: *std.Io.Writer, bundle: Bundle, show_source: bool) std.Io.Writer.Error!void {
    if (show_source) {
        try writer.print("limits source: {s}\n\n", .{bundle.path});
    }
    try writer.writeAll(bundle.body);
    if (bundle.body.len == 0 or bundle.body[bundle.body.len - 1] != '\n') {
        try writer.writeAll("\n");
    }
}

test "embedded limits non-empty" {
    try std.testing.expect(embedded_limits.len > 40);
}
