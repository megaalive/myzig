# EXT-STUDY-028 — post-Zig runtime as allocator-shape reference only

## Pattern

A large formerly-Zig runtime may migrate its implementation language while
keeping the same *ownership shapes*: process heaps, scoped arenas, optional
allocators, and single-buffer scratch.

For myzig, that repo is **not** a Zig AST/fixture source anymore. Sample the
allocator *contracts* (outlives, reset, free no-op, null→global), not the
host language syntax.

## myzig promotion

Playbook (`F-OWN-031`). Study boundary sibling to language-repo notes
(`EXT-STUDY-015`).

## Boundary

Do not clone detector needles from non-Zig sources. Do not claim Zig leak
checks prove foreign-runtime heaps.
