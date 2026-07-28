//! `myzig check` — run local ownership rules over Zig sources.

const std = @import("std");
const compat = @import("compat.zig");
const diagnostic = @import("diagnostic.zig");
const alloc_undischarged = @import("rules/alloc_undischarged.zig");
const file_undischarged = @import("rules/file_undischarged.zig");
const ptrcast_unremarked = @import("rules/ptrcast_unremarked.zig");
const volatile_std = @import("rules/volatile_std.zig");

pub const Options = struct {
    /// When true, emit `compat.volatile-std` findings. Off by default so
    /// ordinary Zig stays first-class; dogfood apps opt in.
    prefer_compat: bool = false,
};

pub const Result = struct {
    diagnostics: std.ArrayList(diagnostic.Diagnostic),

    pub fn deinit(self: *Result, gpa: std.mem.Allocator) void {
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
    var result = Result{ .diagnostics = .empty };
    errdefer result.deinit(gpa);

    const st = try compat.statFile(io, path);
    switch (st.kind) {
        .file => try checkFile(io, gpa, path, &result.diagnostics, options),
        .directory => try checkDir(io, gpa, path, &result.diagnostics, options),
        else => return error.UnsupportedPath,
    }
    return result;
}

fn checkDir(
    io: compat.Io,
    gpa: std.mem.Allocator,
    path: []const u8,
    out: *std.ArrayList(diagnostic.Diagnostic),
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
            .directory => try checkDir(io, gpa, child, out, options),
            .file => {
                if (std.mem.endsWith(u8, name, ".zig")) {
                    try checkFile(io, gpa, child, out, options);
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
    out: *std.ArrayList(diagnostic.Diagnostic),
    options: Options,
) !void {
    const source = try compat.readFileAlloc(io, gpa, path, 8 * 1024 * 1024);
    defer gpa.free(source);
    try alloc_undischarged.analyzeSource(path, source, out, gpa);
    try file_undischarged.analyzeSource(path, source, out, gpa);
    try ptrcast_unremarked.analyzeSource(path, source, out, gpa);
    try volatile_std.analyzeSource(path, source, out, gpa, options.prefer_compat);
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

test {
    _ = alloc_undischarged;
    _ = file_undischarged;
    _ = ptrcast_unremarked;
    _ = volatile_std;
}
