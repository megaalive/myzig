//! `myzig explain` — ownership narrative + structured repair choices.

const std = @import("std");
const schema = @import("schema.zig");
const check_mod = @import("check.zig");
const compat = @import("compat.zig");
const diagnostic = @import("diagnostic.zig");
const json_out = @import("json_out.zig");

pub const Target = struct {
    path: []const u8,
    line: u32,
    column: u32 = 0,
};

pub const Format = enum {
    text,
    json,
    agent,

    pub fn parse(flag: []const u8) ?Format {
        if (std.mem.eql(u8, flag, "--json") or std.mem.eql(u8, flag, "json")) return .json;
        if (std.mem.eql(u8, flag, "--agent") or std.mem.eql(u8, flag, "agent")) return .agent;
        if (std.mem.eql(u8, flag, "--text") or std.mem.eql(u8, flag, "text")) return .text;
        return null;
    }
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

fn writePolicyBanner(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll(
        \\policy: choose a listed repair intent — do not invent ownership policy
        \\certainty: never claim proven above this rule's certainty_ceiling
        \\
    );
}

fn writeRepairCards(writer: *std.Io.Writer, rule: schema.Rule) std.Io.Writer.Error!void {
    try writer.writeAll("repair_choices:\n");
    for (rule.repairs, 0..) |r, i| {
        try writer.print("  [{d}] tier={s} intent={s}\n", .{ i + 1, r.tier.asText(), r.intent });
        try writer.print("      summary: {s}\n", .{r.summary});
        try writer.print("      automatic: {}\n", .{r.tier == .automatic});
    }
    try writer.writeAll(
        \\
        \\next_steps:
        \\  1. pick one intent from repair_choices
        \\  2. apply that repair in source
        \\  3. myzig check <path>
        \\  4. myzig receipt <path>
        \\
    );
}

pub fn writeRuleExplain(writer: *std.Io.Writer, rule: schema.Rule) std.Io.Writer.Error!void {
    try writePolicyBanner(writer);
    try writer.print("rule: {s}\n", .{rule.id});
    try writer.print("category: {s}\n", .{rule.category.asText()});
    try writer.print("severity: {s}\n", .{rule.default_severity.asText()});
    try writer.print("certainty_ceiling: {s}\n", .{rule.certainty_ceiling.asText()});
    try writer.print("obligation: {s}\n", .{rule.obligation.asText()});
    try writer.print("detector: {s}\n\n", .{rule.detector.asText()});
    try writer.print("{s}\n\n", .{rule.explanation});
    try writeRepairCards(writer, rule);
    if (rule.references.len > 0) {
        try writer.writeAll("references:\n");
        for (rule.references) |ref| try writer.print("  - {s}\n", .{ref});
    }
}

pub fn writeRuleExplainAgent(writer: *std.Io.Writer, rule: schema.Rule) std.Io.Writer.Error!void {
    try writer.writeAll("# myzig explain (agent)\n\n");
    try writer.writeAll("Choose exactly one repair intent below. Do not invent policy.\n");
    try writer.print("Never claim certainty above `{s}`.\n\n", .{rule.certainty_ceiling.asText()});
    try writer.print("## {s}\n", .{rule.id});
    try writer.print("obligation: {s}\n", .{rule.obligation.asText()});
    try writer.print("ceiling: {s}\n\n", .{rule.certainty_ceiling.asText()});
    try writer.print("{s}\n\n", .{rule.explanation});
    try writer.writeAll("## Repair intents\n\n");
    for (rule.repairs) |r| {
        try writer.print("- intent=`{s}` tier=`{s}` auto={}: {s}\n", .{
            r.intent,
            r.tier.asText(),
            r.tier == .automatic,
            r.summary,
        });
    }
    try writer.writeAll("\n## Loop\n\n`check` → pick intent → edit → `check` → `receipt`\n");
}

pub fn writeRuleExplainJson(writer: *std.Io.Writer, rule: schema.Rule, finding: ?diagnostic.Diagnostic) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.writeAll("  \"schema_version\": \"0.0.0\",\n");
    try writer.writeAll("  \"policy\": \"choose_listed_intent_only\",\n");
    try writer.writeAll("  \"rule\": {\n");
    try writer.writeAll("    \"id\": ");
    try json_out.writeString(writer, rule.id);
    try writer.writeAll(",\n");
    try writer.writeAll("    \"category\": ");
    try json_out.writeString(writer, rule.category.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"severity\": ");
    try json_out.writeString(writer, rule.default_severity.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"certainty_ceiling\": ");
    try json_out.writeString(writer, rule.certainty_ceiling.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"obligation\": ");
    try json_out.writeString(writer, rule.obligation.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"detector\": ");
    try json_out.writeString(writer, rule.detector.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"message\": ");
    try json_out.writeString(writer, rule.message);
    try writer.writeAll(",\n");
    try writer.writeAll("    \"explanation\": ");
    try json_out.writeString(writer, rule.explanation);
    try writer.writeAll("\n  },\n");
    if (finding) |d| {
        try writer.writeAll("  \"finding\": {\n");
        try writer.writeAll("    \"rule_id\": ");
        try json_out.writeString(writer, d.rule_id);
        try writer.writeAll(",\n");
        try writer.writeAll("    \"severity\": ");
        try json_out.writeString(writer, d.severity.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("    \"certainty\": ");
        try json_out.writeString(writer, d.certainty.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("    \"path\": ");
        try json_out.writeString(writer, d.location.path);
        try writer.writeAll(",\n");
        try writer.print("    \"line\": {d},\n", .{d.location.line});
        try writer.print("    \"column\": {d},\n", .{d.location.column});
        try writer.writeAll("    \"message\": ");
        try json_out.writeString(writer, d.message);
        try writer.writeAll("\n  },\n");
    } else {
        try writer.writeAll("  \"finding\": null,\n");
    }
    try writer.writeAll("  \"repair_choices\": [\n");
    for (rule.repairs, 0..) |r, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("    {\n");
        try writer.print("      \"index\": {d},\n", .{i + 1});
        try writer.writeAll("      \"tier\": ");
        try json_out.writeString(writer, r.tier.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("      \"intent\": ");
        try json_out.writeString(writer, r.intent);
        try writer.writeAll(",\n");
        try writer.writeAll("      \"summary\": ");
        try json_out.writeString(writer, r.summary);
        try writer.writeAll(",\n");
        try writer.print("      \"automatic\": {}\n", .{r.tier == .automatic});
        try writer.writeAll("    }");
    }
    if (rule.repairs.len > 0) try writer.writeAll("\n");
    try writer.writeAll("  ],\n");
    try writer.writeAll("  \"next_steps\": [\n");
    try writer.writeAll("    \"pick_one_intent\",\n");
    try writer.writeAll("    \"apply_repair\",\n");
    try writer.writeAll("    \"myzig check\",\n");
    try writer.writeAll("    \"myzig receipt\"\n");
    try writer.writeAll("  ]\n");
    try writer.writeAll("}\n");
}

fn writeNearby(
    writer: *std.Io.Writer,
    diags: []const diagnostic.Diagnostic,
    target_line: u32,
) std.Io.Writer.Error!void {
    var shown: usize = 0;
    for (diags) |d| {
        if (d.location.line == 0) continue;
        const dist = if (d.location.line > target_line)
            d.location.line - target_line
        else
            target_line - d.location.line;
        if (dist > 20) continue;
        if (shown == 0) try writer.writeAll("nearby_findings:\n");
        try writer.writeAll("  ");
        try d.writeText(writer);
        shown += 1;
        if (shown >= 5) break;
    }
}

pub fn explainLocation(
    io: compat.Io,
    gpa: std.mem.Allocator,
    target: Target,
    writer: *std.Io.Writer,
    format: Format,
) !void {
    const prefer_compat = check_mod.preferCompatMarker(io);
    var result = try check_mod.checkPathOptions(io, gpa, target.path, .{
        .prefer_compat = prefer_compat,
    });
    defer result.deinit(gpa);

    var matched: ?diagnostic.Diagnostic = null;
    for (result.diagnostics.items) |d| {
        if (d.location.line != target.line) continue;
        if (target.column != 0 and d.location.column != 0 and d.location.column != target.column) continue;
        matched = d;
        break;
    }

    if (matched) |d| {
        const rule = findRule(d.rule_id) orelse {
            try writer.print("no catalog entry for rule {s}\n", .{d.rule_id});
            return;
        };
        switch (format) {
            .text => {
                try writer.writeAll("finding:\n  ");
                try d.writeText(writer);
                try writer.writeAll("\n");
                try writeRuleExplain(writer, rule);
            },
            .agent => {
                try writer.writeAll("finding:\n  ");
                try d.writeText(writer);
                try writer.writeAll("\n");
                try writeRuleExplainAgent(writer, rule);
            },
            .json => try writeRuleExplainJson(writer, rule, d),
        }
        return;
    }

    switch (format) {
        .json => {
            try writer.writeAll("{\n");
            try writer.writeAll("  \"finding\": null,\n");
            try writer.writeAll("  \"path\": ");
            try json_out.writeString(writer, target.path);
            try writer.writeAll(",\n");
            try writer.print("  \"line\": {d},\n", .{target.line});
            try writer.writeAll("  \"hint\": \"re-run myzig check; see nearby_findings if present\"\n");
            try writer.writeAll("}\n");
        },
        else => {
            try writer.print(
                "no finding at {s}:{d}\nre-run: myzig check {s}\n",
                .{ target.path, target.line, target.path },
            );
            try writeNearby(writer, result.diagnostics.items, target.line);
        },
    }
}

pub fn explainRule(
    rule: schema.Rule,
    writer: *std.Io.Writer,
    format: Format,
) std.Io.Writer.Error!void {
    switch (format) {
        .text => try writeRuleExplain(writer, rule),
        .agent => try writeRuleExplainAgent(writer, rule),
        .json => try writeRuleExplainJson(writer, rule, null),
    }
}

test "parseTarget file:line:column" {
    const t = try parseTarget("fixtures/fail/alloc_undischarged.zig:11:33");
    try std.testing.expectEqualStrings("fixtures/fail/alloc_undischarged.zig", t.path);
    try std.testing.expect(t.line == 11);
    try std.testing.expect(t.column == 33);
}

test "format flags" {
    try std.testing.expect(Format.parse("--json") == .json);
    try std.testing.expect(Format.parse("--agent") == .agent);
    try std.testing.expect(Format.parse("--nope") == null);
}
