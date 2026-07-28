# EXT-STUDY-030 — single-buffer scratch and nullable allocator

## Pattern

```text
MaxHeapAllocator: one reusable buffer; free() is a no-op; scope() resets on drop
NullableAllocator: same size as a real allocator; vtable=None means “no heap”
```

Single-buffer scratch avoids per-call GPA traffic; ownership is “reset the
buffer,” not “free each pointer.” Nullable allocators let empty/const values
carry no heap without a sentinel second field.

Zig analogues: `FixedBufferAllocator` / `ArenaAllocator.reset`, optional
`?Allocator`, and `std.heap.stackFallback` for stack-then-parent.

## myzig promotion

Playbook (`F-OWN-033`). Optional future compat helper only if dogfood repeats.

## Boundary

Does not detect no-op `free` APIs or optional-allocator misuse automatically.
