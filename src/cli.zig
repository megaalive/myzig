//! CLI dispatch for myzig coach commands.

const std = @import("std");
const catalog = @import("catalog.zig");
const check_mod = @import("check.zig");
const compat = @import("compat.zig");
const explain_mod = @import("explain.zig");
const friction_mod = @import("friction.zig");
const receipt_mod = @import("receipt.zig");
const baseline_mod = @import("baseline.zig");
const adopt_mod = @import("adopt.zig");

pub const Command = enum {
    help,
    version,
    check,
    explain,
    adopt,
    baseline,
    rules,
    receipt,
    friction,
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
        if (std.mem.eql(u8, name, "friction")) return .friction;
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
        \\  check [path] [--receipt] [--prefer-compat] [--ratchet]
        \\                            Run ownership checks (optional debt ratchet)
        \\  explain <file:line>       Ownership narrative + repair choices
        \\  explain --rule <id>       Explain a catalog rule
        \\  adopt [path]              Suggest editable policy + baseline if missing
        \\  baseline [path]           Snapshot current findings for ratchet
        \\  rules [--json|--markdown|--agent|--sarif]
        \\                            List rule catalog
        \\  receipt [path]            Emit thin check receipt (JSON)
        \\  friction [--sources]      Living text playbook (update without new code)
        \\  verify-cost <case>        Leveled ReleaseFast cost witness (stub → M6)
        \\  init                      Create .myzig/ project config
        \\  help                      Show this help
        \\  version                   Show version
        \\
        \\Exit codes: 0 ok · 1 findings/ratchet/error · 2 bad usage / unknown command
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
            var prefer_compat = false;
            var want_ratchet = false;
            for (rest) |a| {
                if (std.mem.eql(u8, a, "--receipt")) {
                    want_receipt = true;
                } else if (std.mem.eql(u8, a, "--prefer-compat")) {
                    prefer_compat = true;
                } else if (std.mem.eql(u8, a, "--ratchet")) {
                    want_ratchet = true;
                } else if (std.mem.startsWith(u8, a, "-")) {
                    try rio.stderr.print("myzig check: unknown flag '{s}'\n", .{a});
                    return error.Usage;
                } else {
                    path = a;
                }
            }
            if (!prefer_compat) prefer_compat = check_mod.preferCompatMarker(rio.io);
            var result = try check_mod.checkPathOptions(rio.io, rio.allocator, path, .{
                .prefer_compat = prefer_compat,
            });
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
            if (want_ratchet) {
                var loaded = baseline_mod.loadBundle(rio.io, rio.allocator) catch |err| {
                    try rio.stderr.print(
                        "myzig check --ratchet: missing or unreadable {s} ({s}); run `myzig baseline` first\n",
                        .{ baseline_mod.baseline_path, @errorName(err) },
                    );
                    return error.Usage;
                };
                defer loaded.deinit(rio.allocator);
                var current = try baseline_mod.fromDiagnostics(
                    rio.allocator,
                    path,
                    rio.version,
                    result.diagnostics.items,
                );
                defer current.deinit(rio.allocator);
                var cmp = try baseline_mod.compare(rio.allocator, loaded.snap, current);
                defer cmp.deinit(rio.allocator);
                if (!cmp.ok) {
                    try rio.stderr.writeAll("ratchet: new safety debt vs baseline\n");
                    for (cmp.increases.items) |line| {
                        try rio.stderr.print("  {s}\n", .{line});
                    }
                    return error.Findings;
                }
                try rio.stdout.writeAll("ratchet: ok (no increase vs baseline)\n");
                // Existing findings are accepted debt under ratchet mode.
                return;
            }
            if (result.diagnostics.items.len > 0) return error.Findings;
        },
        .adopt => {
            const path = if (rest.len >= 1) rest[0] else ".";
            try adopt_mod.run(rio.io, rio.allocator, path, rio.version, rio.stdout, true);
        },
        .baseline => {
            const path = if (rest.len >= 1) rest[0] else ".";
            var result = try check_mod.checkPath(rio.io, rio.allocator, path);
            defer result.deinit(rio.allocator);
            var snap = try baseline_mod.fromDiagnostics(rio.allocator, path, rio.version, result.diagnostics.items);
            defer snap.deinit(rio.allocator);
            try baseline_mod.writeFile(rio.io, rio.allocator, snap);
            try rio.stdout.print("wrote {s}\n", .{baseline_mod.baseline_path});
            try rio.stdout.print("total_findings: {d}\n", .{snap.total_findings});
            for (snap.by_rule) |rc| {
                try rio.stdout.print("  {s}: {d}\n", .{ rc.rule_id, rc.count });
            }
        },
        .receipt => {
            const path = if (rest.len >= 1) rest[0] else ".";
            const prefer_compat = check_mod.preferCompatMarker(rio.io);
            var result = try check_mod.checkPathOptions(rio.io, rio.allocator, path, .{
                .prefer_compat = prefer_compat,
            });
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
                \\Opt into std insulation checks by creating an empty file:
                \\  .myzig/prefer_compat
                \\Then `myzig check` enables `compat.volatile-std` (or pass `--prefer-compat`).
                \\
                \\Project-local friction tips (optional overlay for `myzig friction`):
                \\  .myzig/friction-playbook.md
                \\
            ;
            try compat.writeFile(rio.io, ".myzig/README.md", readme);
            const overlay =
                \\# Project friction overlay
                \\
                \\Append project-specific agent tips here. Merged after the package
                \\playbook when you run `myzig friction`.
                \\
                \\### F-OTHER-001 · example (delete or replace)
                \\- **symptom:** …
                \\- **do:** …
                \\- **don't:** …
                \\- **promote-to-code-when:** …
                \\- **incident:** none yet
                \\
            ;
            try compat.writeFile(rio.io, ".myzig/friction-playbook.md", overlay);
            try rio.stdout.writeAll("created .myzig/ (including friction-playbook overlay)\n");
        },
        .friction => {
            var show_sources = false;
            for (rest) |a| {
                if (std.mem.eql(u8, a, "--sources")) {
                    show_sources = true;
                } else {
                    try rio.stderr.print("myzig friction: unknown flag '{s}'\n", .{a});
                    return error.Usage;
                }
            }
            var bundle = try friction_mod.load(rio.io, rio.allocator);
            defer bundle.deinit(rio.allocator);
            try friction_mod.write(rio.stdout, bundle, show_sources);
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
    try std.testing.expect(Command.parse("friction") == .friction);
    try std.testing.expect(Command.parse("verify-cost") == .verify_cost);
}
