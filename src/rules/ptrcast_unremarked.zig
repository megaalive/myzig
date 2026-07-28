//! Convention detector for `unsafe.ptrcast-unremarked`.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");
const permit = @import("../permit.zig");

const Needle = struct {
    text: []const u8,
    kind: permit.Kind,
};

const needles = [_]Needle{
    .{ .text = "@ptrCast(", .kind = .ptrcast },
    .{ .text = "@alignCast(", .kind = .aligncast },
};

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var search_from: usize = 0;
    while (search_from < source.len) {
        var best_idx: ?usize = null;
        var best_needle: ?Needle = null;
        for (needles) |n| {
            if (std.mem.indexOfPos(u8, source, search_from, n.text)) |idx| {
                if (best_idx == null or idx < best_idx.?) {
                    best_idx = idx;
                    best_needle = n;
                }
            }
        }
        const hit = best_idx orelse break;
        const n = best_needle.?;
        if (scan.isInLineComment(source, hit)) {
            search_from = hit + 1;
            continue;
        }
        const line = scan.lineSlice(source, hit);
        const parsed = permit.parseLine(line, n.kind);
        if (!parsed.ok) {
            try out.append(gpa, diagnostic.Diagnostic.fromRule(
                schema.seed_ptrcast_unremarked,
                .convention,
                .{
                    .path = path,
                    .line = scan.lineNumber(source, hit),
                    .column = scan.columnNumber(source, hit),
                },
                null,
            ));
        }
        search_from = hit + 1;
    }
}

test "ptrCast without remark is flagged" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad(p: *anyopaque) *u8 {
        \\    return @ptrCast(p);
        \\}
    ;
    const pass_src =
        \\pub fn ok(p: *anyopaque) *u8 {
        \\    return @ptrCast(p); // myzig.permit(ptrcast): FFI opaque handle
        \\}
    ;
    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("fail.zig", fail_src, &fail_diags, gpa);
    try std.testing.expect(fail_diags.items.len >= 1);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("pass.zig", pass_src, &pass_diags, gpa);
    try std.testing.expect(pass_diags.items.len == 0);
}
