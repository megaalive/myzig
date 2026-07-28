//! Thin reproducible receipt for `myzig check` / `myzig receipt`.

const std = @import("std");
const diagnostic = @import("diagnostic.zig");

pub const Receipt = struct {
    myzig_version: []const u8,
    compat_adapter: []const u8,
    path: []const u8,
    findings: usize,
    diagnostics: []const diagnostic.Diagnostic,
};

pub fn writeJson(writer: *std.Io.Writer, r: Receipt) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.print("  \"myzig_version\": \"{s}\",\n", .{r.myzig_version});
    try writer.print("  \"compat_adapter\": \"{s}\",\n", .{r.compat_adapter});
    try writer.print("  \"path\": \"{s}\",\n", .{r.path});
    try writer.writeAll("  \"observed\": {\n");
    try writer.print("    \"findings\": {d},\n", .{r.findings});
    try writer.writeAll("    \"diagnostics\": [\n");
    for (r.diagnostics, 0..) |d, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("      {\n");
        try writer.print("        \"rule_id\": \"{s}\",\n", .{d.rule_id});
        try writer.print("        \"severity\": \"{s}\",\n", .{d.severity.asText()});
        try writer.print("        \"certainty\": \"{s}\",\n", .{d.certainty.asText()});
        try writer.print("        \"obligation\": \"{s}\",\n", .{d.obligation.asText()});
        try writer.print("        \"message\": \"{s}\",\n", .{d.message});
        try writer.print("        \"path\": \"{s}\",\n", .{d.location.path});
        try writer.print("        \"line\": {d},\n", .{d.location.line});
        try writer.print("        \"column\": {d}\n", .{d.location.column});
        try writer.writeAll("      }");
    }
    try writer.writeAll("\n    ]\n");
    try writer.writeAll("  },\n");
    try writer.writeAll("  \"claimed\": {}\n");
    try writer.writeAll("}\n");
}

test "receipt json contains observed findings" {
    var buf: [512]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    const diags = [_]diagnostic.Diagnostic{.{
        .rule_id = "memory.alloc-undischarged",
        .severity = .warning,
        .certainty = .likely,
        .obligation = .memory_must_release_or_transfer,
        .message = "test",
        .location = .{ .path = "a.zig", .line = 1, .column = 1 },
    }};
    try writeJson(&w, .{
        .myzig_version = "0.0.0",
        .compat_adapter = "zig_0_17",
        .path = "a.zig",
        .findings = 1,
        .diagnostics = &diags,
    });
    try std.testing.expect(std.mem.indexOf(u8, buf[0..w.end], "\"findings\": 1") != null);
}
