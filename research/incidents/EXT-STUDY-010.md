# EXT-STUDY-010 — resource capability by phase

## Pattern

Wrap an allocator with an explicit phase machine:

- `startup` — alloc / resize / free allowed
- `sealed` — no heap mutation (steady state)
- `teardown` — free only

Accidental runtime allocation after seal becomes an assertion failure.

## myzig promotion

- Helper: `myzig.compat.PhaseAllocator`
- Playbook tip: encode *when* a capability is valid, not only whether it exists
- Not a mandate that every app allocate only at startup

## Boundary

Request-scoped arenas and long-lived GPAs remain first-class for ordinary apps.
