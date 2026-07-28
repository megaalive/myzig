//! Convention: empty `catch {}` / `catch unreachable` swallow errors.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var i: usize = 0;
    while (i < source.len) : (i += 1) {
        if (!std.mem.startsWith(u8, source[i..], "catch")) continue;
        if (i > 0) {
            const prev = source[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        var j = i + "catch".len;
        if (j < source.len and (std.ascii.isAlphanumeric(source[j]) or source[j] == '_')) continue;
        while (j < source.len and std.ascii.isWhitespace(source[j])) : (j += 1) {}
        if (j >= source.len) continue;

        if (std.mem.startsWith(u8, source[j..], "unreachable")) {
            if (scan.isInLineComment(source, i)) continue;
            // Documented invariant: adjacent/same-line comment excuses unreachable.
            if (catchUnreachableIsDocumented(source, i)) {
                i = j;
                continue;
            }
            try out.append(gpa, diagnostic.Diagnostic.fromRule(
                schema.seed_swallow_error,
                .convention,
                .{
                    .path = path,
                    .line = scan.lineNumber(source, i),
                    .column = scan.columnNumber(source, i),
                },
                null,
            ));
            i = j;
            continue;
        }

        if (source[j] != '{') continue;
        const close = scan.matchingBrace(source, j) orelse continue;
        const inner = source[j + 1 .. close];
        if (!catchBodyIsEmpty(inner)) {
            i = close;
            continue;
        }
        // Comment-only catch is allowed (documented ignore).
        if (catchBodyHasComment(inner)) {
            i = close;
            continue;
        }
        try out.append(gpa, diagnostic.Diagnostic.fromRule(
            schema.seed_swallow_error,
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

fn catchBodyIsEmpty(inner: []const u8) bool {
    var i: usize = 0;
    while (i < inner.len) {
        while (i < inner.len and std.ascii.isWhitespace(inner[i])) : (i += 1) {}
        if (i >= inner.len) return true;
        if (std.mem.startsWith(u8, inner[i..], "//")) {
            const nl = std.mem.indexOfScalarPos(u8, inner, i, '\n') orelse return true;
            i = nl + 1;
            continue;
        }
        if (std.mem.startsWith(u8, inner[i..], "unreachable")) {
            var k = i + "unreachable".len;
            while (k < inner.len and std.ascii.isWhitespace(inner[k])) : (k += 1) {}
            if (k < inner.len and inner[k] == ';') k += 1;
            while (k < inner.len and std.ascii.isWhitespace(inner[k])) : (k += 1) {}
            return k >= inner.len;
        }
        return false;
    }
    return true;
}

fn catchBodyHasComment(inner: []const u8) bool {
    return std.mem.indexOf(u8, inner, "//") != null;
}

fn catchUnreachableIsDocumented(source: []const u8, catch_index: usize) bool {
    const curr = scan.lineSlice(source, catch_index);
    if (std.mem.indexOf(u8, curr, "//") != null) return true;
    if (scan.previousLineSlice(source, catch_index)) |prev| {
        const trimmed = std.mem.trim(u8, prev, " \t");
        if (std.mem.startsWith(u8, trimmed, "//")) return true;
    }
    return false;
}

test "empty catch flagged; commented catch and real handler are not" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad() void {
        \\    mightFail() catch {};
        \\}
    ;
    const comment_src =
        \\pub fn ok() void {
        \\    mightFail() catch {
        \\        // intentionally ignored
        \\    };
        \\}
    ;
    const pass_src =
        \\pub fn ok2() void {
        \\    mightFail() catch |err| {
        \\        _ = err;
        \\    };
        \\}
    ;
    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("fail.zig", fail_src, &fail_diags, gpa);
    try std.testing.expect(fail_diags.items.len >= 1);

    var comment_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer comment_diags.deinit(gpa);
    try analyzeSource("comment.zig", comment_src, &comment_diags, gpa);
    try std.testing.expect(comment_diags.items.len == 0);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("pass.zig", pass_src, &pass_diags, gpa);
    try std.testing.expect(pass_diags.items.len == 0);

    const unreachable_doc_src =
        \\pub fn ok3() void {
        \\    // Uri is guaranteed valid
        \\    _ = parse() catch unreachable;
        \\}
    ;
    var unreachable_doc_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer unreachable_doc_diags.deinit(gpa);
    try analyzeSource("unreachable_doc.zig", unreachable_doc_src, &unreachable_doc_diags, gpa);
    try std.testing.expect(unreachable_doc_diags.items.len == 0);

    const unreachable_bare_src =
        \\pub fn bad2() void {
        \\    _ = parse() catch unreachable;
        \\}
    ;
    var unreachable_bare_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer unreachable_bare_diags.deinit(gpa);
    try analyzeSource("unreachable_bare.zig", unreachable_bare_src, &unreachable_bare_diags, gpa);
    try std.testing.expect(unreachable_bare_diags.items.len >= 1);
}
