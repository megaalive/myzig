# AZIG-OWN-003 — `std.fmt.allocPrint` is an ownership acquire

## Summary

azig's HTTP/runtime paths heavily use `std.fmt.allocPrint(allocator, …)` for
URLs, error strings, and prompts (`src/penyedia/http_runtime.zig`). That API
returns owned memory, same obligation class as `.alloc` / `.dupe`.

## Why it matters

Early `memory.alloc-undischarged` only scanned `.alloc(`, `.create(`, `.dupe(`.
`allocPrint` / `allocPrintZ` / `alignedAlloc` / `dupeZ` were **false negatives**:
leaky `return msg.len` after `allocPrint` produced **0 findings**.

## Symptom / observation

```zig
const msg = try std.fmt.allocPrint(allocator, "n={d}", .{1});
return msg.len; // leaked — myzig was silent
```

Dogfood probe on a minimal snippet confirmed the FN before needle expansion.

## Candidate rule / limit

- Treat `.allocPrint(`, `.allocPrintZ(`, `.alignedAlloc(`, `.dupeZ(` as acquires
- Same discharge/transfer rules as other allocator needles
- Document that large azig functions with any `defer …free` may still be coarse
  (see `AZIG-OWN-001`)

## False-positive / fitting risk

Do not treat `allocPrint` mentions in comments as acquires (existing `//` guard).
Do not claim every azig `allocPrint` site is proven safe after this change.
