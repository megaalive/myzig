//! SARIF 2.1.0 export (minimal, deterministic).

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

pub fn writeRulesOnly(writer: *std.Io.Writer, myzig_version: []const u8) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.writeAll("  \"$schema\": \"https://json.schemastore.org/sarif-2.1.0.json\",\n");
    try writer.writeAll("  \"version\": \"2.1.0\",\n");
    try writer.writeAll("  \"runs\": [\n    {\n");
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
        try writer.writeAll(",\n");
        try writer.writeAll("          \"level\": ");
        try json_out.writeString(writer, levelFor(d.severity));
        try writer.writeAll(",\n");
        try writer.writeAll("          \"message\": { \"text\": ");
        try json_out.writeString(writer, d.message);
        try writer.writeAll(" },\n");
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

fn writeRuleDescriptors(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    for (schema.seed_rules, 0..) |rule, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("            {\n");
        try writer.writeAll("              \"id\": ");
        try json_out.writeString(writer, rule.id);
        try writer.writeAll(",\n");
        try writer.writeAll("              \"shortDescription\": { \"text\": ");
        try json_out.writeString(writer, rule.message);
        try writer.writeAll(" },\n");
        try writer.writeAll("              \"fullDescription\": { \"text\": ");
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
        try writer.writeAll("\n              }\n");
        try writer.writeAll("            }");
    }
    if (schema.seed_rules.len > 0) try writer.writeAll("\n");
}

test "sarif rules export contains version and rule id" {
    var buf: [8192]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try writeRulesOnly(&w, "0.0.0");
    const out = buf[0..w.end];
    try std.testing.expect(std.mem.indexOf(u8, out, "\"version\": \"2.1.0\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "memory.alloc-undischarged") != null);
}
