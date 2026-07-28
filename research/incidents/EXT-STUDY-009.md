# EXT-STUDY-009 — allocator.create(T) vs method create

## Pattern

```zig
// acquire — single type argument
const p = try allocator.create(Handle);
const n = try allocator.create(u32);

// not an allocator create — multi-arg method
lazy.value = try Context.create(handle, allocator);
```

Bare `.create(` matched both shapes and produced false positives on lazy/resource
factories that return by value into a field.

## myzig promotion

- `.create(` is an acquire only for single-argument calls (`allocator.create(T)`)
- Multi-arg `.create(a, b, …)` is treated as a method, not a heap acquire
- Documented `catch unreachable` (adjacent comment) is allowed for invariants
- Certainty unchanged

## Boundary

Single-arg method `.create(value)` may still look like an acquire (possible FP).
