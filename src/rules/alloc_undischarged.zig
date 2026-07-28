//! Heuristic local detector for `memory.alloc-undischarged`.
//!
//! This is intentionally not a full CFG/ZIR engine. It scans function bodies
//! for allocator-like acquires and looks for coarse discharge markers
//! (`defer`/`errdefer` free/destroy/deinit, or a returning acquire transfer).
//! Certainty stays at `likely` (rule ceiling).

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");

const acquire_needles = [_][]const u8{ ".alloc(", ".create(", ".dupe(" };

pub fn analyzeSource(
    path: []const u8,
    source: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    var funcs = try findFunctions(gpa, source);
    defer {
        for (funcs.items) |*f| gpa.free(f.name);
        funcs.deinit(gpa);
    }

    for (funcs.items) |func| {
        try analyzeFunction(path, source, func, out, gpa);
    }
}

const Func = struct {
    name: []u8,
    start: usize,
    end: usize,
};

fn findFunctions(gpa: std.mem.Allocator, source: []const u8) !std.ArrayList(Func) {
    var list: std.ArrayList(Func) = .empty;
    errdefer {
        for (list.items) |*f| gpa.free(f.name);
        list.deinit(gpa);
    }

    var i: usize = 0;
    while (i < source.len) {
        const rest = source[i..];
        const rel = std.mem.indexOf(u8, rest, "fn ") orelse break;
        const fn_pos = i + rel;
        const after_fn = fn_pos + 3;
        const name_start = skipSpace(source, after_fn);
        const name_end = identEnd(source, name_start);
        if (name_end == name_start) {
            i = after_fn;
            continue;
        }
        const brace = std.mem.indexOfScalarPos(u8, source, name_end, '{') orelse break;
        const end = matchingBrace(source, brace) orelse break;
        const name = try gpa.dupe(u8, source[name_start..name_end]);
        errdefer gpa.free(name);
        try list.append(gpa, .{
            .name = name,
            .start = brace,
            .end = end,
        });
        i = end + 1;
    }
    return list;
}

fn analyzeFunction(
    path: []const u8,
    source: []const u8,
    func: Func,
    out: *std.ArrayList(diagnostic.Diagnostic),
    gpa: std.mem.Allocator,
) !void {
    const body = source[func.start .. func.end + 1];
    const has_defer_discharge = containsDeferDischarge(body);

    var search_from: usize = 0;
    while (search_from < body.len) {
        const hit = nextAcquire(body, search_from) orelse break;
        const abs_index = func.start + hit;
        const line = lineNumber(source, abs_index);
        const column = columnNumber(source, abs_index);
        const line_slice = lineSlice(source, abs_index);

        const discharged = isReturnTransferLine(line_slice) or has_defer_discharge;
        if (!discharged) {
            const d = diagnostic.Diagnostic.fromRule(
                schema.seed_alloc_undischarged,
                .likely,
                .{ .path = path, .line = line, .column = column },
                null,
            );
            try out.append(gpa, d);
        }

        search_from = hit + 1;
    }
}

fn nextAcquire(body: []const u8, from: usize) ?usize {
    var best: ?usize = null;
    for (acquire_needles) |needle| {
        if (std.mem.indexOfPos(u8, body, from, needle)) |idx| {
            if (best == null or idx < best.?) best = idx;
        }
    }
    return best;
}

fn containsDeferDischarge(body: []const u8) bool {
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        if (std.mem.startsWith(u8, body[i..], "errdefer") or std.mem.startsWith(u8, body[i..], "defer")) {
            const line_end = std.mem.indexOfScalarPos(u8, body, i, '\n') orelse body.len;
            const line = body[i..line_end];
            if (std.mem.indexOf(u8, line, "free") != null or
                std.mem.indexOf(u8, line, "destroy") != null or
                std.mem.indexOf(u8, line, "deinit") != null)
            {
                return true;
            }
        }
    }
    return false;
}

fn isReturnTransferLine(line: []const u8) bool {
    if (std.mem.indexOf(u8, line, "return") == null) return false;
    for (acquire_needles) |needle| {
        if (std.mem.indexOf(u8, line, needle) != null) return true;
    }
    return false;
}

fn lineSlice(source: []const u8, index: usize) []const u8 {
    const line_start: usize = if (std.mem.lastIndexOfScalar(u8, source[0..index], '\n')) |nl| nl + 1 else 0;
    const end = std.mem.indexOfScalarPos(u8, source, index, '\n') orelse source.len;
    return source[line_start..end];
}

fn lineNumber(source: []const u8, index: usize) u32 {
    var line: u32 = 1;
    var i: usize = 0;
    while (i < index and i < source.len) : (i += 1) {
        if (source[i] == '\n') line += 1;
    }
    return line;
}

fn columnNumber(source: []const u8, index: usize) u32 {
    var col: u32 = 1;
    var i: usize = index;
    while (i > 0) {
        i -= 1;
        if (source[i] == '\n') break;
        col += 1;
    }
    return col;
}

fn skipSpace(source: []const u8, start: usize) usize {
    var i = start;
    while (i < source.len and std.ascii.isWhitespace(source[i])) : (i += 1) {}
    return i;
}

fn identEnd(source: []const u8, start: usize) usize {
    var i = start;
    while (i < source.len) : (i += 1) {
        const c = source[i];
        if (!(std.ascii.isAlphanumeric(c) or c == '_')) break;
    }
    return i;
}

fn matchingBrace(source: []const u8, open: usize) ?usize {
    if (open >= source.len or source[open] != '{') return null;
    var depth: i32 = 0;
    var i = open;
    while (i < source.len) : (i += 1) {
        const c = source[i];
        if (c == '{') depth += 1;
        if (c == '}') {
            depth -= 1;
            if (depth == 0) return i;
        }
    }
    return null;
}

test "leaky local alloc is flagged; defer free and return-transfer are not" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn leaky(allocator: anytype, n: usize) !usize {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    return buffer.len;
        \\}
    ;
    const pass_src =
        \\pub fn ok(allocator: anytype, n: usize) !void {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    defer allocator.free(buffer);
        \\    _ = buffer;
        \\}
    ;
    const transfer_src =
        \\pub fn give(allocator: anytype, n: usize) ![]u8 {
        \\    return try allocator.alloc(u8, n);
        \\}
    ;

    var fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer fail_diags.deinit(gpa);
    try analyzeSource("fail.zig", fail_src, &fail_diags, gpa);
    try std.testing.expect(fail_diags.items.len >= 1);
    try std.testing.expectEqualStrings("memory.alloc-undischarged", fail_diags.items[0].rule_id);

    var pass_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer pass_diags.deinit(gpa);
    try analyzeSource("pass.zig", pass_src, &pass_diags, gpa);
    try std.testing.expect(pass_diags.items.len == 0);

    var transfer_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer transfer_diags.deinit(gpa);
    try analyzeSource("transfer.zig", transfer_src, &transfer_diags, gpa);
    try std.testing.expect(transfer_diags.items.len == 0);
}
