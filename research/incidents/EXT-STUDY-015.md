# EXT-STUDY-015 — language repo as semantic reference

## Pattern

The language implementation and stdlib are the source of truth for allocator
contracts, `defer`/`errdefer`, error sets, optionals, pointers, alignment,
sentinel slices, and testing allocators.

## myzig stance

Use as **idiom and semantic reference**, not as an application architecture
template. Analyzer behavior must track real language rules when they diverge
from “what looks reasonable.”

## Boundary

Do not clone compiler/linker/backend structure into myzig.
