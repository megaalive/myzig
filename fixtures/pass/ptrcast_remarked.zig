//! Pass fixture for `unsafe.ptrcast-unremarked`.

pub fn castOpaque(p: *anyopaque) *u8 {
    return @ptrCast(p); // safety: caller guarantees *u8 payload
}
