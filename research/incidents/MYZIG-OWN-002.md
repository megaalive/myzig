# MYZIG-OWN-002 — explicit free without defer

## Summary

Straight-line `allocator.free(buffer)` (no `defer`) is a valid local discharge.
Early detectors only treated function-wide `defer …free/destroy/deinit` as release,
so explicit frees looked undischarged.

## Why it matters

Agents often free immediately in short helpers. Flagging those sites trains agents
to add redundant `defer` or ignore myzig.

## Symptom / observation

`const buffer = try allocator.alloc(...); allocator.free(buffer);` was reported
as `memory.alloc-undischarged` until per-binding `.free(name)` / `.destroy(name)`
/ `name.deinit(` matching landed.

## Candidate rule / limit

- Discharge the binding (and one-hop aliases) on matching free/destroy/deinit
- Keep coarse `defer` discharge for arena-style sites (`AZIG-OWN-001`)
- Still do not claim path-sensitive “always freed”

## False-positive / fitting risk

Do not treat `.free(other)` as discharging `buffer`. Do not treat multi-hop
renames as released without modeling.
