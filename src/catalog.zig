//! Rule catalog export helpers (text / json / markdown / agent).

const std = @import("std");
const schema = @import("schema.zig");

pub const Format = enum {
    text,
    json,
    markdown,
    agent,
    sarif,

    pub fn parse(flag: []const u8) ?Format {
        if (std.mem.eql(u8, flag, "--json") or std.mem.eql(u8, flag, "json")) return .json;
        if (std.mem.eql(u8, flag, "--markdown") or std.mem.eql(u8, flag, "markdown") or std.mem.eql(u8, flag, "--md"))
            return .markdown;
        if (std.mem.eql(u8, flag, "--agent") or std.mem.eql(u8, flag, "agent")) return .agent;
        if (std.mem.eql(u8, flag, "--sarif") or std.mem.eql(u8, flag, "sarif")) return .sarif;
        if (std.mem.eql(u8, flag, "--text") or std.mem.eql(u8, flag, "text")) return .text;
        return null;
    }
};

pub fn write(writer: *std.Io.Writer, format: Format) std.Io.Writer.Error!void {
    switch (format) {
        .text => try writeText(writer),
        .json => try writeJson(writer),
        .markdown => try writeMarkdown(writer),
        .agent => try writeAgent(writer),
        .sarif => try writer.writeAll("{\"version\":\"2.1.0\",\"runs\":[],\"$comment\":\"SARIF export lands with M1+\"}\n"),
    }
}

pub fn writeText(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    for (schema.seed_rules) |rule| {
        try writer.print("{s}\n", .{rule.id});
        try writer.print("  category:   {s}\n", .{rule.category.asText()});
        try writer.print("  severity:   {s}\n", .{rule.default_severity.asText()});
        try writer.print("  ceiling:    {s}\n", .{rule.certainty_ceiling.asText()});
        try writer.print("  obligation: {s}\n", .{rule.obligation.asText()});
        try writer.print("  detector:   {s}\n", .{rule.detector.asText()});
        try writer.print("  message:    {s}\n", .{rule.message});
        try writer.writeAll("\n");
    }
}

pub fn writeJson(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll("{\n  \"schema_version\": \"0.0.0\",\n  \"rules\": [\n");
    for (schema.seed_rules, 0..) |rule, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("    {\n");
        try writer.print("      \"id\": \"{s}\",\n", .{rule.id});
        try writer.print("      \"category\": \"{s}\",\n", .{rule.category.asText()});
        try writer.print("      \"default_severity\": \"{s}\",\n", .{rule.default_severity.asText()});
        try writer.print("      \"certainty_ceiling\": \"{s}\",\n", .{rule.certainty_ceiling.asText()});
        try writer.print("      \"obligation\": \"{s}\",\n", .{rule.obligation.asText()});
        try writer.print("      \"detector\": \"{s}\",\n", .{rule.detector.asText()});
        try writer.print("      \"message\": \"{s}\",\n", .{rule.message});
        try writer.writeAll("      \"discharges\": [");
        for (rule.discharges, 0..) |d, di| {
            if (di > 0) try writer.writeAll(", ");
            try writer.print("\"{s}\"", .{d.asText()});
        }
        try writer.writeAll("],\n");
        try writer.writeAll("      \"repairs\": [\n");
        for (rule.repairs, 0..) |r, ri| {
            if (ri > 0) try writer.writeAll(",\n");
            try writer.print(
                "        {{\"tier\": \"{s}\", \"intent\": \"{s}\", \"summary\": \"{s}\"}}",
                .{ r.tier.asText(), r.intent, r.summary },
            );
        }
        try writer.writeAll("\n      ],\n");
        try writer.writeAll("      \"references\": [");
        for (rule.references, 0..) |ref, ri| {
            if (ri > 0) try writer.writeAll(", ");
            try writer.print("\"{s}\"", .{ref});
        }
        try writer.writeAll("]\n    }");
    }
    try writer.writeAll("\n  ]\n}\n");
}

pub fn writeMarkdown(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll("# myzig rules\n\n");
    for (schema.seed_rules) |rule| {
        try writer.print("## `{s}`\n\n", .{rule.id});
        try writer.print("- **category:** {s}\n", .{rule.category.asText()});
        try writer.print("- **severity:** {s}\n", .{rule.default_severity.asText()});
        try writer.print("- **certainty_ceiling:** {s}\n", .{rule.certainty_ceiling.asText()});
        try writer.print("- **obligation:** {s}\n", .{rule.obligation.asText()});
        try writer.print("- **detector:** {s}\n\n", .{rule.detector.asText()});
        try writer.print("{s}\n\n", .{rule.message});
        try writer.writeAll("### Repairs\n\n");
        for (rule.repairs) |r| {
            try writer.print("- `{s}` / `{s}` — {s}\n", .{ r.tier.asText(), r.intent, r.summary });
        }
        try writer.writeAll("\n");
    }
}

pub fn writeAgent(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll("# myzig agent rule card\n\n");
    try writer.writeAll("When fixing Zig ownership issues, prefer these structured choices.\n");
    try writer.writeAll("Do not invent ownership policy; pick an intent from repairs.\n");
    try writer.writeAll("Never claim `proven` above a rule's certainty_ceiling.\n");
    try writer.writeAll("CLI exits: 0=ok, 1=findings/error, 2=usage — no stack traces for those.\n");
    try writer.writeAll("For std fs/env/time insulation, prefer `myzig.compat` and `check --prefer-compat`.\n");
    try writer.writeAll("Living tips (update as text, not always as code): run `myzig friction`.\n");
    try writer.writeAll("Repair cards: `myzig explain <file:line> --json` or `--agent`.\n\n");
    for (schema.seed_rules) |rule| {
        try writer.print("## {s}\n", .{rule.id});
        try writer.print("ceiling: {s}\n", .{rule.certainty_ceiling.asText()});
        try writer.print("obligation: {s}\n", .{rule.obligation.asText()});
        try writer.print("message: {s}\n", .{rule.message});
        try writer.writeAll("repairs:\n");
        for (rule.repairs) |r| {
            try writer.print("- [{s}] intent={s}: {s}\n", .{ r.tier.asText(), r.intent, r.summary });
        }
        try writer.writeAll("\n");
    }
}

test "parse format flags" {
    try std.testing.expect(Format.parse("--json") == .json);
    try std.testing.expect(Format.parse("--markdown") == .markdown);
    try std.testing.expect(Format.parse("--agent") == .agent);
    try std.testing.expect(Format.parse("--nope") == null);
}
