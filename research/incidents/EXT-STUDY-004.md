# EXT-STUDY-004 — hidden global allocators

## Pattern

```zig
pub fn bad() !void {
    const p = try std.heap.page_allocator.alloc(u8, 1);
    defer std.heap.page_allocator.free(p);
}
```

Allocation policy is buried inside the helper; callers cannot choose arena /
GPA / test allocator.

## myzig promotion

- New convention rule: `ownership.hidden-allocator`
- Text-scan needles for `page_allocator` / `c_allocator` on alloc/free lines
- Skips `test { ... }` blocks (tests may use globals by design)
- Certainty ceiling: `convention`

## Boundary

Full type resolution of allocator values and build-step lint hosts stay out of scope.
