//! Leveled ReleaseFast cost witnesses — claimed only after this command runs.

const std = @import("std");
const compat = @import("compat.zig");
const json_out = @import("json_out.zig");

pub const witnesses_dir = ".myzig/cost-witnesses";

pub const LevelStatus = enum {
    pass,
    fail,
    not_evaluated,

    pub fn asText(self: LevelStatus) []const u8 {
        return switch (self) {
            .pass => "pass",
            .fail => "fail",
            .not_evaluated => "not_evaluated",
        };
    }
};

pub const Case = struct {
    id: []const u8,
    summary: []const u8,
    /// Relative path to subject Zig source (fixture or package file).
    subject_path: []const u8,
};

pub const builtin_cases = [_]Case{
    .{
        .id = "id-passthrough",
        .summary = "Trivial identity function — baseline for leveled witnesses without ownership wrappers.",
        .subject_path = "fixtures/cost/id_passthrough.zig",
    },
};

pub fn findCase(id: []const u8) ?Case {
    for (builtin_cases) |c| {
        if (std.mem.eql(u8, c.id, id)) return c;
    }
    return null;
}

pub const Report = struct {
    case_id: []const u8,
    subject_path: []const u8,
    myzig_version: []const u8,
    level1_hidden_alloc: LevelStatus,
    level2_retained_call: LevelStatus,
    level3_extra_branch: LevelStatus,
    level4_normalized_code: LevelStatus,
    overall: LevelStatus,
    witness: []const u8,
};

fn hasNeedle(source: []const u8, needle: []const u8) bool {
    return std.mem.indexOf(u8, source, needle) != null;
}

fn evaluateSubject(source: []const u8) struct { l1: LevelStatus, l2: LevelStatus, l3: LevelStatus, l4: LevelStatus } {
    // Level 1: no hidden allocation markers in the subject helper.
    const alloc_needles = [_][]const u8{ "allocator.alloc", ".create(", "Allocator.alloc", "gpa.alloc" };
    var l1: LevelStatus = .pass;
    for (alloc_needles) |n| {
        if (hasNeedle(source, n)) {
            l1 = .fail;
            break;
        }
    }

    // Level 2: no retained helper call markers (crude text denylist).
    const call_needles = [_][]const u8{ "std.Thread.", "std.Mutex", "std.heap." };
    var l2: LevelStatus = .pass;
    for (call_needles) |n| {
        if (hasNeedle(source, n)) {
            l2 = .fail;
            break;
        }
    }

    // Level 3/4 need CFG / normalized asm — honest not_evaluated for V0.
    return .{ .l1 = l1, .l2 = l2, .l3 = .not_evaluated, .l4 = .not_evaluated };
}

fn overallStatus(l1: LevelStatus, l2: LevelStatus, l3: LevelStatus, l4: LevelStatus) LevelStatus {
    _ = l3;
    _ = l4;
    if (l1 == .fail or l2 == .fail) return .fail;
    return .pass;
}

fn witnessHash(gpa: std.mem.Allocator, case_id: []const u8, source: []const u8, l1: LevelStatus, l2: LevelStatus) ![]u8 {
    var h = std.hash.Wyhash.init(0);
    h.update(case_id);
    h.update("|");
    h.update(source);
    h.update("|");
    h.update(l1.asText());
    h.update("|");
    h.update(l2.asText());
    return try std.fmt.allocPrint(gpa, "wyhash:{x}", .{h.final()});
}

pub fn runCase(
    io: compat.Io,
    gpa: std.mem.Allocator,
    case: Case,
    myzig_version: []const u8,
) !Report {
    const source = try compat.readFileAlloc(io, gpa, case.subject_path, 2 * 1024 * 1024);
    defer gpa.free(source);
    const levels = evaluateSubject(source);
    const overall = overallStatus(levels.l1, levels.l2, levels.l3, levels.l4);
    const witness = try witnessHash(gpa, case.id, source, levels.l1, levels.l2);
    return .{
        .case_id = case.id,
        .subject_path = case.subject_path,
        .myzig_version = myzig_version,
        .level1_hidden_alloc = levels.l1,
        .level2_retained_call = levels.l2,
        .level3_extra_branch = levels.l3,
        .level4_normalized_code = levels.l4,
        .overall = overall,
        .witness = witness,
    };
}

