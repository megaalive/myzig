//! Baseline snapshot + ratchet against new safety debt.

const std = @import("std");
const compat = @import("compat.zig");
const diagnostic = @import("diagnostic.zig");

pub const baseline_path = ".myzig/baseline.json";

pub const RuleCount = struct {
    rule_id: []const u8,
    count: usize,
};

pub const Snapshot = struct {
    path: []const u8,
    myzig_version: []const u8,
    total_findings: usize,
    by_rule: []RuleCount,

    pub fn deinit(self: *Snapshot, gpa: std.mem.Allocator) void {
        for (self.by_rule) |*rc| gpa.free(rc.rule_id);
        gpa.free(self.by_rule);
    }
};

pub const LoadBundle = struct {
    path_owned: []u8,
    version_owned: []u8,
    snap: Snapshot,

    pub fn deinit(self: *LoadBundle, gpa: std.mem.Allocator) void {
        self.snap.deinit(gpa);
        gpa.free(self.path_owned);
        gpa.free(self.version_owned);
    }
};

pub const CompareResult = struct {
    ok: bool,
    increases: std.ArrayList([]const u8),

    pub fn deinit(self: *CompareResult, gpa: std.mem.Allocator) void {
        for (self.increases.items) |line| gpa.free(line);
        self.increases.deinit(gpa);
    }
};

pub fn fromDiagnostics(
    gpa: std.mem.Allocator,
    path: []const u8,
    myzig_version: []const u8,
    diags: []const diagnostic.Diagnostic,
) !Snapshot {
    var counts: std.StringArrayHashMapUnmanaged(usize) = .empty;
    defer counts.deinit(gpa);

    for (diags) |d| {
        const gop = try counts.getOrPut(gpa, d.rule_id);
        if (!gop.found_existing) {
            gop.key_ptr.* = d.rule_id;
            gop.value_ptr.* = 0;
        }
        gop.value_ptr.* += 1;
    }

    var by_rule = try gpa.alloc(RuleCount, counts.count());
    var filled: usize = 0;
    errdefer {
        for (by_rule[0..filled]) |*rc| gpa.free(rc.rule_id);
        gpa.free(by_rule);
    }
    var it = counts.iterator();
    while (it.next()) |entry| {
        by_rule[filled] = .{
            .rule_id = try gpa.dupe(u8, entry.key_ptr.*),
            .count = entry.value_ptr.*,
        };
        filled += 1;
    }
    std.mem.sort(RuleCount, by_rule, {}, struct {
        fn less(_: void, a: RuleCount, b: RuleCount) bool {
            return std.mem.order(u8, a.rule_id, b.rule_id) == .lt;
        }
    }.less);

    return .{
        .path = path,
        .myzig_version = myzig_version,
        .total_findings = diags.len,
        .by_rule = by_rule,
    };
}

pub fn writeJson(writer: *std.Io.Writer, snap: Snapshot) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.writeAll("  \"schema_version\": \"0.0.0\",\n");
    try writer.writeAll("  \"path\": ");
    try writeJsonString(writer, snap.path);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"myzig_version\": ");
    try writeJsonString(writer, snap.myzig_version);
    try writer.writeAll(",\n");
    try writer.print("  \"total_findings\": {d},\n", .{snap.total_findings});
    try writer.writeAll("  \"by_rule\": {\n");
    for (snap.by_rule, 0..) |rc, idx| {
        if (idx > 0) try writer.writeAll(",\n");
        try writer.writeAll("    ");
        try writeJsonString(writer, rc.rule_id);
        try writer.print(": {d}", .{rc.count});
    }
    if (snap.by_rule.len > 0) try writer.writeAll("\n");
    try writer.writeAll("  }\n");
    try writer.writeAll("}\n");
}

fn writeJsonString(writer: *std.Io.Writer, s: []const u8) std.Io.Writer.Error!void {
    try writer.writeByte('"');
    for (s) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(c),
        }
    }
    try writer.writeByte('"');
}

pub fn writeFile(io: compat.Io, gpa: std.mem.Allocator, snap: Snapshot) !void {
    try compat.createDirPath(io, ".myzig");
    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    try writeJson(&aw.writer, snap);
    try compat.writeFile(io, baseline_path, aw.written());
}

