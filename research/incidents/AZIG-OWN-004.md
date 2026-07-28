# AZIG-OWN-004 — list.append(try dupe) is a collection transfer

## Summary

azig commonly moves owned slices into lists with:

```zig
try urls.append(try allocator.dupe(u8, url));
```

(`src/inti/orkestrator_web.zig` and similar). Ownership leaves the local binding
and enters the collection.

## Why it matters

Without recognizing same-line `.append(` / `.appendSlice(` + acquire as transfer,
myzig flagged clean collection fills as `memory.alloc-undischarged`.

## Candidate rule / limit

- Same-line append+acquire ⇒ transfer (likely)
- Multi-line `const x = try dupe; try list.append(x);` remains a possible FN
- Collection freers (`deinit` freeing items) stay out of scope for V0

## False-positive / fitting risk

Do not treat append of a non-owned temporary as creating an obligation discharge
for an earlier unrelated alloc.
