//! `myzig check` — run local ownership rules over Zig sources.

const std = @import("std");
const compat = @import("compat.zig");
const diagnostic = @import("diagnostic.zig");
const alloc_undischarged = @import("rules/alloc_undischarged.zig");
const file_undischarged = @import("rules/file_undischarged.zig");
const ptrcast_unremarked = @import("rules/ptrcast_unremarked.zig");
const volatile_std = @import("rules/volatile_std.zig");
const empty_defer = @import("rules/empty_defer.zig");
const hidden_allocator = @import("rules/hidden_allocator.zig");
const swallow_error = @import("rules/swallow_error.zig");
const init_without_deinit = @import("rules/init_without_deinit.zig");
const sentinel_type_loss = @import("rules/sentinel_type_loss.zig");
const suppress = @import("suppress.zig");

pub const Options = struct {
    /// When true, emit `compat.volatile-std` findings. Off by default so
    /// ordinary Zig stays first-class; dogfood apps opt in.
    prefer_compat: bool = false,
};

pub const Result = struct {
    diagnostics: std.ArrayList(diagnostic.Diagnostic),
    /// Paths owned by this result (duped for directory walks so findings outlive `child` frees).
    owned_paths: std.ArrayList([]u8),

    pub fn deinit(self: *Result, gpa: std.mem.Allocator) void {
        for (self.owned_paths.items) |p| gpa.free(p);
        self.owned_paths.deinit(gpa);
        self.diagnostics.deinit(gpa);
    }
};

pub fn checkPath(
    io: compat.Io,
    gpa: std.mem.Allocator,
    path: []const u8,
) !Result {
    return checkPathOptions(io, gpa, path, .{});
}

pub fn checkPathOptions(
    io: compat.Io,
    gpa: std.mem.Allocator,
    path: []const u8,
    options: Options,
) !Result {
    var result = Result{
        .diagnostics = .empty,
        .owned_paths = .empty,
    };
    errdefer result.deinit(gpa);

    const st = try compat.statFile(io, path);
    switch (st.kind) {
        .file => try checkFile(io, gpa, path, &result, options),
        .directory => try checkDir(io, gpa, path, &result, options),
        else => return error.UnsupportedPath,
    }
    return result;
}

fn checkDir(
    io: compat.Io,
    gpa: std.mem.Allocator,
    path: []const u8,
    result: *Result,
    options: Options,
) !void {
    const names = try compat.listDirAlloc(io, gpa, path);
    defer compat.freeDirList(gpa, names);

    for (names) |name| {
        if (std.mem.eql(u8, name, ".git") or
            std.mem.eql(u8, name, ".zig-cache") or
            std.mem.eql(u8, name, "zig-cache") or
            std.mem.eql(u8, name, "zig-out") or
            std.mem.eql(u8, name, ".myzig") or
            std.mem.eql(u8, name, ".planning"))
        {
            continue;
        }

        const child = try std.fs.path.join(gpa, &.{ path, name });
        defer gpa.free(child);

        const st = compat.statFile(io, child) catch continue;
        switch (st.kind) {
            .directory => try checkDir(io, gpa, child, result, options),
            .file => {
                if (std.mem.endsWith(u8, name, ".zig")) {
                    try checkFile(io, gpa, child, result, options);
                }
            },
            else => {},
        }
    }
}

fn checkFile(
    io: compat.Io,
    gpa: std.mem.Allocator,
    path: []const u8,
    result: *Result,
    options: Options,
) !void {
    // Own a durable path for diagnostics: directory walks free `child` after this returns.
    const path_owned = try gpa.dupe(u8, path);
    errdefer gpa.free(path_owned);
    try result.owned_paths.append(gpa, path_owned);

    const source = try compat.readFileAlloc(io, gpa, path_owned, 8 * 1024 * 1024);
    defer gpa.free(source);
    const out = &result.diagnostics;
    try alloc_undischarged.analyzeSource(path_owned, source, out, gpa);
    try file_undischarged.analyzeSource(path_owned, source, out, gpa);
    try ptrcast_unremarked.analyzeSource(path_owned, source, out, gpa);
    try volatile_std.analyzeSource(path_owned, source, out, gpa, options.prefer_compat);
    try empty_defer.analyzeSource(path_owned, source, out, gpa);
    try hidden_allocator.analyzeSource(path_owned, source, out, gpa);
    try swallow_error.analyzeSource(path_owned, source, out, gpa);
    // FFI-shaped files use the ffi.* rule id so explain/repairs talk about C cleanup.
    if (init_without_deinit.sourceLooksFfi(source)) {
        try init_without_deinit.analyzeFfiShaped(path_owned, source, out, gpa);
    } else {
        try init_without_deinit.analyzeSource(path_owned, source, out, gpa);
    }
    try sentinel_type_loss.analyzeSource(path_owned, source, out, gpa);
    suppress.filterSuppressed(source, out);
}

pub fn writeReport(writer: *std.Io.Writer, diags: []const diagnostic.Diagnostic) std.Io.Writer.Error!void {
    for (diags) |d| {
        try d.writeText(writer);
    }
    try writer.print("{d} finding(s)\n", .{diags.len});
}

/// True when the project opted into compat insulation via marker file.
pub fn preferCompatMarker(io: compat.Io) bool {
    compat.access(io, ".myzig/prefer_compat") catch return false;
    return true;
}

test "directory check keeps durable paths after child frees" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;
    const dir = ".zig-cache/myzig-check-path-own";
    const file_path = dir ++ "/poison.zig";
    try compat.createDirPath(io, dir);
    defer std.Io.Dir.cwd().deleteTree(io, dir) catch {};
    try compat.writeFile(io, file_path,
        \\pub fn f() void {
        \\    _ = error.X catch {};
        \\}
        \\
    );

    var result = try checkPath(io, gpa, dir);
    defer result.deinit(gpa);
    try std.testing.expect(result.diagnostics.items.len >= 1);
    const p = result.diagnostics.items[0].location.path;
    try std.testing.expect(std.mem.indexOf(u8, p, "poison.zig") != null);
    // GPA poison byte must not dominate the path string.
    var aa: usize = 0;
    for (p) |c| {
        if (c == 0xaa) aa += 1;
    }
    try std.testing.expect(aa * 2 < p.len);
}

test {
    _ = alloc_undischarged;
    _ = file_undischarged;
    _ = ptrcast_unremarked;
    _ = volatile_std;
    _ = empty_defer;
    _ = hidden_allocator;
    _ = swallow_error;
    _ = init_without_deinit;
    _ = suppress;
}
