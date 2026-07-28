//! Inline suppressions via disable comments.
//!
//! Supported:
//! - `// myzig-disable-next-line [rule_id…]`
//! - `// myzig-disable-current-line [rule_id…]` (also trailing on the same line)

const std = @import("std");
const diagnostic = @import("diagnostic.zig");

pub fn filterSuppressed(
    source: []const u8,
    diags: *std.ArrayList(diagnostic.Diagnostic),
) void {
    var i: usize = 0;
    while (i < diags.items.len) {
        if (isSuppressed(source, diags.items[i])) {
            _ = diags.orderedRemove(i);
            continue;
        }
        i += 1;
    }
}

fn isSuppressed(source: []const u8, d: diagnostic.Diagnostic) bool {
    const line_no = if (d.location.line == 0) 1 else d.location.line;
    const curr = lineText(source, line_no) orelse return false;
    if (lineDisables(curr, d.rule_id)) return true;
    if (line_no > 1) {
        const prev = lineText(source, line_no - 1) orelse return false;
        if (lineDisablesNext(prev, d.rule_id)) return true;
    }
    return false;
}

fn lineDisables(line: []const u8, rule_id: []const u8) bool {
    const marker = "myzig-disable-current-line";
    const at = std.mem.indexOf(u8, line, marker) orelse return false;
    return markerApplies(line[at + marker.len ..], rule_id);
}

fn lineDisablesNext(line: []const u8, rule_id: []const u8) bool {
    const marker = "myzig-disable-next-line";
    const at = std.mem.indexOf(u8, line, marker) orelse return false;
    return markerApplies(line[at + marker.len ..], rule_id);
}

fn markerApplies(after: []const u8, rule_id: []const u8) bool {
    var rest = std.mem.trim(u8, after, " \t");
    // Drop trailing rationale after ` - `
    if (std.mem.indexOf(u8, rest, " - ")) |dash| {
        rest = std.mem.trim(u8, rest[0..dash], " \t");
    }
    if (rest.len == 0) return true; // disable all rules
    var it = std.mem.tokenizeAny(u8, rest, " \t");
    while (it.next()) |tok| {
        if (std.mem.eql(u8, tok, rule_id)) return true;
    }
    return false;
}

fn lineText(source: []const u8, line_no: u32) ?[]const u8 {
    var line: u32 = 1;
    var start: usize = 0;
    var i: usize = 0;
    while (i < source.len) : (i += 1) {
        if (source[i] == '\n') {
            if (line == line_no) return source[start..i];
            line += 1;
            start = i + 1;
        }
    }
    if (line == line_no) return source[start..];
    return null;
}

test "disable-next-line suppresses matching rule" {
    const src =
        \\// myzig-disable-next-line lifecycle.empty-defer - stub ok
        \\defer {}
    ;
    var list: std.ArrayList(diagnostic.Diagnostic) = .empty;
    defer list.deinit(std.testing.allocator);
    try list.append(std.testing.allocator, .{
        .rule_id = "lifecycle.empty-defer",
        .severity = .note,
        .certainty = .convention,
        .obligation = .other,
        .message = "empty defer block does no cleanup",
        .location = .{ .path = "t.zig", .line = 2, .column = 1 },
    });
    filterSuppressed(src, &list);
    try std.testing.expect(list.items.len == 0);
}
