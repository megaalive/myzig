//! One-shot agent contract surface for harnesses (`myzig agent`).

const std = @import("std");
const catalog = @import("catalog.zig");
const compat = @import("compat.zig");
const friction = @import("friction.zig");
const limits = @import("limits.zig");

pub fn writeContract(writer: *std.Io.Writer, version: []const u8) std.Io.Writer.Error!void {
    try writer.writeAll("# myzig agent contract\n\n");
    try writer.print("myzig {s} · identity: deterministic · honest · auditable\n\n", .{version});
    try writer.writeAll(
        \\## Non-negotiables
        \\
        \\- Ordinary Zig is first-class (no mandatory `myzig` import).
        \\- Pick repair **intents** from `explain`; do not invent ownership policy.
        \\- Never claim `proven` above a rule's `certainty_ceiling` (`myzig limits`).
        \\- `claimed` receipt fields only after real witnesses (`verify-cost`).
        \\- New agent friction → update playbook text first (`myzig friction`), then code if repeated.
        \\
        \\## Self-correction loop
        \\
        \\```text
        \\1. myzig check <path> [--prefer-compat] [--ratchet]
        \\2. pick finding file:line
        \\3. myzig explain <file:line> --json   # or --agent
        \\4. choose one listed repair intent
        \\5. apply repair in source
        \\6. myzig check <path>
        \\7. myzig receipt <path>
        \\```
        \\
        \\Exit codes: `0` ok · `1` findings/ratchet/error · `2` usage/unknown
        \\
        \\## Session bootstrap
        \\
        \\```text
        \\myzig limits
        \\myzig friction
        \\myzig rules --agent
        \\```
        \\
        \\## Debt / insulation
        \\
        \\- Legacy accept: `myzig adopt` → edit `.myzig/policy.md` → `myzig baseline`
        \\- CI gate: `myzig check --ratchet <path>`
        \\- Std insulation: `.myzig/prefer_compat` or `--prefer-compat`
        \\- Local CI parity: `powershell -File scripts/ci.ps1` (matches Actions smoke)
        \\- Transfer tips: two-step field store / put / `takeOwnership*` / same-file callee free (`F-OWN-065`)
        \\- FFI wrappers: `ffi.wrapper-init-without-deinit` on `c.` files (`F-OWN-066`)
        \\- Sentinel types: keep `[:0]u8` from `dupeZ` / `allocSentinel` (`F-OWN-067`)
        \\
    );
}

pub fn writeFullBriefing(
    io: compat.Io,
    gpa: std.mem.Allocator,
    writer: *std.Io.Writer,
    version: []const u8,
    include_rules: bool,
    include_limits: bool,
    include_friction: bool,
) !void {
    try writeContract(writer, version);
    if (include_limits) {
        try writer.writeAll("\n---\n\n");
        var lim = try limits.load(io, gpa);
        defer lim.deinit(gpa);
        try writer.writeAll("## Limits (on disk)\n\n");
        try limits.write(writer, lim, true);
    }
    if (include_friction) {
        try writer.writeAll("\n---\n\n");
        var fr = try friction.load(io, gpa);
        defer fr.deinit(gpa);
        try writer.writeAll("## Friction playbook (on disk)\n\n");
        try friction.write(writer, fr, true);
    }
    if (include_rules) {
        try writer.writeAll("\n---\n\n");
        try catalog.writeAgent(writer);
    }
}

test "contract mentions loop and transfer/FFI tips" {
    var buf: [4096]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try writeContract(&w, "0.0.0");
    try std.testing.expect(std.mem.indexOf(u8, buf[0..w.end], "Self-correction loop") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..w.end], "F-OWN-065") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..w.end], "F-OWN-066") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..w.end], "F-OWN-067") != null);
}
