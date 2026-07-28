//! Reproducible receipts: bind revision/config; observed vs claimed.

const std = @import("std");
const builtin = @import("builtin");
const diagnostic = @import("diagnostic.zig");
const baseline = @import("baseline.zig");
const json_out = @import("json_out.zig");
const schema = @import("schema.zig");
const compat = @import("compat.zig");
const adopt = @import("adopt.zig");
const verify_cost = @import("verify_cost.zig");

/// Claimed witnesses must only appear when a verify step actually ran.
pub const CostClaim = struct {
    case_id: []const u8,
    status: []const u8,
    witness: []const u8,
};

pub const Claimed = struct {
    verify_cost: []const CostClaim = &.{},
};

pub const Receipt = struct {
    myzig_version: []const u8,
    compat_adapter: []const u8,
    zig_version: []const u8,
    source_revision: []const u8,
    ruleset_revision: []const u8,
    path: []const u8,
    prefer_compat: bool = false,
    rules_checked: usize,
    findings: usize,
    diagnostics: []const diagnostic.Diagnostic,
    by_rule: []const baseline.RuleCount = &.{},
    unsafe_ptrcast: usize = 0,
    unsafe_aligncast: usize = 0,
    unsafe_bitcast: usize = 0,
    baseline_total: ?usize = null,
    baseline_delta_ok: ?bool = null,
    claimed: Claimed = .{},
};

pub fn zigVersionString() []const u8 {
    return builtin.zig_version_string;
}

pub fn rulesetRevision() []const u8 {
    return schema.ruleset_revision;
}

pub fn resolveSourceRevision(gpa: std.mem.Allocator) ![]u8 {
    const keys = [_][]const u8{ "MYZIG_SOURCE_REVISION", "GITHUB_SHA", "GIT_COMMIT" };
    for (keys) |key| {
        if (compat.envGet(gpa, key)) |v| return v else |_| {}
    }
    return try gpa.dupe(u8, "unspecified");
}

