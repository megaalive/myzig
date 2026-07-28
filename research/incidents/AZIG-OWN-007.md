# AZIG-OWN-007 — ownership retarget `out = next; return out`

## Summary

String rewrite helpers allocate a replacement buffer, free the old one, then
retarget the local binding before returning:

```zig
const next = try allocator.dupe(u8, trimmed);
allocator.free(out);
out = next;
return out;
```

Seen in web text cleanup (`inti/orkestrator_web.zig`).

## Why it matters

`next` was flagged as undischarged because only `const alias = name` renames
were followed, not assignment retargets.

## Candidate rule / limit

- Exact `lhs = rhs;` (ident = ident) adds `lhs` to the alias closure of `rhs`
- Skip `.field = name`, `==`, and `name.len` / index forms
- Keep ceiling at `likely`

## False-positive / fitting risk

Do not treat `out = next.len` as ownership move.
Do not model pointer arithmetic retargets.
