//! myzig.compat — narrow, versioned façade over high-churn Zig std surfaces.
//!
//! Adopters (e.g. zrig) should call these APIs instead of raw `std.Io.Dir`,
//! volatile env helpers, or `std.time` clocks. When Zig std moves, only the
//! adapter under `compat/` should need changes.
//!
//! This is **not** a second standard library. Surface grows only when dogfood
//! proves another breakage. Ownership obligations still apply (open → close).

const std = @import("std");
const adapter = @import("compat/adapter.zig");

/// Runtime I/O handle from `std.process.Init` (or tests). Re-exported so
/// call sites need not import std just for the type name.
pub const Io = adapter.Io;

pub const Stat = adapter.Stat;
pub const Kind = adapter.Kind;

pub const ReadError = adapter.ReadError;
pub const WriteError = adapter.WriteError;
pub const ListError = adapter.ListError;
pub const StatError = adapter.StatError;
pub const PathError = adapter.PathError;
pub const EnvError = adapter.EnvError;
pub const AccessError = adapter.AccessError;

/// Read an entire file (cwd-relative or absolute per Zig path rules).
/// Caller owns the returned slice.
pub fn readFileAlloc(io: Io, gpa: std.mem.Allocator, path: []const u8, limit: usize) ReadError![]u8 {
    return adapter.readFileAlloc(io, gpa, path, limit);
}

/// Overwrite/create a file with `data`.
pub fn writeFile(io: Io, path: []const u8, data: []const u8) WriteError!void {
    return adapter.writeFile(io, path, data);
}

/// List immediate child names of a directory. Caller owns the slice and each name.
pub fn listDirAlloc(io: Io, gpa: std.mem.Allocator, path: []const u8) ListError![][]u8 {
    return adapter.listDirAlloc(io, gpa, path);
}

pub fn freeDirList(gpa: std.mem.Allocator, names: [][]u8) void {
    adapter.freeDirList(gpa, names);
}

pub fn statFile(io: Io, path: []const u8) StatError!Stat {
    return adapter.statFile(io, path);
}

pub fn createDirPath(io: Io, path: []const u8) PathError!void {
    return adapter.createDirPath(io, path);
}

pub fn access(io: Io, path: []const u8) AccessError!void {
    return adapter.access(io, path);
}

/// Read one environment variable. Caller owns the returned slice.
pub fn envGet(gpa: std.mem.Allocator, name: []const u8) EnvError![]u8 {
    return adapter.envGet(gpa, name);
}

/// Absolute path of the process cwd. Caller owns the returned slice.
pub fn currentPathAlloc(io: Io, gpa: std.mem.Allocator) PathError![]u8 {
    return adapter.currentPathAlloc(io, gpa);
}

/// Unix epoch seconds from the realtime clock.
pub fn unixSeconds(io: Io) i64 {
    return adapter.unixSeconds(io);
}

/// Which Zig adapter is active (for doctor / receipts).
pub fn adapterName() []const u8 {
    return adapter.name;
}

test {
    _ = adapter;
}

test "compat surface is wired" {
    try std.testing.expect(adapterName().len > 0);
}
