//! Ordinary Zig that acquires memory without a local discharge.
//! Used as a fail fixture for `memory.alloc-undischarged` (M0/M1).
//! This file does not import myzig.
//!
//! Note: this is intentionally incomplete ownership — do not copy into
//! production code. The analyzer should flag the missing discharge.

const std = @import("std");

pub fn leakyBuffer(allocator: std.mem.Allocator, n: usize) !usize {
    const buffer = try allocator.alloc(u8, n);
    // Obligation created; length is returned but the buffer is neither
    // freed nor transferred — a local undischarged allocation.
    return buffer.len;
}
