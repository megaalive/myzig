//! Heuristic local detector for `memory.alloc-undischarged`.

const std = @import("std");
const schema = @import("../schema.zig");
const diagnostic = @import("../diagnostic.zig");
const scan = @import("../scan.zig");

const acquire_needles = [_][]const u8{
    ".allocPrintZ(",
    ".allocPrint(",
    ".alignedAlloc(",
    ".dupeSentinel(",
    ".dupeZ(",
    ".realloc(",
    "mem.concat(",
    "mem.join(",
    ".alloc(",
    ".create(",
    ".dupe(",
};
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
            const hit_in_body = hit; // relative to body
            const transferred = isReturnTransferLine(line_slice) or
                isOutParamAcquireLine(line_slice) or
                isCollectionTransferLine(line_slice) or
                acquireInReturnedStructLiteral(body, hit_in_body) or
                (binding != null and bodyTransfersBinding(body, binding.?));
            const released = binding != null and bodyReleasesBindingTree(body, binding.?);
            const discharged = transferred or released or has_defer_discharge;
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

fn isOutParamAcquireLine(line: []const u8) bool {
    // `out.* = try allocator.alloc(...)` — ownership handed to caller via pointer.
    if (std.mem.indexOf(u8, line, ".*") == null) return false;
    if (std.mem.indexOf(u8, line, "=") == null) return false;
    for (acquire_needles) |needle| {
        if (std.mem.indexOf(u8, line, needle) != null) return true;
    }
    return false;
}

fn isCollectionTransferLine(line: []const u8) bool {
    // `try list.append(try allocator.dupe(...))` — ownership moves into the collection.
    const markers = [_][]const u8{ ".append(", ".appendSlice(" };
    var has_append = false;
    for (markers) |m| {
        if (std.mem.indexOf(u8, line, m) != null) {
            has_append = true;
            break;
        }
    }
    if (!has_append) return false;
    for (acquire_needles) |needle| {
        if (std.mem.indexOf(u8, line, needle) != null) return true;
    }
    return false;
}

