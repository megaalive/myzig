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
        if (!hasAdjacentPermit(source, hit, n.kind)) {
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

fn hasAdjacentPermit(source: []const u8, index: usize, expected: permit.Kind) bool {
    const curr = scan.lineSlice(source, index);
    if (permit.parseLine(curr, expected).ok) return true;
    if (scan.previousLineSlice(source, index)) |prev| {
        if (permit.parseLine(prev, expected).ok) return true;
    }
    if (scan.nextLineSlice(source, index)) |next| {
        if (permit.parseLine(next, expected).ok) return true;
    }
    return false;
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
    const adjacent_src =
        \\pub fn okAdjacent(p: *anyopaque) *u8 {
        \\    // myzig.permit(ptrcast): callback opaque
        \\    return @ptrCast(p);
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

    var adj_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer adj_diags.deinit(gpa);
    try analyzeSource("adjacent.zig", adjacent_src, &adj_diags, gpa);
    try std.testing.expect(adj_diags.items.len == 0);
}
