//! Fail fixture for `compat.volatile-std` (requires `--prefer-compat`).
//! Intentionally uses stale/volatile std shapes agents remember.

const std = @import("std");

pub fn staleCwd() void {
    // Does not need to compile under every Zig — text scan only for this rule.
    _ = std.fs.cwd;
}
