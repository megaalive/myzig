//! CLI dispatch for myzig coach commands.

const std = @import("std");
const catalog = @import("catalog.zig");
const check_mod = @import("check.zig");
const compat = @import("compat.zig");
const explain_mod = @import("explain.zig");
const receipt_mod = @import("receipt.zig");

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

pub const RunIo = struct {
    allocator: std.mem.Allocator,
    io: compat.Io,
    stdout: *std.Io.Writer,
    stderr: *std.Io.Writer,
    version: []const u8,
};

pub fn writeHelp(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll(
        \\myzig — ownership reasoning and evidence protocol for Zig
        \\
        \\Usage:
        \\  myzig <command> [args]
        \\
        \\Commands:
        \\  check [path] [--receipt]  Run ownership checks
        \\  explain <file:line>       Ownership narrative + repair choices
        \\  explain --rule <id>       Explain a catalog rule
        \\  adopt [path]              Suggest editable migration policy (stub → M3)
        \\  baseline                  Snapshot current safety debt (stub → M3)
        \\  rules [--json|--markdown|--agent|--sarif]
        \\                            List rule catalog
        \\  receipt [path]            Emit thin check receipt (JSON)
        \\  verify-cost <case>        Leveled ReleaseFast cost witness (stub → M6)
        \\  init                      Create .myzig/ project config
        \\  help                      Show this help
        \\  version                   Show version
        \\
        \\Identity: deterministic · honest · auditable
        \\
    );
}

pub fn writeVersion(writer: *std.Io.Writer, version: []const u8) std.Io.Writer.Error!void {
    try writer.print("myzig {s}\n", .{version});
    try writer.print("compat {s}\n", .{compat.adapterName()});
}

pub fn stubMessage(command: Command) []const u8 {
    return switch (command) {
        .adopt => "adopt: policy synthesizer not implemented yet (M3).",
        .baseline => "baseline: snapshot/ratchet not implemented yet (M3).",
        .verify_cost => "verify-cost: leveled witnesses not implemented yet (M6).",
        else => "",
    };
}

pub fn dispatch(rio: RunIo, argv: []const []const u8) !void {
    const command: Command = if (argv.len == 0) .help else Command.parse(argv[0]);
    const rest = if (argv.len == 0) argv else argv[1..];

    switch (command) {
        .help => try writeHelp(rio.stdout),
        .version => try writeVersion(rio.stdout, rio.version),
        .rules => {
            var format: catalog.Format = .text;
            for (rest) |a| {
                format = catalog.Format.parse(a) orelse {
                    try rio.stderr.print("myzig rules: unknown flag '{s}'\n", .{a});
                    return error.Usage;
                };
            }
            try catalog.write(rio.stdout, format);
        },
        .check => {
            var path: []const u8 = ".";
            var want_receipt = false;
            for (rest) |a| {
                if (std.mem.eql(u8, a, "--receipt")) {
                    want_receipt = true;
                } else if (std.mem.startsWith(u8, a, "-")) {
                    try rio.stderr.print("myzig check: unknown flag '{s}'\n", .{a});
                    return error.Usage;
                } else {
                    path = a;
                }
            }
            var result = try check_mod.checkPath(rio.io, rio.allocator, path);
            defer result.deinit(rio.allocator);
            if (want_receipt) {
                try receipt_mod.writeJson(rio.stdout, .{
                    .myzig_version = rio.version,
                    .compat_adapter = compat.adapterName(),
                    .path = path,
                    .findings = result.diagnostics.items.len,
                    .diagnostics = result.diagnostics.items,
                });
            } else {
                try check_mod.writeReport(rio.stdout, result.diagnostics.items);
            }
            if (result.diagnostics.items.len > 0) return error.Findings;
        },
        .receipt => {
            const path = if (rest.len >= 1) rest[0] else ".";
            var result = try check_mod.checkPath(rio.io, rio.allocator, path);
            defer result.deinit(rio.allocator);
            try receipt_mod.writeJson(rio.stdout, .{
                .myzig_version = rio.version,
                .compat_adapter = compat.adapterName(),
                .path = path,
                .findings = result.diagnostics.items.len,
                .diagnostics = result.diagnostics.items,
            });
            if (result.diagnostics.items.len > 0) return error.Findings;
        },
        .explain => {
            if (rest.len >= 2 and std.mem.eql(u8, rest[0], "--rule")) {
                const rule = explain_mod.findRule(rest[1]) orelse {
                    try rio.stderr.print("myzig explain: unknown rule '{s}'\n", .{rest[1]});
                    return error.Usage;
                };
                try explain_mod.writeRuleExplain(rio.stdout, rule);
                return;
            }
            if (rest.len < 1) return error.Usage;
            const target = try explain_mod.parseTarget(rest[0]);
            try explain_mod.explainLocation(rio.io, rio.allocator, target, rio.stdout);
        },
        .init => {
            try compat.createDirPath(rio.io, ".myzig");
            const readme =
                \\# myzig project config
                \\
                \\Policy, baselines, and local overrides will live here.
                \\Ordinary Zig remains first-class; this directory is optional evidence/config.
                \\
            ;
            try compat.writeFile(rio.io, ".myzig/README.md", readme);
            try rio.stdout.writeAll("created .myzig/\n");
        },
        .unknown => {
            try rio.stderr.print("myzig: unknown command '{s}'\n\n", .{argv[0]});
            try writeHelp(rio.stderr);
            return error.UnknownCommand;
        },
        else => {
            try rio.stdout.print("{s}\n", .{stubMessage(command)});
        },
    }
}

test "parse known commands" {
    try std.testing.expect(Command.parse("check") == .check);
    try std.testing.expect(Command.parse("explain") == .explain);
    try std.testing.expect(Command.parse("receipt") == .receipt);
    try std.testing.expect(Command.parse("verify-cost") == .verify_cost);
}
