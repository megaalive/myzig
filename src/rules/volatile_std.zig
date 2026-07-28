//! Convention detector for `compat.volatile-std`.
//!
//! Flags high-churn / stale std call sites that agents often paste from memory.
//! Active only when callers pass `enabled=true` (`--prefer-compat` or
//! `.myzig/prefer_compat`). Ordinary Zig remains first-class without that opt-in.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

/// Patterns that broke under Zig 0.17 and/or are intentionally insulated by myzig.compat.
const needles = [_][]const u8{
    "std.fs.cwd",
    "std.process.getEnvVarOwned",
    "std.time.timestamp",
    "std.time.milliTimestamp",
    "std.Io.Dir.cwd",
};

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
    enabled: bool,
) !void {
    if (!enabled) return;
    if (isCompatAdapterPath(path)) return;

    var search_from: usize = 0;
    while (search_from < source.len) {
        const hit = scan.nextNeedle(source, search_from, &needles) orelse break;
        if (scan.isInLineComment(source, hit)) {
            search_from = hit + 1;
            continue;
        }
        try out.append(gpa, diagnostic.Diagnostic.fromRule(
            schema.seed_volatile_std,
            .convention,
            .{
                .path = path,
                .line = scan.lineNumber(source, hit),
                .column = scan.columnNumber(source, hit),
            },
            null,
        ));
        search_from = hit + 1;
    }
}

fn isCompatAdapterPath(path: []const u8) bool {
    return std.mem.indexOf(u8, path, "/compat/") != null or
        std.mem.indexOf(u8, path, "\\compat\\") != null or
        std.mem.endsWith(u8, path, "/compat.zig") or
        std.mem.endsWith(u8, path, "\\compat.zig");
}

test "volatile std flagged when enabled" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad() void {
        \\    _ = std.fs.cwd();
        \\}
    ;
    const pass_src =
        \\pub fn ok(io: anytype, gpa: anytype) ![]u8 {
        \\    return myzig.compat.readFileAlloc(io, gpa, "x", 64);
        \\}
    ;

    var off: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer off.deinit(gpa);
    try analyzeSource("x.zig", fail_src, &off, gpa, false);
    try std.testing.expect(off.items.len == 0);

    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("x.zig", fail_src, &fail_diags, gpa, true);
    try std.testing.expect(fail_diags.items.len >= 1);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("x.zig", pass_src, &pass_diags, gpa, true);
    try std.testing.expect(pass_diags.items.len == 0);

    var adapter: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer adapter.deinit(gpa);
    try analyzeSource("src/compat/zig_0_17.zig", fail_src, &adapter, gpa, true);
    try std.testing.expect(adapter.items.len == 0);
}
