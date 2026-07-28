# EXT-STUDY-002 — multi-line append ownership transfer

## Pattern

```zig
const data = try allocator.dupe(u8, src);
try list.append(allocator, .{ .data = data });
```

## Why it matters

myzig already treated same-line `append(try dupe)` as transfer (`AZIG-OWN-004`).
The multi-line form (dupe, then append struct field) was still a **false positive**.

## myzig promotion

- Binding appearing inside `.append(` / `.appendSlice(` argument span ⇒ transfer
- Keep certainty `likely`

## Boundary

Path-sensitive store engines and double-free / UAF analysis stay out of scope.
