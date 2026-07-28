# EXT-STUDY-020 — indexed out-store and init-in-struct transfer

## Pattern

```zig
into[i] = try allocator.dupe(u8, src);           // caller owns into[i]
return .{ .req_state = req_state, .res = res }; // init transferred into owner
```

Row/decoders fill caller slices; connection factories return nested init state
inside a struct literal.

## myzig promotion

- `into[i] = try …alloc/dupe` counts as transfer for `memory.alloc-undischarged`
- `try X.init` returned via `return .{ .field = name }` discharges
  `lifecycle.init-without-deinit`

## Boundary

Does not prove the caller frees `into[i]` later.
