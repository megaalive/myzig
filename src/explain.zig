//! `myzig explain` — ownership narrative for a location or rule id.

const std = @import("std");
const schema = @import("schema.zig");
const check_mod = @import("check.zig");
const compat = @import("compat.zig");
const diagnostic = @import("diagnostic.zig");

pub const Target = struct {
    path: []const u8,
    line: u32,
    column: u32 = 0,
};

pub fn parseTarget(spec: []const u8) !Target {
    // Formats: path:line  or  path:line:column (relative/unix-style paths).
    const last_colon = std.mem.lastIndexOfScalar(u8, spec, ':') orelse return error.Usage;
    const after = spec[last_colon + 1 ..];
    const column_or_line = std.fmt.parseInt(u32, after, 10) catch return error.Usage;

    const head = spec[0..last_colon];
    if (std.mem.lastIndexOfScalar(u8, head, ':')) |prev| {
        const maybe_line = head[prev + 1 ..];
        if (std.fmt.parseInt(u32, maybe_line, 10)) |line| {
            return .{
                .path = head[0..prev],
                .line = line,
                .column = column_or_line,
            };
        } else |_| {}
    }

    return .{ .path = head, .line = column_or_line };
}

pub fn findRule(id: []const u8) ?schema.Rule {
    for (schema.seed_rules) |r| {
        if (std.mem.eql(u8, r.id, id)) return r;
    }
    return null;
}

pub fn writeRuleExplain(writer: *std.Io.Writer, rule: schema.Rule) std.Io.Writer.Error!void {
    try writer.print("rule: {s}\n", .{rule.id});
    try writer.print("category: {s}\n", .{rule.category.asText()});
    try writer.print("severity: {s}\n", .{rule.default_severity.asText()});
    try writer.print("certainty_ceiling: {s}\n", .{rule.certainty_ceiling.asText()});
    try writer.print("obligation: {s}\n", .{rule.obligation.asText()});
    try writer.print("detector: {s}\n\n", .{rule.detector.asText()});
    try writer.print("{s}\n\n", .{rule.explanation});
    try writer.writeAll("repairs (choose an intent; do not invent ownership policy):\n");
    for (rule.repairs) |r| {
        try writer.print("  - [{s}] intent={s}: {s}\n", .{ r.tier.asText(), r.intent, r.summary });
    }
    if (rule.references.len > 0) {
        try writer.writeAll("\nreferences:\n");
        for (rule.references) |ref| try writer.print("  - {s}\n", .{ref});
    }
}

pub fn explainLocation(
    io: compat.Io,
    gpa: std.mem.Allocator,
    target: Target,
    writer: *std.Io.Writer,
) !void {
    var result = try check_mod.checkPath(io, gpa, target.path);
    defer result.deinit(gpa);

    var matched: ?diagnostic.Diagnostic = null;
    for (result.diagnostics.items) |d| {
        if (d.location.line != target.line) continue;
        if (target.column != 0 and d.location.column != 0 and d.location.column != target.column) continue;
        matched = d;
        break;
    }

    if (matched) |d| {
        try writer.writeAll("finding:\n  ");
        try d.writeText(writer);
        try writer.writeAll("\n");
        const rule = findRule(d.rule_id) orelse {
            try writer.print("no catalog entry for rule {s}\n", .{d.rule_id});
            return;
        };
        try writeRuleExplain(writer, rule);
        return;
    }

    try writer.print(
        "no finding at {s}:{d}\nre-run: myzig check {s}\n",
        .{ target.path, target.line, target.path },
    );
}

test "parseTarget file:line:column" {
    const t = try parseTarget("fixtures/fail/alloc_undischarged.zig:11:33");
    try std.testing.expectEqualStrings("fixtures/fail/alloc_undischarged.zig", t.path);
    try std.testing.expect(t.line == 11);
    try std.testing.expect(t.column == 33);
}
