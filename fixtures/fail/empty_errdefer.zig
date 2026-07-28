//! Fail fixture: empty errdefer does no error-path cleanup.

pub fn bad() !void {
    errdefer {}
    return error.Fail;
}