pub fn loadBundle(io: compat.Io, gpa: std.mem.Allocator) !LoadBundle {
    const bytes = try compat.readFileAlloc(io, gpa, baseline_path, 2 * 1024 * 1024);
    defer gpa.free(bytes);

    var parsed = try std.json.parseFromSlice(std.json.Value, gpa, bytes, .{});
    defer parsed.deinit();

    const root = parsed.value.object;
    const path = try gpa.dupe(u8, root.get("path").?.string);
    errdefer gpa.free(path);
    const myzig_version = try gpa.dupe(u8, root.get("myzig_version").?.string);
    errdefer gpa.free(myzig_version);
    const total: usize = @intCast(root.get("total_findings").?.integer);

    const by_obj = root.get("by_rule").?.object;
    var by_rule = try gpa.alloc(RuleCount, by_obj.count());
    errdefer {
        for (by_rule) |*rc| gpa.free(rc.rule_id);
        gpa.free(by_rule);
    }
    var i: usize = 0;
    var it = by_obj.iterator();
    while (it.next()) |entry| {
        by_rule[i] = .{
            .rule_id = try gpa.dupe(u8, entry.key_ptr.*),
            .count = @intCast(entry.value_ptr.*.integer),
        };
        i += 1;
    }
    std.mem.sort(RuleCount, by_rule, {}, struct {
        fn less(_: void, a: RuleCount, b: RuleCount) bool {
            return std.mem.order(u8, a.rule_id, b.rule_id) == .lt;
        }
    }.less);

    return .{
        .path_owned = path,
        .version_owned = myzig_version,
        .snap = .{
            .path = path,
            .myzig_version = myzig_version,
            .total_findings = total,
            .by_rule = by_rule,
        },
    };
}

fn countFor(snap: Snapshot, rule_id: []const u8) usize {
    for (snap.by_rule) |rc| {
        if (std.mem.eql(u8, rc.rule_id, rule_id)) return rc.count;
    }
    return 0;
}

pub fn compare(gpa: std.mem.Allocator, baseline: Snapshot, current: Snapshot) !CompareResult {
    var increases: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (increases.items) |line| gpa.free(line);
        increases.deinit(gpa);
    }

    if (current.total_findings > baseline.total_findings) {
        const line = try std.fmt.allocPrint(
            gpa,
            "total_findings {d} → {d}",
            .{ baseline.total_findings, current.total_findings },
        );
        try increases.append(gpa, line);
    }

    for (current.by_rule) |rc| {
        const was = countFor(baseline, rc.rule_id);
        if (rc.count > was) {
            const line = try std.fmt.allocPrint(
                gpa,
                "{s}: {d} → {d}",
                .{ rc.rule_id, was, rc.count },
            );
            try increases.append(gpa, line);
        }
    }

    return .{
        .ok = increases.items.len == 0,
        .increases = increases,
    };
}

test "fromDiagnostics aggregates by rule" {
    const gpa = std.testing.allocator;
    const diags = [_]diagnostic.Diagnostic{
        .{
            .rule_id = "memory.alloc-undischarged",
            .severity = .warning,
            .certainty = .likely,
            .obligation = .memory_must_release_or_transfer,
            .message = "a",
            .location = .{ .path = "a.zig", .line = 1, .column = 1 },
        },
        .{
            .rule_id = "memory.alloc-undischarged",
            .severity = .warning,
            .certainty = .likely,
            .obligation = .memory_must_release_or_transfer,
            .message = "b",
            .location = .{ .path = "b.zig", .line = 2, .column = 1 },
        },
    };
    var snap = try fromDiagnostics(gpa, ".", "0.0.0", &diags);
    defer snap.deinit(gpa);
    try std.testing.expect(snap.total_findings == 2);
    try std.testing.expect(snap.by_rule.len == 1);
    try std.testing.expect(snap.by_rule[0].count == 2);
}

test "compare detects increase" {
    const gpa = std.testing.allocator;
    var base_rules = try gpa.alloc(RuleCount, 1);
    base_rules[0] = .{ .rule_id = try gpa.dupe(u8, "memory.alloc-undischarged"), .count = 1 };
    var base: Snapshot = .{
        .path = ".",
        .myzig_version = "0.0.0",
        .total_findings = 1,
        .by_rule = base_rules,
    };
    defer base.deinit(gpa);

    var cur_rules = try gpa.alloc(RuleCount, 1);
    cur_rules[0] = .{ .rule_id = try gpa.dupe(u8, "memory.alloc-undischarged"), .count = 2 };
    var cur: Snapshot = .{
        .path = ".",
        .myzig_version = "0.0.0",
        .total_findings = 2,
        .by_rule = cur_rules,
    };
    defer cur.deinit(gpa);

    var cmp = try compare(gpa, base, cur);
    defer cmp.deinit(gpa);
    try std.testing.expect(!cmp.ok);
    try std.testing.expect(cmp.increases.items.len >= 1);
}
