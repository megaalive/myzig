//! Convention: prefer caller-supplied allocators over hidden globals.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

/// Longest-first so `std.heap.page_allocator` wins over `heap.page_allocator`.
const needles = [_][]const u8{
    "std.heap.page_allocator",
    "std.heap.c_allocator",
    "heap.page_allocator",
    "heap.c_allocator",
};

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var flagged_line: u32 = 0;
    var search_from: usize = 0;
    while (search_from < source.len) {
        const hit = nextLongestNeedle(source, search_from) orelse break;
        if (scan.isInLineComment(source, hit.index)) {
            search_from = hit.index + hit.len;
            continue;
        }
        if (insideTestBlock(source, hit.index)) {
            search_from = hit.index + hit.len;
            continue;
        }
        // Skip `heap.page_allocator` when it is actually `std.heap…` (already
        // matched by the longer needle on a prior iteration).
        if (hit.len < "std.heap.page_allocator".len and hit.index >= 4) {
            if (std.mem.eql(u8, source[hit.index - 4 .. hit.index], "std.")) {
                search_from = hit.index + hit.len;
                continue;
            }
        }
        const line = scan.lineSlice(source, hit.index);
        const looks_like_use = std.mem.indexOf(u8, line, ".alloc(") != null or
            std.mem.indexOf(u8, line, ".create(") != null or
            std.mem.indexOf(u8, line, ".dupe(") != null or
            std.mem.indexOf(u8, line, ".free(") != null or
            std.mem.indexOf(u8, line, ".destroy(") != null or
            std.mem.indexOf(u8, line, "try ") != null;
        if (!looks_like_use) {
            search_from = hit.index + hit.len;
            continue;
        }
        const line_no = scan.lineNumber(source, hit.index);
        if (line_no == flagged_line) {
            search_from = hit.index + hit.len;
            continue;
        }
        flagged_line = line_no;
        try out.append(gpa, diagnostic.Diagnostic.fromRule(
            schema.seed_hidden_allocator,
            .convention,
            .{
                .path = path,
                .line = line_no,
                .column = scan.columnNumber(source, hit.index),
            },
            null,
        ));
        search_from = hit.index + hit.len;
    }
}

const NeedleHit = struct { index: usize, len: usize };

fn nextLongestNeedle(source: []const u8, from: usize) ?NeedleHit {
    var best_idx: ?usize = null;
    var best_len: usize = 0;
    for (needles) |needle| {
        if (std.mem.indexOfPos(u8, source, from, needle)) |idx| {
            if (best_idx == null or idx < best_idx.? or (idx == best_idx.? and needle.len > best_len)) {
                best_idx = idx;
                best_len = needle.len;
            }
        }
    }
    const idx = best_idx orelse return null;
    return .{ .index = idx, .len = best_len };
}

fn insideTestBlock(source: []const u8, index: usize) bool {
    var i: usize = 0;
    while (i < index) : (i += 1) {
        if (!std.mem.startsWith(u8, source[i..], "test")) continue;
        if (i > 0) {
            const prev = source[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        var j = i + "test".len;
        if (j < source.len and (std.ascii.isAlphanumeric(source[j]) or source[j] == '_')) continue;
        while (j < source.len and std.ascii.isWhitespace(source[j])) : (j += 1) {}
        // `test "name" {` or `test {`
        if (j < source.len and source[j] == '"') {
            const endq = std.mem.indexOfScalarPos(u8, source, j + 1, '"') orelse continue;
            j = endq + 1;
            while (j < source.len and std.ascii.isWhitespace(source[j])) : (j += 1) {}
        }
        if (j >= source.len or source[j] != '{') continue;
        const close = scan.matchingBrace(source, j) orelse continue;
        if (index > j and index < close) return true;
        i = close;
    }
    return false;
}

test "page_allocator alloc is flagged; explicit allocator param use is not" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad() !void {
        \\    const p = try std.heap.page_allocator.alloc(u8, 1);
        \\    defer std.heap.page_allocator.free(p);
        \\}
    ;
    const pass_src =
        \\pub fn ok(allocator: anytype) !void {
        \\    const p = try allocator.alloc(u8, 1);
        \\    defer allocator.free(p);
        \\}
    ;
    const test_src =
        \\test {
        \\    const p = try std.heap.page_allocator.alloc(u8, 1);
        \\    defer std.heap.page_allocator.free(p);
        \\}
    ;
    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("fail.zig", fail_src, &fail_diags, gpa);
    try std.testing.expectEqual(@as(usize, 2), fail_diags.items.len);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("pass.zig", pass_src, &pass_diags, gpa);
    try std.testing.expect(pass_diags.items.len == 0);

    var test_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer test_diags.deinit(gpa);
    try analyzeSource("test.zig", test_src, &test_diags, gpa);
    try std.testing.expect(test_diags.items.len == 0);
}
