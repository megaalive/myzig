# EXT-STUDY-045 — pooled buffer providers release or promote

## Pattern

```zig
// Writer backed by a buffer pool
deinit: if pooled → provider.pool.release(buf) else allocator.free
// Grow may promote out of the pool (pooled=false) then free with allocator
```

Web frame / message stacks borrow fixed-size buffers from a provider; returning
the wrong path double-frees or leaks the pool.

## myzig promotion

Playbook (`F-OWN-049`). `release` already discharges.

## Boundary

Does not track pool vs heap promotion flags.
