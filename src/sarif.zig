//! SARIF 2.1.0 export (forge-oriented, deterministic).

const std = @import("std");
const schema = @import("schema.zig");
const diagnostic = @import("diagnostic.zig");
const json_out = @import("json_out.zig");

fn levelFor(sev: schema.Severity) []const u8 {
    return switch (sev) {
        .error_ => "error",
        .warning => "warning",
        .note => "note",
    };
}

fn ruleIndexFor(rule_id: []const u8) ?usize {
    for (schema.seed_rules, 0..) |rule, i| {
        if (std.mem.eql(u8, rule.id, rule_id)) return i;
    }
    return null;
}

fn writePrimaryLocationLineHash(
    writer: *std.Io.Writer,
    d: diagnostic.Diagnostic,
) std.Io.Writer.Error!void {
    var h = std.hash.Wyhash.init(0);
    h.update(d.rule_id);
    h.update("\x1f");
    h.update(d.location.path);
    h.update("\x1f");
    var line_buf: [16]u8 = undefined;
    const line_txt = std.fmt.bufPrint(&line_buf, "{d}", .{d.location.line}) catch unreachable;
    h.update(line_txt);
    h.update("\x1f");
    var col_buf: [16]u8 = undefined;
    const col_txt = std.fmt.bufPrint(&col_buf, "{d}", .{d.location.column}) catch unreachable;
    h.update(col_txt);
    const digest = h.final();
    try writer.print("\"{x}\"", .{digest});
}

pub fn writeRulesOnly(writer: *std.Io.Writer, myzig_version: []const u8) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.writeAll("  \"$schema\": \"https://json.schemastore.org/sarif-2.1.0.json\",\n");
    try writer.writeAll("  \"version\": \"2.1.0\",\n");
    try writer.writeAll("  \"runs\": [\n    {\n");
    try writeAutomationDetails(writer);
    try writer.writeAll("      \"tool\": {\n        \"driver\": {\n");
    try writer.writeAll("          \"name\": \"myzig\",\n");
    try writer.writeAll("          \"informationUri\": \"https://github.com/megaalive/myzig\",\n");
    try writer.writeAll("          \"version\": ");
    try json_out.writeString(writer, myzig_version);
    try writer.writeAll(",\n");
    try writer.writeAll("          \"rules\": [\n");
    try writeRuleDescriptors(writer);
    try writer.writeAll("          ]\n        }\n      },\n");
    try writer.writeAll("      \"results\": []\n");
    try writer.writeAll("    }\n  ]\n}\n");
}

pub fn writeRun(
    writer: *std.Io.Writer,
    myzig_version: []const u8,
    diags: []const diagnostic.Diagnostic,
) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.writeAll("  \"$schema\": \"https://json.schemastore.org/sarif-2.1.0.json\",\n");
    try writer.writeAll("  \"version\": \"2.1.0\",\n");
    try writer.writeAll("  \"runs\": [\n    {\n");
    try writeAutomationDetails(writer);
    try writer.writeAll("      \"tool\": {\n        \"driver\": {\n");
    try writer.writeAll("          \"name\": \"myzig\",\n");
    try writer.writeAll("          \"informationUri\": \"https://github.com/megaalive/myzig\",\n");
    try writer.writeAll("          \"version\": ");
    try json_out.writeString(writer, myzig_version);
    try writer.writeAll(",\n");
    try writer.writeAll("          \"rules\": [\n");
    try writeRuleDescriptors(writer);
    try writer.writeAll("          ]\n        }\n      },\n");
    try writer.writeAll("      \"results\": [\n");
    for (diags, 0..) |d, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("        {\n");
        try writer.writeAll("          \"ruleId\": ");
        try json_out.writeString(writer, d.rule_id);
        if (ruleIndexFor(d.rule_id)) |idx| {
            try writer.print(",\n          \"ruleIndex\": {d}", .{idx});
        }
        try writer.writeAll(",\n");
        try writer.writeAll("          \"level\": ");
        try json_out.writeString(writer, levelFor(d.severity));
        try writer.writeAll(",\n");
        try writer.writeAll("          \"message\": { \"text\": ");
        try json_out.writeString(writer, d.message);
        try writer.writeAll(" },\n");
        try writer.writeAll("          \"partialFingerprints\": {\n");
        try writer.writeAll("            \"primaryLocationLineHash\": ");
        try writePrimaryLocationLineHash(writer, d);
        try writer.writeAll("\n          },\n");
        try writer.writeAll("          \"properties\": {\n");
        try writer.writeAll("            \"certainty\": ");
        try json_out.writeString(writer, d.certainty.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("            \"obligation\": ");
        try json_out.writeString(writer, d.obligation.asText());
        try writer.writeAll("\n          },\n");
        try writer.writeAll("          \"locations\": [\n            {\n");
        try writer.writeAll("              \"physicalLocation\": {\n");
        try writer.writeAll("                \"artifactLocation\": { \"uri\": ");
        try json_out.writeString(writer, d.location.path);
        try writer.writeAll(" },\n");
        try writer.writeAll("                \"region\": {\n");
        try writer.print("                  \"startLine\": {d}", .{if (d.location.line == 0) 1 else d.location.line});
        if (d.location.column != 0) {
            try writer.print(",\n                  \"startColumn\": {d}", .{d.location.column});
        }
        try writer.writeAll("\n                }\n");
        try writer.writeAll("              }\n");
        try writer.writeAll("            }\n          ]\n");
        try writer.writeAll("        }");
    }
    if (diags.len > 0) try writer.writeAll("\n");
    try writer.writeAll("      ]\n");
    try writer.writeAll("    }\n  ]\n}\n");
}