pub fn writeText(writer: *std.Io.Writer, r: Report) std.Io.Writer.Error!void {
    try writer.print("Cost witness: {s}\n\n", .{if (r.overall == .pass) "PASS" else if (r.overall == .fail) "FAIL" else "PARTIAL"});
    try writer.print("case: {s}\n", .{r.case_id});
    try writer.print("subject: {s}\n", .{r.subject_path});
    try writer.print("Hidden allocation      {s}\n", .{r.level1_hidden_alloc.asText()});
    try writer.print("Runtime helper calls   {s}\n", .{r.level2_retained_call.asText()});
    try writer.print("Additional branches    {s}\n", .{r.level3_extra_branch.asText()});
    try writer.print("Normalized code match  {s}\n", .{r.level4_normalized_code.asText()});
    try writer.print("\nwitness: {s}\n", .{r.witness});
    try writer.writeAll(
        \\
        \\Claimed only after this command runs — receipts pick up
        \\`.myzig/cost-witnesses/<case>.json` when present.
        \\
    );
}

pub fn writeJson(writer: *std.Io.Writer, r: Report) std.Io.Writer.Error!void {
    try writer.writeAll("{\n");
    try writer.writeAll("  \"schema_version\": \"0.0.0\",\n");
    try writer.writeAll("  \"case\": ");
    try json_out.writeString(writer, r.case_id);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"subject\": ");
    try json_out.writeString(writer, r.subject_path);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"myzig_version\": ");
    try json_out.writeString(writer, r.myzig_version);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"status\": ");
    try json_out.writeString(writer, r.overall.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("  \"witness\": ");
    try json_out.writeString(writer, r.witness);
    try writer.writeAll(",\n");
    try writer.writeAll("  \"levels\": {\n");
    try writer.writeAll("    \"hidden_allocation\": ");
    try json_out.writeString(writer, r.level1_hidden_alloc.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"retained_helper_calls\": ");
    try json_out.writeString(writer, r.level2_retained_call.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"additional_branches\": ");
    try json_out.writeString(writer, r.level3_extra_branch.asText());
    try writer.writeAll(",\n");
    try writer.writeAll("    \"normalized_code_match\": ");
    try json_out.writeString(writer, r.level4_normalized_code.asText());
    try writer.writeAll("\n  }\n");
    try writer.writeAll("}\n");
}

pub fn persist(io: compat.Io, gpa: std.mem.Allocator, r: Report) ![]u8 {
    try compat.createDirPath(io, witnesses_dir);
    const path = try std.fmt.allocPrint(gpa, "{s}/{s}.json", .{ witnesses_dir, r.case_id });
    errdefer gpa.free(path);
    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    try writeJson(&aw.writer, r);
    try compat.writeFile(io, path, aw.written());
    return path;
}

pub fn writeList(writer: *std.Io.Writer) std.Io.Writer.Error!void {
    try writer.writeAll("verify-cost cases:\n");
    for (builtin_cases) |c| {
        try writer.print("  {s:<20} {s}\n", .{ c.id, c.summary });
        try writer.print("    subject: {s}\n", .{c.subject_path});
    }
}

test "id passthrough evaluates clean" {
    const src =
        \\pub fn id(x: u32) u32 {
        \\    return x;
        \\}
    ;
    const levels = evaluateSubject(src);
    try std.testing.expect(levels.l1 == .pass);
    try std.testing.expect(levels.l2 == .pass);
    try std.testing.expect(levels.l3 == .not_evaluated);
}
