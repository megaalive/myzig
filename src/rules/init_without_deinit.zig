//! Convention: `init` without a matching `deinit` on the same binding.
//! Resource-shaped constructors often need explicit teardown.

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
    var funcs = try scan.findFunctions(gpa, source);
    defer scan.freeFunctions(gpa, &funcs);

    for (funcs.items) |func| {
        const body = source[func.start .. func.end + 1];
        var search_from: usize = 0;
        while (search_from < body.len) {
            const hit = nextInitAssign(body, search_from) orelse break;
            const abs_index = func.start + hit.index;
            if (scan.isInLineComment(source, abs_index)) {
                search_from = hit.index + 1;
                continue;
            }
            if (bodyHasDeinit(body, hit.name) or bodyTransfersName(body, hit.name)) {
                search_from = hit.index + hit.name.len;
                continue;
            }
            try out.append(gpa, diagnostic.Diagnostic.fromRule(
                schema.seed_init_without_deinit,
                .convention,
                .{
                    .path = path,
                    .line = scan.lineNumber(source, abs_index),
                    .column = scan.columnNumber(source, abs_index),
                },
                null,
            ));
            search_from = hit.index + hit.name.len;
        }
    }
}

const InitHit = struct { index: usize, name: []const u8 };

fn nextInitAssign(body: []const u8, from: usize) ?InitHit {
    var i = from;
    while (i < body.len) : (i += 1) {
        const is_var = std.mem.startsWith(u8, body[i..], "var ");
        const is_const = std.mem.startsWith(u8, body[i..], "const ");
        if (!is_var and !is_const) continue;
        if (i > 0) {
            const prev = body[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        var j = i + if (is_var) "var ".len else "const ".len;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        const name_start = j;
        while (j < body.len and (std.ascii.isAlphanumeric(body[j]) or body[j] == '_')) : (j += 1) {}
        if (j == name_start) continue;
        const name = body[name_start..j];
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        // Optional `: Type`
        if (j < body.len and body[j] == ':') {
            j += 1;
            while (j < body.len and body[j] != '=') : (j += 1) {}
        }
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (j >= body.len or body[j] != '=') continue;
        j += 1;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        // Resource-shaped constructors usually error (`try X.init`); skip bare `.init(`.
        if (!std.mem.startsWith(u8, body[j..], "try ")) continue;
        j += "try ".len;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        const line_end = std.mem.indexOfScalarPos(u8, body, j, '\n') orelse body.len;
        const stmt = body[j..line_end];
        const init_at = std.mem.indexOf(u8, stmt, ".init(") orelse continue;
        if (std.mem.indexOf(u8, stmt, ".initCapacity(") != null) continue;
        if (std.mem.indexOf(u8, stmt, ".initEmpty(") != null) continue;
        // Bare `.init(` (inferred) is often a non-resource wrapper (writers, etc.).
        var k = init_at;
        while (k > 0 and (std.ascii.isAlphanumeric(stmt[k - 1]) or stmt[k - 1] == '_' or stmt[k - 1] == '.')) : (k -= 1) {}
        if (k == init_at) continue;
        return .{ .index = name_start, .name = name };
    }
    return null;
}

fn bodyHasDeinit(body: []const u8, name: []const u8) bool {
    // `name.deinit` or `defer name.deinit` / `errdefer name.deinit`
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        if (!std.mem.startsWith(u8, body[i..], name)) continue;
        if (i > 0) {
            const prev = body[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        var j = i + name.len;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (std.mem.startsWith(u8, body[j..], ".deinit")) return true;
    }
    return false;
}

fn bodyTransfersName(body: []const u8, name: []const u8) bool {
    // `return name;` / `return name,` / field store with name on RHS of return struct — V0: return token.
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
        if (std.mem.startsWith(u8, body[j..], name)) {
            const end = j + name.len;
            if (end >= body.len or (!std.ascii.isAlphanumeric(body[end]) and body[end] != '_')) return true;
        }
    }
    return false;
}

test "init without deinit flagged; defer deinit and return transfer are not" {
    const gpa = std.testing.allocator;
    const fail_src =
        \\pub fn bad() !void {
        \\    var loop = try Loop.init(.{});
        \\    _ = loop;
        \\}
    ;
    const pass_src =
        \\pub fn ok() !void {
        \\    var loop = try Loop.init(.{});
        \\    defer loop.deinit();
        \\}
    ;
    const transfer_src =
        \\pub fn give() !Loop {
        \\    const loop = try Loop.init(.{});
        \\    return loop;
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
}
