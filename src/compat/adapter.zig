//! Selects the Zig-toolchain adapter for `myzig.compat`.

const builtin = @import("builtin");

pub const impl = blk: {
    const v = builtin.zig_version;
    if (v.major == 0 and v.minor >= 17) {
        break :blk @import("zig_0_17.zig");
    }
    @compileError("myzig.compat: unsupported Zig version — add an adapter under src/compat/");
};

pub const name = impl.name;
pub const Io = impl.Io;
pub const Stat = impl.Stat;
pub const Kind = impl.Kind;

pub const ReadError = impl.ReadError;
pub const WriteError = impl.WriteError;
pub const ListError = impl.ListError;
pub const StatError = impl.StatError;
pub const PathError = impl.PathError;
pub const EnvError = impl.EnvError;
pub const AccessError = impl.AccessError;
pub const CopyError = impl.CopyError;
pub const DeleteError = impl.DeleteError;
pub const RenameError = impl.RenameError;

pub const readFileAlloc = impl.readFileAlloc;
pub const writeFile = impl.writeFile;
pub const listDirAlloc = impl.listDirAlloc;
pub const freeDirList = impl.freeDirList;
pub const statFile = impl.statFile;
pub const createDirPath = impl.createDirPath;
pub const access = impl.access;
pub const copyFile = impl.copyFile;
pub const deleteFile = impl.deleteFile;
pub const renameFile = impl.renameFile;
pub const envGet = impl.envGet;
pub const currentPathAlloc = impl.currentPathAlloc;
pub const unixSeconds = impl.unixSeconds;
