# AZIG-OWN-001 — arena-scoped buffers vs local alloc heuristic

## Summary

azig's HTTP/runtime paths often use `ArenaAllocator` with `defer arena.deinit()`
and then `a.alloc(...)` for short-lived buffers (see `src/penyedia/http_runtime.zig`).

## Why it matters

A naive "every `.alloc(` needs `free`" rule would either:

1. **FP** if it ignored arenas, or
2. **Over-accept** if any `defer …deinit` discharges the whole function (myzig V0).

myzig currently takes (2) for local heuristics: `defer` lines mentioning
`deinit`/`free`/`destroy` discharge acquires in that function. That matches many
arena call sites but can hide a second GPA leak in the same function.

## Symptom / observation

Dogfood reading of azig arena patterns did not require a new hard rule yet; it
refined **published limits** (coarse defer discharge) rather than a false "proven safe".

## Candidate rule / limit

- Keep `memory.alloc-undischarged` at `likely`
- Document arena coarseness in `docs/LIMITS.md`
- Future: track arena allocators distinctly (`arena_scoped` discharge) when incidents demand it

## False-positive / fitting risk

Do not claim arena modeling is precise until path-sensitive or typed allocator facts exist.
