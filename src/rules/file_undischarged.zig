//! Heuristic detector for `resource.file-undischarged`.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

const acquire_needles = [_][]const u8{ ".openFile(", ".createFile(", "openFileAbsolute(", "createFileAbsolute(" };
const discharge_words = [_][]const u8{"close"};

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var funcs = try scan.findFunctions(gpa, source);
    defer scan.freeFunctions(gpa, &funcs);

    for (funcs.items) |func| {
        const body = source[func.start .. func.end + 1];
        const has_defer_close = scan.deferLineMentions(body, &discharge_words);
        const has_close_call = std.mem.indexOf(u8, body, ".close(") != null;

        var search_from: usize = 0;
        while (search_from < body.len) {
            const hit = scan.nextNeedle(body, search_from, &acquire_needles) orelse break;
            const abs_index = func.start + hit;
            if (scan.isInLineComment(source, abs_index)) {
                search_from = hit + 1;
                continue;
            }
            if (!has_defer_close and !has_close_call) {
                try out.append(gpa, diagnostic.Diagnostic.fromRule(
                    schema.seed_file_undischarged,
                    .likely,
                    .{
                        .path = path,
                        .line = scan.lineNumber(source, abs_index),
                        .column = scan.columnNumber(source, abs_index),
                    },
                    null,
                ));
            }
            search_from = hit + 1;
        }
    }
}

test "openFile without close is flagged" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad(dir: anytype) !void {
        \\    const f = try dir.openFile("x", .{});
        \\    _ = f;
        \\}
    ;
    const pass_src =
        \\pub fn ok(dir: anytype) !void {
        \\    const f = try dir.openFile("x", .{});
        \\    defer f.close();
        \\    _ = f;
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
