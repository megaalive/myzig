# EXT-STUDY-064 — sentinel type-loss (`dupeZ` → `[]u8`)

## Context

Field tools (zwanzig `sentinel-alloc`) warn when a sentinel-terminated allocation
(`[:0]u8` from `dupeZ` / `allocSentinel` / …) is stored in a non-sentinel
`[]u8` / `[]const u8`. The allocator allocated `len+1` bytes; losing the
sentinel type can free the wrong size.

## What we learn

- Same-line explicit `const x: []u8 = try …dupeZ(` is text-scannable and honest
- Cross-line / inferred renames need AST/types — still a blind spot
- CFG/ZIR depth remains a non-goal (`EXT-STUDY-003`)

## myzig promotion

- Playbook `F-OWN-067`
- Soft convention rule `memory.sentinel-type-loss` (same-line only)
- Fixtures: `fixtures/fail/sentinel_type_loss.zig`, `fixtures/pass/sentinel_type_kept.zig`

## Boundary

Do not claim `proven`. Multi-hop type loss stays in `docs/BLINDSPOTS.md`.
