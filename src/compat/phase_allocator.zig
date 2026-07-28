//! Phase-gated allocator wrapper.
//!
//! Startup may allocate; after seal, accidental runtime alloc asserts;
//! teardown allows free only. Use when a program has distinct capability
//! phases — not a mandate that all apps be static-only.
//!
//! Kernel sibling: boottime FixedBufferAllocator sealed before the lasting
//! runtime heap takes over (`EXT-STUDY-039`).

const std = @import("std");
const assert = std.debug.assert;
const mem = std.mem;
const Alignment = mem.Alignment;

const PhaseAllocator = @This();

parent_allocator: mem.Allocator,
phase: Phase,

pub const Phase = enum {
    /// Alloc / resize / free allowed (startup / construction).
    startup,
    /// No alloc, resize, or free (steady state).
    sealed,
    /// Free allowed; alloc / resize forbidden (shutdown).
    teardown,
};

pub fn init(parent_allocator: mem.Allocator) PhaseAllocator {
    return .{
        .parent_allocator = parent_allocator,
        .phase = .startup,
    };
}

pub fn deinit(self: *PhaseAllocator) void {
    self.* = undefined;
}

pub fn seal(self: *PhaseAllocator) void {
    assert(self.phase == .startup);
    self.phase = .sealed;
}

pub fn beginTeardown(self: *PhaseAllocator) void {
    assert(self.phase == .sealed);
    self.phase = .teardown;
}

pub fn allocator(self: *PhaseAllocator) mem.Allocator {
    return .{
        .ptr = self,
        .vtable = &.{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        },
    };
}

fn alloc(ctx: *anyopaque, len: usize, ptr_align: Alignment, ret_addr: usize) ?[*]u8 {
    const self: *PhaseAllocator = @ptrCast(@alignCast(ctx));
    assert(self.phase == .startup);
    return self.parent_allocator.rawAlloc(len, ptr_align, ret_addr);
}

fn resize(ctx: *anyopaque, buf: []u8, buf_align: Alignment, new_len: usize, ret_addr: usize) bool {
    const self: *PhaseAllocator = @ptrCast(@alignCast(ctx));
    assert(self.phase == .startup);
    return self.parent_allocator.rawResize(buf, buf_align, new_len, ret_addr);
}

fn remap(ctx: *anyopaque, buf: []u8, buf_align: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    const self: *PhaseAllocator = @ptrCast(@alignCast(ctx));
    assert(self.phase == .startup);
    return self.parent_allocator.rawRemap(buf, buf_align, new_len, ret_addr);
}

fn free(ctx: *anyopaque, buf: []u8, buf_align: Alignment, ret_addr: usize) void {
    const self: *PhaseAllocator = @ptrCast(@alignCast(ctx));
    assert(self.phase == .startup or self.phase == .teardown);
    // Once freeing starts from startup, enter teardown so further allocs fail.
    if (self.phase == .startup) self.phase = .teardown;
    return self.parent_allocator.rawFree(buf, buf_align, ret_addr);
}

test "startup alloc works; seal then teardown free" {
    const gpa = std.testing.allocator;
    var phase_alloc = PhaseAllocator.init(gpa);
    defer phase_alloc.deinit();
    const a = phase_alloc.allocator();
    const buf = try a.alloc(u8, 4);
    a.free(buf);
    try std.testing.expect(phase_alloc.phase == .teardown);

    var phase2 = PhaseAllocator.init(gpa);
    defer phase2.deinit();
    const a2 = phase2.allocator();
    const b = try a2.alloc(u8, 2);
    phase2.seal();
    try std.testing.expect(phase2.phase == .sealed);
    phase2.beginTeardown();
    a2.free(b);
    try std.testing.expect(phase2.phase == .teardown);
}
