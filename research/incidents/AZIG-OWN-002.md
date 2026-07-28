# AZIG-OWN-002 — out-param and rename transfers

## Summary

Zig APIs often hand ownership to the caller without a `return` of the allocated
pointer: fill an out-parameter (`out.* = try allocator.alloc(...)`) or rename
before return (`const owned = buf; return owned;`). azig/zrig-style helpers use
these patterns routinely.

## Why it matters

Before this incident was promoted, `memory.alloc-undischarged` only treated:

1. `return try allocator.alloc(...)`, and
2. `const buf = try …; return buf`

as transfers. Out-params and one-hop renames were **false negatives** — the
obligation looked undischarged even when ownership clearly left the function.

## Symptom / observation

Dogfood reading of common Zig out-parameter fills flagged clean transfer sites.
Schema already listed `transfer_out_param` as a discharge kind, but the detector
did not implement it.

## Candidate rule / limit

- Teach the local detector:
  - `out.* = try …alloc/create/dupe`
  - `const buf = try …; out.* = buf;`
  - one-hop `const alias = buf; return alias;` / `out.* = alias;`
- Keep ceiling at `likely`
- Still document multi-hop aliases as FN (`docs/LIMITS.md`, `docs/BLINDSPOTS.md`)

## False-positive / fitting risk

Do not treat `out.* = buf.len` or `const alias = buf.len` as transfers.
Do not claim wrapper APIs (`takeOwnership(buf)`) transfer without explicit modeling.
