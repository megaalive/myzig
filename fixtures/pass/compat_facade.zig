//! Pass fixture for `compat.volatile-std`.
//! Prefer myzig.compat call sites (no std.fs.cwd / getEnvVarOwned / Io.Dir.cwd).

pub fn readSmall(io: anytype, gpa: anytype) ![]u8 {
    // Intended shape (dogfood apps): myzig.compat.readFileAlloc(io, gpa, path, limit)
    _ = io;
    _ = gpa;
    return error.NotImplemented;
}
