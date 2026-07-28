//! Shared local source scanning helpers for heuristic rules.

const std = @import("std");

pub const Func = struct {
    name: []u8,
    start: usize,
    end: usize,
};

pub fn findFunctions(gpa: std.mem.Allocator, source: []const u8) !std.ArrayList(Func) {
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
        try list.append(gpa, .{ .name = name, .start = brace, .end = end });
        i = end + 1;
    }
    return list;
}

pub fn freeFunctions(gpa: std.mem.Allocator, funcs: *std.ArrayList(Func)) void {
    for (funcs.items) |*f| gpa.free(f.name);
    funcs.deinit(gpa);
}

pub fn nextNeedle(body: []const u8, from: usize, needles: []const []const u8) ?usize {
    var best: ?usize = null;
    for (needles) |needle| {
        if (std.mem.indexOfPos(u8, body, from, needle)) |idx| {
            if (best == null or idx < best.?) best = idx;
        }
    }
    return best;
}

pub fn lineSlice(source: []const u8, index: usize) []const u8 {
    const line_start: usize = if (std.mem.lastIndexOfScalar(u8, source[0..index], '\n')) |nl| nl + 1 else 0;
    const end = std.mem.indexOfScalarPos(u8, source, index, '\n') orelse source.len;
    return source[line_start..end];
}

/// Previous full line before the line containing `index`, if any.
pub fn previousLineSlice(source: []const u8, index: usize) ?[]const u8 {
    const line_start: usize = if (std.mem.lastIndexOfScalar(u8, source[0..index], '\n')) |nl| nl + 1 else 0;
    if (line_start == 0) return null;
    const prev_end = line_start - 1; // the '\n'
    const prev_start: usize = if (std.mem.lastIndexOfScalar(u8, source[0..prev_end], '\n')) |nl| nl + 1 else 0;
    return source[prev_start..prev_end];
}

/// Next full line after the line containing `index`, if any.
pub fn nextLineSlice(source: []const u8, index: usize) ?[]const u8 {
    const end = std.mem.indexOfScalarPos(u8, source, index, '\n') orelse return null;
    if (end + 1 >= source.len) return null;
    const next_start = end + 1;
    const next_end = std.mem.indexOfScalarPos(u8, source, next_start, '\n') orelse source.len;
    return source[next_start..next_end];
}

pub fn lineNumber(source: []const u8, index: usize) u32 {
    var line: u32 = 1;
    var i: usize = 0;
    while (i < index and i < source.len) : (i += 1) {
        if (source[i] == '\n') line += 1;
    }
    return line;
}

pub fn columnNumber(source: []const u8, index: usize) u32 {
    var col: u32 = 1;
    var i: usize = index;
    while (i > 0) {
        i -= 1;
        if (source[i] == '\n') break;
        col += 1;
    }
    return col;
}

/// True when `index` sits on a line after a `//` comment marker (text-scan FP guard).
pub fn isInLineComment(source: []const u8, index: usize) bool {
    const line_start: usize = if (std.mem.lastIndexOfScalar(u8, source[0..index], '\n')) |nl| nl + 1 else 0;
    if (index < line_start) return false;
    return std.mem.indexOf(u8, source[line_start..index], "//") != null;
}

pub fn deferLineMentions(body: []const u8, words: []const []const u8) bool {
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        if (std.mem.startsWith(u8, body[i..], "errdefer") or std.mem.startsWith(u8, body[i..], "defer")) {
            const line_end = std.mem.indexOfScalarPos(u8, body, i, '\n') orelse body.len;
            const line = body[i..line_end];
            for (words) |w| {
                if (std.mem.indexOf(u8, line, w) != null) return true;
            }
        }
    }
    return false;
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
