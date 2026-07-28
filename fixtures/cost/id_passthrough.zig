//! Cost-witness subject: identity passthrough (no alloc, no helper runtime).

pub fn id(x: u32) u32 {
    return x;
}
