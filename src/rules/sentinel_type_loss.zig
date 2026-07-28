//! Convention: sentinel alloc assigned into non-sentinel `[]u8` / `[]const u8`.
//! Text-scan V0 — same-line type annotation only (honest; no CFG).

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

const acquires = [_][]const u8{
    ".dupeZ(",
    ".dupeSentinel(",
    ".allocSentinel(",
    ".allocPrintSentinel(",
};

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var search_from: usize = 0;
    while (search_from < source.len) {
        const hit = scan.nextNeedle(source, search_from, &acquires) orelse break;
        if (scan.isInLineComment(source, hit)) {
            search_from = hit + 1;
            continue;
        }
        const line_start: usize = if (std.mem.lastIndexOfScalar(u8, source[0..hit], '\n')) |nl| nl + 1 else 0;
        const line_end = std.mem.indexOfScalarPos(u8, source, hit, '\n') orelse source.len;
        const line = source[line_start..line_end];
        const rel = hit - line_start;
        if (!lineLosesSentinel(line, rel)) {
            search_from = hit + 1;
            continue;
        }
        try out.append(gpa, diagnostic.Diagnostic.fromRule(
            schema.seed_sentinel_type_loss,
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

fn lineLosesSentinel(line: []const u8, acquire_rel: usize) bool {
    if (acquire_rel > line.len) return false;
    const before = line[0..acquire_rel];
    // Explicit non-sentinel slice annotation on the same binding line.
    // Does not match `[:0]u8` / `[:0]const u8`.
    if (std.mem.indexOf(u8, before, ": []u8") != null) return true;
    if (std.mem.indexOf(u8, before, ": []const u8") != null) return true;
    return false;
}

test "same-line []u8 dupeZ is flagged; [:0]u8 is not" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad(a: anytype, s: []const u8) !void {
        \\    const plain: []u8 = try a.dupeZ(u8, s);
        \\    _ = plain;
        \\}
    ;
    const pass_src =
        \\pub fn ok(a: anytype, s: []const u8) !void {
        \\    const z: [:0]u8 = try a.dupeZ(u8, s);
        \\    _ = z;
        \\}
    ;
    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("fail.zig", fail_src, &fail_diags, gpa);
    try std.testing.expectEqual(@as(usize, 1), fail_diags.items.len);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("pass.zig", pass_src, &pass_diags, gpa);
    try std.testing.expectEqual(@as(usize, 0), pass_diags.items.len);
}
