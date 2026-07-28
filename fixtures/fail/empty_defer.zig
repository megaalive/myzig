//! Fail fixture: empty defer does no cleanup.

pub fn bad() void {
    defer {}
}
