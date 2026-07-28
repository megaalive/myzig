//! Zig 0.17.x adapter — maps stable myzig.compat calls onto `std.Io` / process / c getenv.

const std = @import("std");
const IoStd = std.Io;

pub const name: []const u8 = "zig_0_17";
pub const Io = IoStd;

pub const Kind = enum {
    file,
    directory,
    sym_link,
    other,
};

pub const Stat = struct {
    size: u64,
    kind: Kind,
};

pub const ReadError = error{ OutOfMemory, StreamTooLong } || IoStd.Dir.ReadFileAllocError || IoStd.Cancelable;
pub const WriteError = IoStd.Dir.WriteFileError || IoStd.Cancelable;
pub const ListError = error{OutOfMemory} || IoStd.Dir.OpenError || IoStd.Dir.Iterator.Error || IoStd.Cancelable;
pub const StatError = IoStd.Dir.StatFileError || IoStd.Cancelable;
pub const PathError = error{ OutOfMemory, CurrentDirUnlinked } || IoStd.Dir.CreateDirPathError || IoStd.Cancelable || IoStd.UnexpectedError;
pub const EnvError = error{ OutOfMemory, EnvironmentVariableNotFound };
pub const AccessError = IoStd.Dir.AccessError || IoStd.Cancelable;
pub const CopyError = IoStd.Dir.CopyFileError || IoStd.Cancelable;
pub const DeleteError = IoStd.Dir.DeleteFileError || IoStd.Cancelable;

pub fn readFileAlloc(io: Io, gpa: std.mem.Allocator, path: []const u8, limit: usize) ReadError![]u8 {
    return IoStd.Dir.cwd().readFileAlloc(io, path, gpa, .limited(limit));
}

pub fn writeFile(io: Io, path: []const u8, data: []const u8) WriteError!void {
    try IoStd.Dir.writeFile(IoStd.Dir.cwd(), io, .{ .sub_path = path, .data = data });
}

pub fn listDirAlloc(io: Io, gpa: std.mem.Allocator, path: []const u8) ListError![][]u8 {
    var dir = try IoStd.Dir.cwd().openDir(io, path, .{ .iterate = true });
    defer dir.close(io);

    var list: std.ArrayList([]u8) = .empty;
    errdefer {
        for (list.items) |n| gpa.free(n);
        list.deinit(gpa);
    }

    var it = dir.iterate();
    while (try it.next(io)) |entry| {
        const name_copy = try gpa.dupe(u8, entry.name);
        errdefer gpa.free(name_copy);
        try list.append(gpa, name_copy);
    }
    return try list.toOwnedSlice(gpa);
}

pub fn freeDirList(gpa: std.mem.Allocator, names: [][]u8) void {
    for (names) |n| gpa.free(n);
    gpa.free(names);
}

pub fn statFile(io: Io, path: []const u8) StatError!Stat {
    const st = try IoStd.Dir.cwd().statFile(io, path, .{});
    return .{
        .size = st.size,
        .kind = mapKind(st.kind),
    };
}

fn mapKind(kind: IoStd.File.Kind) Kind {
    return switch (kind) {
        .file => .file,
        .directory => .directory,
        .sym_link => .sym_link,
        else => .other,
    };
}

pub fn createDirPath(io: Io, path: []const u8) PathError!void {
    try IoStd.Dir.cwd().createDirPath(io, path);
}

pub fn access(io: Io, path: []const u8) AccessError!void {
    try IoStd.Dir.cwd().access(io, path, .{});
}

pub fn copyFile(io: Io, source_path: []const u8, dest_path: []const u8) CopyError!void {
    const cwd = IoStd.Dir.cwd();
    try IoStd.Dir.copyFile(cwd, source_path, cwd, dest_path, io, .{});
}

pub fn deleteFile(io: Io, path: []const u8) DeleteError!void {
    try IoStd.Dir.cwd().deleteFile(io, path);
}

pub fn envGet(gpa: std.mem.Allocator, key: []const u8) EnvError![]u8 {
    const key_z = try gpa.dupeSentinel(u8, key, 0);
    defer gpa.free(key_z);
    const raw = std.c.getenv(key_z.ptr) orelse return error.EnvironmentVariableNotFound;
    return try gpa.dupe(u8, std.mem.span(raw));
}

pub fn currentPathAlloc(io: Io, gpa: std.mem.Allocator) PathError![]u8 {
    const path_z = try std.process.currentPathAlloc(io, gpa);
    defer gpa.free(path_z);
    // Public façade returns plain []u8 so callers can `gpa.free` without sentinel length traps.
    return try gpa.dupe(u8, path_z);
}

pub fn unixSeconds(io: Io) i64 {
    const ts = IoStd.Clock.Timestamp.now(io, .real);
    return ts.raw.toSeconds();
}

test "adapter name" {
    try std.testing.expectEqualStrings("zig_0_17", name);
}

test "write read list stat roundtrip" {
    const io = std.testing.io;
    const gpa = std.testing.allocator;

    const dir_path = ".zig-cache/myzig-compat-test";
    const file_path = ".zig-cache/myzig-compat-test/roundtrip.txt";

    try createDirPath(io, dir_path);
    defer IoStd.Dir.cwd().deleteTree(io, dir_path) catch {};

    try writeFile(io, file_path, "hello-compat");
    const data = try readFileAlloc(io, gpa, file_path, 1024);
    defer gpa.free(data);
    try std.testing.expectEqualStrings("hello-compat", data);

    const copy_path = ".zig-cache/myzig-compat-test/roundtrip-copy.txt";
    try copyFile(io, file_path, copy_path);
    const copied = try readFileAlloc(io, gpa, copy_path, 1024);
    defer gpa.free(copied);
    try std.testing.expectEqualStrings("hello-compat", copied);
    try deleteFile(io, copy_path);
    try std.testing.expectError(error.FileNotFound, access(io, copy_path));

    const st = try statFile(io, file_path);
    try std.testing.expect(st.kind == .file);
    try std.testing.expect(st.size == "hello-compat".len);

    const names = try listDirAlloc(io, gpa, dir_path);
    defer freeDirList(gpa, names);
    var found = false;
    for (names) |n| {
        if (std.mem.eql(u8, n, "roundtrip.txt")) found = true;
    }
    try std.testing.expect(found);

    const cwd = try currentPathAlloc(io, gpa);
    defer gpa.free(cwd);
    try std.testing.expect(cwd.len > 0);

    _ = unixSeconds(io);
}
