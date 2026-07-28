//! Fail fixture: empty catch swallows errors.

fn mightFail() !void {
    return error.Nope;
}

pub fn bad() void {
    mightFail() catch {};
}
