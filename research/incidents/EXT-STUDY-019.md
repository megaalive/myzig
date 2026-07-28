# EXT-STUDY-019 — fixed-region / linker-heap allocators

## Pattern

Embedded and constrained runtimes allocate from a linker-defined heap slice or
a fixed buffer (`init_with_buffer` / `init_with_heap`), sometimes with a
fallback chain of regions. Stack reservation may shrink the heap end.

## myzig stance

- Sibling to `PhaseAllocator`: capability is *which region*, not only phase
- Playbook: prefer explicit region allocators over hidden globals on freestanding targets
- Do not ban request arenas on hosted servers

## Boundary

No detector for linker symbols or MMIO lifetimes.
