//! Pass fixture for `unsafe.ptrcast-unremarked` with structured permit.

pub fn castOpaque(p: *anyopaque) *u8 {
    return @ptrCast(p); // myzig.permit(ptrcast): caller guarantees *u8 payload
}
