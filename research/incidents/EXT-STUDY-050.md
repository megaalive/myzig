# EXT-STUDY-050 — steady-state zero alloc and static limits

## Pattern

High-assurance databases/event loops size journals, replicas, and message
buffers statically (or at startup) and avoid GPA in the steady-state path.
Fuzz/tests may use GPA; production hot paths do not.

## myzig promotion

Playbook (`F-OWN-054`); sibling of `PhaseAllocator` / boottime seal.

## Boundary

Does not prove a function is allocation-free.
