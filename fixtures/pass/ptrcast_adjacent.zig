//! Pass fixture: permit on the previous adjacent line discharges ptrcast.

pub fn okAdjacent(p: *anyopaque) *u8 {
    // myzig.permit(ptrcast): callback opaque
    return @ptrCast(p);
}
