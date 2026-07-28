# EXT-STUDY-037 — physical frame allocators are not Zig Allocators

## Pattern

```zig
const page = pmm.alloc() orelse return error.OutOfMemory; // returns phys addr
try pmm.free(page); // frees BLOCK_SIZE / PAGE_SIZE by address

// or LIFO stack of free frames from multiboot mmap:
const frame = pmem.allocate();
pmem.free(frame);
```

Kernels track free *physical pages* with bitmaps, LIFO stacks, or buddy
orders. That API is address-sized, not `std.mem.Allocator`. Mixing
`allocator.free` with frame addresses (or the reverse) corrupts both layers.

## myzig promotion

Playbook (`F-OWN-041`). Sibling to freestanding region heaps (`EXT-STUDY-019`).

## Boundary

No detector for physical-address free lists or MMIO lifetimes.