fn writeAutomationDetails(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll("      \"automationDetails\": { \"id\": \"myzig/check\" },\n");
}

fn writeRuleDescriptors(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    for (schema.seed_rules, 0..) |rule, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("            {\n");
        try writer.writeAll("              \"id\": ");
        try json_out.writeString(writer, rule.id);
        try writer.writeAll(",\n");
        try writer.writeAll("              \"name\": ");
        try json_out.writeString(writer, rule.id);
        try writer.writeAll(",\n");
        try writer.writeAll("              \"shortDescription\": { \"text\": ");
        try json_out.writeString(writer, rule.message);
        try writer.writeAll(" },\n");
        try writer.writeAll("              \"fullDescription\": { \"text\": ");
        try json_out.writeString(writer, rule.explanation);
        try writer.writeAll(" },\n");
        try writer.writeAll("              \"helpUri\": \"https://github.com/megaalive/myzig/blob/master/docs/LIMITS.md\",\n");
        try writer.writeAll("              \"help\": { \"text\": ");
        try json_out.writeString(writer, rule.explanation);
        try writer.writeAll(" },\n");
        try writer.writeAll("              \"defaultConfiguration\": { \"level\": ");
        try json_out.writeString(writer, levelFor(rule.default_severity));
        try writer.writeAll(" },\n");
        try writer.writeAll("              \"properties\": {\n");
        try writer.writeAll("                \"certainty_ceiling\": ");
        try json_out.writeString(writer, rule.certainty_ceiling.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("                \"obligation\": ");
        try json_out.writeString(writer, rule.obligation.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("                \"tags\": [\"ownership\", \"myzig\"]\n");
        try writer.writeAll("              }\n");
        try writer.writeAll("            }");
    }
    if (schema.seed_rules.len > 0) try writer.writeAll("\n");
}

test "sarif rules export contains version and rule id" {
    var buf: [16384]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try writeRulesOnly(&w, "0.0.0");
    const out = buf[0..w.end];
    try std.testing.expect(std.mem.indexOf(u8, out, "\"version\": \"2.1.0\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "memory.alloc-undischarged") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "\"automationDetails\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "helpUri") != null);
}

test "sarif run includes ruleIndex and partialFingerprints" {
    var buf: [16384]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    const diags = [_]diagnostic.Diagnostic{
        diagnostic.Diagnostic.fromRule(
            schema.seed_alloc_undischarged,
            .likely,
            .{ .path = "fixtures/fail/alloc_undischarged.zig", .line = 12, .column = 5 },
            null,
        ),
    };
    try writeRun(&w, "0.0.0", &diags);
    const out = buf[0..w.end];
    try std.testing.expect(std.mem.indexOf(u8, out, "\"ruleIndex\": 0") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "primaryLocationLineHash") != null);
}