pub fn writeJson(writer: *std.Io.Writer, r: Receipt) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.writeAll("  \"schema_version\": \"0.0.0\",\n");
    try writer.writeAll("  \"myzig_version\": ");
    try json_out.writeString(writer, r.myzig_version);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"compat_adapter\": ");
    try json_out.writeString(writer, r.compat_adapter);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"zig_version\": ");
    try json_out.writeString(writer, r.zig_version);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"source_revision\": ");
    try json_out.writeString(writer, r.source_revision);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"ruleset_revision\": ");
    try json_out.writeString(writer, r.ruleset_revision);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"path\": ");
    try json_out.writeString(writer, r.path);
    try writer.writeAll(",\n");
    try writer.print("  \"prefer_compat\": {},\n", .{r.prefer_compat});
    try writer.writeAll("  \"observed\": {\n");
    try writer.print("    \"rules_checked\": {d},\n", .{r.rules_checked});
    try writer.print("    \"findings\": {d},\n", .{r.findings});
    try writer.writeAll("    \"unsafe_by_kind\": {\n");
    try writer.print("      \"ptrcast\": {d},\n", .{r.unsafe_ptrcast});
    try writer.print("      \"aligncast\": {d},\n", .{r.unsafe_aligncast});
    try writer.print("      \"bitcast\": {d}\n", .{r.unsafe_bitcast});
    try writer.writeAll("    },\n");
    try writer.writeAll("    \"by_rule\": {\n");
    for (r.by_rule, 0..) |rc, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("      ");
        try json_out.writeString(writer, rc.rule_id);
        try writer.print(": {d}", .{rc.count});
    }
    if (r.by_rule.len > 0) try writer.writeAll("\n");
    try writer.writeAll("    },\n");
    if (r.baseline_total) |bt| {
        try writer.print("    \"baseline_total_findings\": {d},\n", .{bt});
        if (r.baseline_delta_ok) |ok| {
            try writer.print("    \"baseline_no_increase\": {},\n", .{ok});
        }
    }
    try writer.writeAll("    \"diagnostics\": [\n");
    for (r.diagnostics, 0..) |d, i| {
        if (i > 0) try writer.writeAll(",\n");
        try writer.writeAll("      {\n");
        try writer.writeAll("        \"rule_id\": ");
        try json_out.writeString(writer, d.rule_id);
        try writer.writeAll(",\n");
        try writer.writeAll("        \"severity\": ");
        try json_out.writeString(writer, d.severity.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("        \"certainty\": ");
        try json_out.writeString(writer, d.certainty.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("        \"obligation\": ");
        try json_out.writeString(writer, d.obligation.asText());
        try writer.writeAll(",\n");
        try writer.writeAll("        \"message\": ");
        try json_out.writeString(writer, d.message);
        try writer.writeAll(",\n");
        try writer.writeAll("        \"path\": ");
        try json_out.writeString(writer, d.location.path);
        try writer.writeAll(",\n");
        try writer.print("        \"line\": {d},\n", .{d.location.line});
        try writer.print("        \"column\": {d}\n", .{d.location.column});
        try writer.writeAll("      }");
    }
    try writer.writeAll("\n    ]\n");
    try writer.writeAll("  },\n");
    try writer.writeAll("  \"claimed\": ");
    if (r.claimed.verify_cost.len == 0) {
        try writer.writeAll("{}\n");
    } else {
        try writer.writeAll("{\n");
        try writer.writeAll("    \"verify_cost\": [\n");
        for (r.claimed.verify_cost, 0..) |c, i| {
            if (i > 0) try writer.writeAll(",\n");
            try writer.writeAll("      {\n");
            try writer.writeAll("        \"case\": ");
            try json_out.writeString(writer, c.case_id);
            try writer.writeAll(",\n");
            try writer.writeAll("        \"status\": ");
            try json_out.writeString(writer, c.status);
            try writer.writeAll(",\n");
            try writer.writeAll("        \"witness\": ");
            try json_out.writeString(writer, c.witness);
            try writer.writeAll("\n      }");
        }
        try writer.writeAll("\n    ]\n");
        try writer.writeAll("  }\n");
    }
    try writer.writeAll("}\n");
}

/// Build a receipt from a check result (arena-friendly allocations).
pub fn build(
    io: compat.Io,
    gpa: std.mem.Allocator,
    path: []const u8,
    myzig_version: []const u8,
    prefer_compat: bool,
    diags: []const diagnostic.Diagnostic,
) !struct {
    receipt: Receipt,
    snap: baseline.Snapshot,
    source_revision: []u8,
    cost_claims: []CostClaim,
    cost_owned: std.ArrayList([]u8),
} {
    var snap = try baseline.fromDiagnostics(gpa, path, myzig_version, diags);
    errdefer snap.deinit(gpa);
    const source_revision = try resolveSourceRevision(gpa);
    errdefer gpa.free(source_revision);

    var unsafe_ptr: usize = 0;
    var unsafe_align: usize = 0;
    var unsafe_bit: usize = 0;
    if (adopt.countTree(io, gpa, path)) |summary| {
        unsafe_ptr = summary.ptrcast_sites;
        unsafe_align = summary.aligncast_sites;
        unsafe_bit = summary.bitcast_sites;
    } else |_| {}

    var baseline_total: ?usize = null;
    var baseline_ok: ?bool = null;
    if (baseline.loadBundle(io, gpa)) |loaded_val| {
        var loaded = loaded_val;
        defer loaded.deinit(gpa);
        baseline_total = loaded.snap.total_findings;
        var cmp = try baseline.compare(gpa, loaded.snap, snap);
        defer cmp.deinit(gpa);
        baseline_ok = cmp.ok;
    } else |_| {}

    var cost_owned: std.ArrayList([]u8) = .empty;
    errdefer {
        for (cost_owned.items) |s| gpa.free(s);
        cost_owned.deinit(gpa);
    }
    const cost_claims = try loadCostClaims(io, gpa, &cost_owned);

    const receipt: Receipt = .{
        .myzig_version = myzig_version,
        .compat_adapter = compat.adapterName(),
        .zig_version = zigVersionString(),
        .source_revision = source_revision,
        .ruleset_revision = rulesetRevision(),
        .path = path,
        .prefer_compat = prefer_compat,
        .rules_checked = schema.seed_rules.len,
        .findings = diags.len,
        .diagnostics = diags,
        .by_rule = snap.by_rule,
        .unsafe_ptrcast = unsafe_ptr,
        .unsafe_aligncast = unsafe_align,
        .unsafe_bitcast = unsafe_bit,
        .baseline_total = baseline_total,
        .baseline_delta_ok = baseline_ok,
        .claimed = .{ .verify_cost = cost_claims },
    };
    return .{
        .receipt = receipt,
        .snap = snap,
        .source_revision = source_revision,
        .cost_claims = cost_claims,
        .cost_owned = cost_owned,
    };
}

fn loadCostClaims(
    io: compat.Io,
    gpa: std.mem.Allocator,
    owned: *std.ArrayList([]u8),
) ![]CostClaim {
    var claims: std.ArrayList(CostClaim) = .empty;
    errdefer claims.deinit(gpa);

    for (verify_cost.builtin_cases) |c| {
        const path = try std.fmt.allocPrint(gpa, "{s}/{s}.json", .{ verify_cost.witnesses_dir, c.id });
        defer gpa.free(path);
        const bytes = compat.readFileAlloc(io, gpa, path, 512 * 1024) catch continue;
        defer gpa.free(bytes);

        var parsed = std.json.parseFromSlice(std.json.Value, gpa, bytes, .{}) catch continue;
        defer parsed.deinit();
        const root = parsed.value.object;
        const case_id = root.get("case").?.string;
        const status = root.get("status").?.string;
        const witness = root.get("witness").?.string;

        const case_dup = try gpa.dupe(u8, case_id);
        try owned.append(gpa, case_dup);
        const status_dup = try gpa.dupe(u8, status);
        try owned.append(gpa, status_dup);
        const witness_dup = try gpa.dupe(u8, witness);
        try owned.append(gpa, witness_dup);

        try claims.append(gpa, .{
            .case_id = case_dup,
            .status = status_dup,
            .witness = witness_dup,
        });
    }

    return try claims.toOwnedSlice(gpa);
}

test "receipt json contains observed findings and empty claimed" {
    var buf: [2048]u8 = undefined;
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
        .zig_version = "0.17.0-dev",
        .source_revision = "deadbeef",
        .ruleset_revision = "0.0.0-seed",
        .path = "a.zig",
        .prefer_compat = false,
        .rules_checked = 4,
        .findings = 1,
        .diagnostics = &diags,
    });
    const out = buf[0..w.end];
    try std.testing.expect(std.mem.indexOf(u8, out, "\"findings\": 1") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "\"source_revision\": \"deadbeef\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "\"claimed\": {}") != null);
    try std.testing.expect(std.mem.indexOf(u8, out, "verify_cost") == null);
}
