# MYZIG-OWN-001 — local alloc undischarged

## Summary

A function allocates with `allocator.alloc`, returns a non-pointer derived value
(`buffer.len`), and never frees or transfers the buffer.

## Original pattern

```zig
pub fn leakyBuffer(allocator: std.mem.Allocator, n: usize) !usize {
    const buffer = try allocator.alloc(u8, n);
    return buffer.len;
}
```

## Why wrong

The allocation creates `memory_must_release_or_transfer`. Returning `buffer.len`
does not transfer the allocation. The buffer is leaked.

## Symptom

Leak detectors / GPA in tests / long-running process RSS growth. Zig compiler
does not reject this.

## Human fix

```zig
defer allocator.free(buffer);
```

or transfer ownership by returning `[]u8` instead of `usize`.

## Candidate rule

`memory.alloc-undischarged` (certainty ceiling: `likely`)

## Fixtures

- fail: `fixtures/fail/alloc_undischarged.zig`
- pass: `fixtures/pass/alloc_defer_free.zig`

## False-positive risk

- Returning `allocator.alloc(...)` directly is a transfer (should not fire).
- Function-scoped `defer free` discharges other acquires coarsely (may hide a
  second undischarged site in the same function).
- No path sensitivity: conditional free may be missed or over-accepted.

## Azig follow-up

See `AZIG-OWN-001` for arena + coarse defer discharge limits extracted from azig
HTTP/runtime patterns. This fixture incident remains the M1 loop proof.
