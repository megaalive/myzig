# EXT-STUDY-003 — study boundary (CFG/ZIR not cloned)

## Context

Field tools sometimes ship path-sensitive store engines, stack-escape checkers,
sentinel-alloc analysis, and CFG/ZIR passes.

## What we learn

- Path-sensitive double-free / leak / UAF needs CFG + resource stores
- Sentinel type loss (`dupeZ` → `[]u8`) is a real class of bugs
- FP fixtures for ownership transfers (struct return, append) validate heuristics we already model

## myzig stance

Explicit non-goal for now: do **not** compete on ZIR/CFG depth.
Win on obligation honesty, repair intents, receipts, ratchet, agent contract.
Document sentinel/path-sensitive gaps in `docs/LIMITS.md` / `docs/BLINDSPOTS.md`.

## Optional later

- Convention note for `.dupeZ(` stored into non-sentinel `[]u8` if incidents demand
- Never claim `proven` for heuristic memory rules
