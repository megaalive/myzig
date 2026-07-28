//! Heuristic local detector for `memory.alloc-undischarged`.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

const acquire_needles = [_][]const u8{ ".alloc(", ".create(", ".dupe(" };
const discharge_words = [_][]const u8{ "free", "destroy", "deinit" };

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
        const has_defer_discharge = scan.deferLineMentions(body, &discharge_words);

        var search_from: usize = 0;
        while (search_from < body.len) {
            const hit = scan.nextNeedle(body, search_from, &acquire_needles) orelse break;
            const abs_index = func.start + hit;
            if (scan.isInLineComment(source, abs_index)) {
                search_from = hit + 1;
                continue;
            }
            const line_slice = scan.lineSlice(source, abs_index);
            const binding = bindingNameFromAcquireLine(line_slice);
            const transferred = isReturnTransferLine(line_slice) or
                (binding != null and bodyReturnsBinding(body, binding.?));
            const discharged = transferred or has_defer_discharge;
            if (!discharged) {
                try out.append(gpa, diagnostic.Diagnostic.fromRule(
                    schema.seed_alloc_undischarged,
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

fn isReturnTransferLine(line: []const u8) bool {
    if (std.mem.indexOf(u8, line, "return") == null) return false;
    for (acquire_needles) |needle| {
        if (std.mem.indexOf(u8, line, needle) != null) return true;
    }
    return false;
}

fn bindingNameFromAcquireLine(line: []const u8) ?[]const u8 {
    var rest = std.mem.trim(u8, line, " \t");
    if (std.mem.startsWith(u8, rest, "const ")) {
        rest = std.mem.trimStart(u8, rest["const ".len..], " \t");
    } else if (std.mem.startsWith(u8, rest, "var ")) {
        rest = std.mem.trimStart(u8, rest["var ".len..], " \t");
    } else return null;

    const eq = std.mem.indexOfScalar(u8, rest, '=') orelse return null;
    var name = std.mem.trim(u8, rest[0..eq], " \t");
    if (std.mem.indexOfScalar(u8, name, ':')) |colon| {
        name = std.mem.trim(u8, name[0..colon], " \t");
    }
    if (name.len == 0) return null;
    if (!std.ascii.isAlphabetic(name[0]) and name[0] != '_') return null;
    for (name[1..]) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_') return null;
    }
    return name;
}

fn bodyReturnsBinding(body: []const u8, name: []const u8) bool {
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        if (!std.mem.startsWith(u8, body[i..], "return")) continue;
        if (i > 0) {
            const prev = body[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        var j = i + "return".len;
        if (j < body.len and (std.ascii.isAlphanumeric(body[j]) or body[j] == '_')) continue;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (!std.mem.startsWith(u8, body[j..], name)) continue;
        const end = j + name.len;
        if (end < body.len) {
            const next = body[end];
            // `return buffer.len` / `return buffer[0]` are not ownership transfers.
            if (next == '.' or next == '[') continue;
            if (std.ascii.isAlphanumeric(next) or next == '_') continue;
        }
        return true;
    }
    return false;
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
    const local_transfer_src =
        \\pub fn giveLocal(allocator: anytype, n: usize) ![]u8 {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    return buffer;
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

    var transfer_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer transfer_diags.deinit(gpa);
    try analyzeSource("transfer.zig", transfer_src, &transfer_diags, gpa);
    try std.testing.expect(transfer_diags.items.len == 0);

    var local_transfer_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer local_transfer_diags.deinit(gpa);
    try analyzeSource("local_transfer.zig", local_transfer_src, &local_transfer_diags, gpa);
    try std.testing.expect(local_transfer_diags.items.len == 0);

    const comment_src =
        \\pub fn documented() void {
        \\    // example only: allocator.alloc(u8, 1) would leak without defer
        \\}
    ;
    var comment_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer comment_diags.deinit(gpa);
    try analyzeSource("comment.zig", comment_src, &comment_diags, gpa);
    try std.testing.expect(comment_diags.items.len == 0);
}