/// Acquires used as field initializers inside `return .{ ... }` transfer to the caller.
fn acquireInReturnedStructLiteral(body: []const u8, rel_index: usize) bool {
    var i: usize = 0;
    while (i < rel_index) : (i += 1) {
        if (!std.mem.startsWith(u8, body[i..], "return")) continue;
        if (i > 0) {
            const prev = body[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        var j = i + "return".len;
        if (j < body.len and (std.ascii.isAlphanumeric(body[j]) or body[j] == '_')) continue;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (!std.mem.startsWith(u8, body[j..], ".{")) continue;
        const open = j + 1;
        const close = scan.matchingBrace(body, open) orelse continue;
        if (rel_index > open and rel_index < close) return true;
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
    if (!isIdent(name)) return null;
    return name;
}

fn isIdent(name: []const u8) bool {
    if (name.len == 0) return false;
    if (!std.ascii.isAlphabetic(name[0]) and name[0] != '_') return false;
    for (name[1..]) |c| {
        if (!std.ascii.isAlphanumeric(c) and c != '_') return false;
    }
    return true;
}

fn bodyTransfersBinding(body: []const u8, name: []const u8) bool {
    var names: [8][]const u8 = undefined;
    const n = collectAliasClosure(body, name, &names);
    for (names[0..n]) |id| {
        if (bodyReturnsBinding(body, id)) return true;
        if (bodyAssignsBindingToOutParam(body, id)) return true;
        if (bindingUsedInReturnedStructField(body, id)) return true;
        if (bindingConsumedByCollectionCall(body, id)) return true;
    }
    return false;
}

fn bindingConsumedByCollectionCall(body: []const u8, name: []const u8) bool {
    // Multi-line: `const data = try dupe; try list.append(..., .{ .data = data });`
    const markers = [_][]const u8{ ".append(", ".appendSlice(" };
    for (markers) |marker| {
        var from: usize = 0;
        while (from < body.len) {
            const idx = std.mem.indexOfPos(u8, body, from, marker) orelse break;
            const open = idx + marker.len - 1; // '('
            const close = scan.matchingParen(body, open) orelse {
                from = idx + 1;
                continue;
            };
            const args = body[open + 1 .. close];
            if (identAppearsInSpan(args, name)) return true;
            from = close + 1;
        }
    }
    return false;
}

fn identAppearsInSpan(span: []const u8, name: []const u8) bool {
    var i: usize = 0;
    while (i < span.len) : (i += 1) {
        if (!std.mem.startsWith(u8, span[i..], name)) continue;
        if (i > 0) {
            const prev = span[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        const end = i + name.len;
        if (end < span.len) {
            const next = span[end];
            if (next == '.' or next == '[') continue;
            if (std.ascii.isAlphanumeric(next) or next == '_') continue;
        }
        return true;
    }
    return false;
}

fn bindingUsedInReturnedStructField(body: []const u8, name: []const u8) bool {
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
        if (!std.mem.startsWith(u8, body[j..], ".{")) continue;
        const open = j + 1;
        const close = scan.matchingBrace(body, open) orelse continue;
        const span = body[open .. close + 1];
        if (identAssignedInSpan(span, name)) return true;
    }
    return false;
}

fn identAssignedInSpan(span: []const u8, name: []const u8) bool {
    var i: usize = 0;
    while (i < span.len) : (i += 1) {
        if (span[i] != '=') continue;
        if (i + 1 < span.len and (span[i + 1] == '=' or span[i + 1] == '>')) continue;
        if (i > 0 and (span[i - 1] == '!' or span[i - 1] == '<' or span[i - 1] == '>' or span[i - 1] == '=')) continue;
        var j = i + 1;
        while (j < span.len and std.ascii.isWhitespace(span[j])) : (j += 1) {}
        if (!std.mem.startsWith(u8, span[j..], name)) continue;
        const end = j + name.len;
        if (end < span.len) {
            const next = span[end];
            if (next == '.' or next == '[' or std.ascii.isAlphanumeric(next) or next == '_') continue;
        }
        return true;
    }
    return false;
}

fn bodyReleasesBindingTree(body: []const u8, name: []const u8) bool {
    var names: [8][]const u8 = undefined;
    const n = collectAliasClosure(body, name, &names);
    for (names[0..n]) |id| {
        if (bodyReleasesBinding(body, id)) return true;
    }
    return false;
}

fn bodyReleasesBinding(body: []const u8, name: []const u8) bool {
    // `.free(name)` / `.destroy(name)` — including under `defer` / `errdefer`.
    const call_needles = [_][]const u8{ ".free(", ".destroy(" };
    for (call_needles) |needle| {
        var i: usize = 0;
        while (i < body.len) : (i += 1) {
            if (!std.mem.startsWith(u8, body[i..], needle)) continue;
            var j = i + needle.len;
            while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
            if (!std.mem.startsWith(u8, body[j..], name)) continue;
            const end = j + name.len;
            if (end < body.len) {
                const next = body[end];
                if (std.ascii.isAlphanumeric(next) or next == '_') continue;
            }
            return true;
        }
    }
    // `name.deinit(` for `create`-style objects.
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        if (!std.mem.startsWith(u8, body[i..], name)) continue;
        if (i > 0) {
            const prev = body[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') continue;
        }
        var j = i + name.len;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (!std.mem.startsWith(u8, body[j..], ".deinit(")) continue;
        return true;
    }
    return false;
}

fn collectAliasClosure(body: []const u8, root: []const u8, out: *[8][]const u8) usize {
    out[0] = root;
    var n: usize = 1;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var hop: [8][]const u8 = undefined;
        const hn = collectOneHopAliases(body, out[i], &hop);
        for (hop[0..hn]) |alias| {
            if (!aliasListContains(out[0..n], alias)) {
                if (n >= out.len) return n;
                out[n] = alias;
                n += 1;
            }
        }
        var assigns: [8][]const u8 = undefined;
        const an = collectAssignmentAliases(body, out[i], &assigns);
        for (assigns[0..an]) |alias| {
            if (!aliasListContains(out[0..n], alias)) {
                if (n >= out.len) return n;
                out[n] = alias;
                n += 1;
            }
        }
    }
    return n;
}

fn aliasListContains(list: []const []const u8, name: []const u8) bool {
    for (list) |existing| {
        if (std.mem.eql(u8, existing, name)) return true;
    }
    return false;
}

/// `out = next;` — ownership retarget (exact RHS ident).
fn collectAssignmentAliases(body: []const u8, name: []const u8, out: *[8][]const u8) usize {
    var n: usize = 0;
    var i: usize = 0;
    while (i < body.len and n < out.len) : (i += 1) {
        if (body[i] != '=') continue;
        if (i + 1 < body.len and (body[i + 1] == '=' or body[i + 1] == '>')) continue;
        if (i > 0 and (body[i - 1] == '!' or body[i - 1] == '<' or body[i - 1] == '>' or body[i - 1] == '=')) continue;

        // LHS ident immediately before `=`
        var lhs_end = i;
        while (lhs_end > 0 and std.ascii.isWhitespace(body[lhs_end - 1])) : (lhs_end -= 1) {}
        var lhs_start = lhs_end;
        while (lhs_start > 0) {
            const c = body[lhs_start - 1];
            if (std.ascii.isAlphanumeric(c) or c == '_') {
                lhs_start -= 1;
                continue;
            }
            break;
        }
        if (lhs_start == lhs_end) continue;
        const lhs = body[lhs_start..lhs_end];
        if (!isIdent(lhs)) continue;
        // Avoid matching `.field = name` as a new owning binding name starting with field —
        // still OK: field store is not a local binding transfer via return of field.
        // Skip if LHS is preceded by `.`
        if (lhs_start > 0 and body[lhs_start - 1] == '.') continue;

        var j = i + 1;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (!std.mem.startsWith(u8, body[j..], name)) continue;
        const end = j + name.len;
        if (end < body.len) {
            const next = body[end];
            if (next == '.' or next == '[' or std.ascii.isAlphanumeric(next) or next == '_') continue;
        }
        out[n] = lhs;
        n += 1;
    }
    return n;
}

fn collectOneHopAliases(body: []const u8, name: []const u8, out: *[8][]const u8) usize {
    var n: usize = 0;
    var i: usize = 0;
    while (i < body.len and n < out.len) {
        const rest = body[i..];
        const kw_len: usize = if (std.mem.startsWith(u8, rest, "const "))
            "const ".len
        else if (std.mem.startsWith(u8, rest, "var "))
            "var ".len
        else {
            i += 1;
            continue;
        };
        if (i > 0) {
            const prev = body[i - 1];
            if (std.ascii.isAlphanumeric(prev) or prev == '_') {
                i += 1;
                continue;
            }
        }

        var j = i + kw_len;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        const name_start = j;
        const name_end = identEnd(body, name_start);
        if (name_end == name_start) {
            i += 1;
            continue;
        }
        const alias = body[name_start..name_end];
        j = name_end;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (j < body.len and body[j] == ':') {
            j += 1;
            while (j < body.len and body[j] != '=' and body[j] != ';' and body[j] != '\n') : (j += 1) {}
        }
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (j >= body.len or body[j] != '=') {
            i += 1;
            continue;
        }
        j += 1;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (!std.mem.startsWith(u8, body[j..], name)) {
            i += 1;
            continue;
        }
        const after = j + name.len;
        if (after < body.len) {
            const next = body[after];
            // Reject `const alias = buffer.len` / `buffer[0]` / `buffer_more`.
            if (next == '.' or next == '[' or std.ascii.isAlphanumeric(next) or next == '_') {
                i += 1;
                continue;
            }
        }
        out[n] = alias;
        n += 1;
        i = after;
    }
    return n;
}

fn identEnd(source: []const u8, start: usize) usize {
    var i = start;
    while (i < source.len) : (i += 1) {
        const c = source[i];
        if (!std.ascii.isAlphanumeric(c) and c != '_') break;
    }
    return i;
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

fn bodyAssignsBindingToOutParam(body: []const u8, name: []const u8) bool {
    // `out.* = buffer;` / `dest.* = buffer`
    var i: usize = 0;
    while (i < body.len) : (i += 1) {
        if (!std.mem.startsWith(u8, body[i..], ".*")) continue;
        var j = i + ".*".len;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (j >= body.len or body[j] != '=') continue;
        j += 1;
        while (j < body.len and std.ascii.isWhitespace(body[j])) : (j += 1) {}
        if (!std.mem.startsWith(u8, body[j..], name)) continue;
        const end = j + name.len;
        if (end < body.len) {
            const next = body[end];
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
    const alias_transfer_src =
        \\pub fn giveAlias(allocator: anytype, n: usize) ![]u8 {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    const owned = buffer;
        \\    return owned;
        \\}
    ;
    const out_param_src =
        \\pub fn fill(allocator: anytype, n: usize, out: *[]u8) !void {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    out.* = buffer;
        \\}
    ;
    const out_param_direct_src =
        \\pub fn fillDirect(allocator: anytype, n: usize, out: *[]u8) !void {
        \\    out.* = try allocator.alloc(u8, n);
        \\}
    ;
    const explicit_free_src =
        \\pub fn freeNow(allocator: anytype, n: usize) !void {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    allocator.free(buffer);
        \\}
    ;
    const alias_free_src =
        \\pub fn freeAlias(allocator: anytype, n: usize) !void {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    const owned = buffer;
        \\    allocator.free(owned);
        \\}
    ;
    const multi_hop_src =
        \\pub fn giveChain(allocator: anytype, n: usize) ![]u8 {
        \\    const buffer = try allocator.alloc(u8, n);
        \\    const mid = buffer;
        \\    const owned = mid;
        \\    return owned;
        \\}
    ;
    const alloc_print_fail_src =
        \\pub fn leakyPrint(allocator: anytype) !usize {
        \\    const msg = try std.fmt.allocPrint(allocator, "n={d}", .{1});
        \\    return msg.len;
        \\}
    ;
    const alloc_print_ok_src =
        \\pub fn okPrint(allocator: anytype) ![]u8 {
        \\    return try std.fmt.allocPrint(allocator, "n={d}", .{1});
        \\}
    ;
    const append_transfer_src =
        \\pub fn collect(allocator: anytype, list: anytype, s: []const u8) !void {
        \\    try list.append(try allocator.dupe(u8, s));
        \\}
    ;
    const concat_fail_src =
        \\pub fn leakyJoin(allocator: anytype) !usize {
        \\    const s = try std.mem.concat(allocator, u8, &.{ "a", "b" });
        \\    return s.len;
        \\}
    ;
    const struct_return_src =
        \\pub fn buat(allocator: anytype, s: []const u8) !struct { id: []u8 } {
        \\    return .{
        \\        .id = try allocator.dupe(u8, s),
        \\    };
        \\}
    ;
    const struct_binding_src =
        \\pub fn buatList(allocator: anytype, n: usize) !struct { pesan: []u8 } {
        \\    const daftar = try allocator.alloc(u8, n);
        \\    return .{
        \\        .pesan = daftar,
        \\    };
        \\}
    ;
    const append_multiline_src =
        \\pub fn addItem(allocator: anytype, list: anytype, src: []const u8) !void {
        \\    const data = try allocator.dupe(u8, src);
        \\    try list.append(allocator, .{ .data = data });
        \\}
    ;
    const retarget_src =
        \\pub fn trimCopy(allocator: anytype, teks: []const u8) ![]u8 {
        \\    var out = try allocator.dupe(u8, teks);
        \\    const next = try allocator.dupe(u8, teks[1..]);
        \\    allocator.free(out);
        \\    out = next;
        \\    return out;
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

    var alias_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer alias_diags.deinit(gpa);
    try analyzeSource("alias.zig", alias_transfer_src, &alias_diags, gpa);
    try std.testing.expect(alias_diags.items.len == 0);

    var out_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer out_diags.deinit(gpa);
    try analyzeSource("out.zig", out_param_src, &out_diags, gpa);
    try std.testing.expect(out_diags.items.len == 0);

    var out_direct_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer out_direct_diags.deinit(gpa);
    try analyzeSource("out_direct.zig", out_param_direct_src, &out_direct_diags, gpa);
    try std.testing.expect(out_direct_diags.items.len == 0);

    var free_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer free_diags.deinit(gpa);
    try analyzeSource("free.zig", explicit_free_src, &free_diags, gpa);
    try std.testing.expect(free_diags.items.len == 0);

    var alias_free_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer alias_free_diags.deinit(gpa);
    try analyzeSource("alias_free.zig", alias_free_src, &alias_free_diags, gpa);
    try std.testing.expect(alias_free_diags.items.len == 0);

    var multi_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer multi_diags.deinit(gpa);
    try analyzeSource("multi.zig", multi_hop_src, &multi_diags, gpa);
    try std.testing.expect(multi_diags.items.len == 0);

    var print_fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer print_fail_diags.deinit(gpa);
    try analyzeSource("print_fail.zig", alloc_print_fail_src, &print_fail_diags, gpa);
    try std.testing.expect(print_fail_diags.items.len >= 1);

    var print_ok_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer print_ok_diags.deinit(gpa);
    try analyzeSource("print_ok.zig", alloc_print_ok_src, &print_ok_diags, gpa);
    try std.testing.expect(print_ok_diags.items.len == 0);

    var append_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer append_diags.deinit(gpa);
    try analyzeSource("append.zig", append_transfer_src, &append_diags, gpa);
    try std.testing.expect(append_diags.items.len == 0);

    var concat_fail_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer concat_fail_diags.deinit(gpa);
    try analyzeSource("concat_fail.zig", concat_fail_src, &concat_fail_diags, gpa);
    try std.testing.expect(concat_fail_diags.items.len >= 1);

    var struct_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer struct_diags.deinit(gpa);
    try analyzeSource("struct.zig", struct_return_src, &struct_diags, gpa);
    try std.testing.expect(struct_diags.items.len == 0);

    var struct_bind_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer struct_bind_diags.deinit(gpa);
    try analyzeSource("struct_bind.zig", struct_binding_src, &struct_bind_diags, gpa);
    try std.testing.expect(struct_bind_diags.items.len == 0);

    var append_multi_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer append_multi_diags.deinit(gpa);
    try analyzeSource("append_multi.zig", append_multiline_src, &append_multi_diags, gpa);
    try std.testing.expect(append_multi_diags.items.len == 0);

    var retarget_diags: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer retarget_diags.deinit(gpa);
    try analyzeSource("retarget.zig", retarget_src, &retarget_diags, gpa);
    try std.testing.expect(retarget_diags.items.len == 0);

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
