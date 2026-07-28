//! CLI dispatch stubs. Behavior grows with M0/M1; commands are reserved now.

const std = @import("std");
const schema = @import("schema.zig");

pub const Command = enum {
    help,
    version,
    check,
    explain,
    adopt,
    baseline,
    rules,
    receipt,
    verify_cost,
    init,
    unknown,

    pub fn parse(name: []const u8) Command {
        if (std.mem.eql(u8, name, "help") or std.mem.eql(u8, name, "--help") or std.mem.eql(u8, name, "-h"))
            return .help;
        if (std.mem.eql(u8, name, "version") or std.mem.eql(u8, name, "--version") or std.mem.eql(u8, name, "-V"))
            return .version;
        if (std.mem.eql(u8, name, "check")) return .check;
        if (std.mem.eql(u8, name, "explain")) return .explain;
        if (std.mem.eql(u8, name, "adopt")) return .adopt;
        if (std.mem.eql(u8, name, "baseline")) return .baseline;
        if (std.mem.eql(u8, name, "rules")) return .rules;
        if (std.mem.eql(u8, name, "receipt")) return .receipt;
        if (std.mem.eql(u8, name, "verify-cost")) return .verify_cost;
        if (std.mem.eql(u8, name, "init")) return .init;
        return .unknown;
    }
};

pub fn writeHelp(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll(
        \\myzig — ownership reasoning and evidence protocol for Zig
        \\
        \\Usage:
        \\  myzig <command> [args]
        \\
        \\Commands:
        \\  check [path]              Run ownership checks (stub)
        \\  explain <file:line>       Ownership narrative for a finding (stub)
        \\  adopt [path]              Suggest editable migration policy (stub)
        \\  baseline                  Snapshot current safety debt (stub)
        \\  rules [--json|--markdown|--agent|--sarif]
        \\                            List rule catalog
        \\  receipt [path]            Emit or verify a receipt (stub)
        \\  verify-cost <case>        Leveled ReleaseFast cost witness (stub)
        \\  init                      Create .myzig/ project config (stub)
        \\  help                      Show this help
        \\  version                   Show version
        \\
        \\Identity: deterministic · honest · auditable
        \\
    );
}

pub fn writeVersion(writer: *std.Io.Writer, version: []const u8) std.Io.Writer.Error!void {
    try writer.print("myzig {s}\n", .{version});
}

pub fn writeRulesText(writer: *std.Io.Writer) std.Io.Writer.Error!void {
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

pub fn stubMessage(command: Command) []const u8 {
    return switch (command) {
        .check => "check: analyzer not implemented yet (M1).",
        .explain => "explain: ownership narratives land with M1/M5.",
        .adopt => "adopt: policy synthesizer not implemented yet (M3).",
        .baseline => "baseline: snapshot/ratchet not implemented yet (M3).",
        .receipt => "receipt: reproducible receipts not implemented yet (M4).",
        .verify_cost => "verify-cost: leveled witnesses not implemented yet (M6).",
        .init => "init: will create .myzig/ when project config lands.",
        .help, .version, .rules, .unknown => "",
    };
}

test "parse known commands" {
    try std.testing.expect(Command.parse("check") == .check);
    try std.testing.expect(Command.parse("verify-cost") == .verify_cost);
    try std.testing.expect(Command.parse("--help") == .help);
    try std.testing.expect(Command.parse("nope") == .unknown);
}
