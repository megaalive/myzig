//! Emitted findings. Certainty is always clamped to the rule's ceiling.

const std = @import("std");
const schema = @import("schema.zig");

pub const Location = struct {
    path: []const u8,
    /// 1-based line; 0 means unknown.
    line: u32 = 0,
    /// 1-based column; 0 means unknown.
    column: u32 = 0,

    pub fn formatText(self: Location, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        if (self.line == 0) {
            try writer.print("{s}", .{self.path});
            return;
        }
        if (self.column == 0) {
            try writer.print("{s}:{d}", .{ self.path, self.line });
            return;
        }
        try writer.print("{s}:{d}:{d}", .{ self.path, self.line, self.column });
    }
};

pub const Diagnostic = struct {
    rule_id: []const u8,
    severity: schema.Severity,
    certainty: schema.Certainty,
    obligation: schema.ObligationKind,
    message: []const u8,
    location: Location,

    /// Build a finding from a rule, clamping certainty to the rule ceiling.
    pub fn fromRule(
        rule: schema.Rule,
        claim: schema.Certainty,
        location: Location,
        message_override: ?[]const u8,
    ) Diagnostic {
        return .{
            .rule_id = rule.id,
            .severity = rule.default_severity,
            .certainty = rule.clampCertainty(claim),
            .obligation = rule.obligation,
            .message = message_override orelse rule.message,
            .location = location,
        };
    }

    pub fn writeText(self: Diagnostic, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try self.location.formatText(writer);
        try writer.print(": {s}: {s} [{s}] ({s})\n", .{
            self.severity.asText(),
            self.message,
            self.rule_id,
            self.certainty.asText(),
        });
    }
};

test "fromRule clamps proven to likely for seed rule" {
    const d = Diagnostic.fromRule(
        schema.seed_alloc_undischarged,
        .proven,
        .{ .path = "fixtures/fail/alloc_undischarged.zig", .line = 12, .column = 5 },
        null,
    );
    try std.testing.expect(d.certainty == .likely);
    try std.testing.expectEqualStrings("memory.alloc-undischarged", d.rule_id);
}

test "location formats with and without column" {
    var buf: [128]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);

    const loc: Location = .{ .path = "a.zig", .line = 3, .column = 7 };
    try loc.formatText(&w);
    try std.testing.expectEqualStrings("a.zig:3:7", buf[0..w.end]);
}
