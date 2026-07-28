//! Heuristic detector for empty `defer` / `errdefer` blocks (convention).
//! Text-scan V0 — brace body only whitespace/comments.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

const Kind = enum { defer_kw, errdefer_kw };

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var i: usize = 0;
    while (i < source.len) : (i += 1) {
        const kind: Kind = blk: {
            if (std.mem.startsWith(u8, source[i..], "errdefer")) break :blk .errdefer_kw;
            if (std.mem.startsWith(u8, source[i..], "defer")) break :blk .defer_kw;
            continue;
        };
        if (i > 0) {
            const prev = source[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        const kw_len: usize = switch (kind) {
            .errdefer_kw => "errdefer".len,
            .defer_kw => "defer".len,
        };
        var j = i + kw_len;
        if (j < source.len and (std.ascii.isAlphanumeric(source[j]) or source[j] == '_')) continue;
        while (j < source.len and std.ascii.isWhitespace(source[j])) : (j += 1) {}
        if (j >= source.len or source[j] != '{') continue;
        const close = scan.matchingBrace(source, j) orelse continue;
        const inner = source[j + 1 .. close];
        if (!blockBodyIsEmpty(inner)) {
            i = close;
            continue;
        }
        const rule = switch (kind) {
            .defer_kw => schema.seed_empty_defer,
            .errdefer_kw => schema.seed_empty_errdefer,
        };
        try out.append(gpa, diagnostic.Diagnostic.fromRule(
            rule,
            .convention,
            .{
                .path = path,
                .line = scan.lineNumber(source, i),
                .column = scan.columnNumber(source, i),
            },
            null,
        ));
        i = close;
    }
}

fn blockBodyIsEmpty(inner: []const u8) bool {
    var i: usize = 0;
    while (i < inner.len) {
        while (i < inner.len and std.ascii.isWhitespace(inner[i])) : (i += 1) {}
        if (i >= inner.len) return true;
        if (std.mem.startsWith(u8, inner[i..], "//")) {
            const nl = std.mem.indexOfScalarPos(u8, inner, i, '\n') orelse return true;
            i = nl + 1;
            continue;
        }
        return false;
    }
    return true;
}

test "empty defer flagged; non-empty deferred free is not" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad() void {
        \\    defer {}
        \\}
    ;
    const comment_src =
        \\pub fn todo() void {
        \\    defer {
        \\        // TODO: cleanup
        \\    }
        \\}
    ;
    const pass_src =
        \\pub fn ok(allocator: anytype, buf: []u8) void {
        \\    defer allocator.free(buf);
        \\}
    ;
    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("fail.zig", fail_src, &fail_diags, gpa);
    try std.testing.expect(fail_diags.items.len >= 1);

    var comment_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer comment_diags.deinit(gpa);
    try analyzeSource("comment.zig", comment_src, &comment_diags, gpa);
    try std.testing.expect(comment_diags.items.len >= 1);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("pass.zig", pass_src, &pass_diags, gpa);
    try std.testing.expect(pass_diags.items.len == 0);
}
