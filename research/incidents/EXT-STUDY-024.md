# EXT-STUDY-024 — lasting vs scratch allocators

## Pattern

Apps expose a long-lived allocator for the widget/tree/session, and a separate
`scratch_allocator` (or similarly named) for short messages / one-frame strings.
Scratch-backed acquires are reclaimed by scratch reset or parent lifetime — not
by local `defer free`.

Defaulting the lasting allocator to `page_allocator` / `c_allocator` without an
explicit app override is the same hidden-heap smell as `EXT-STUDY-004`.

## myzig promotion

- Arena-token discharge also matches `scratch_allocator` / `scratch.` tokens
- Playbook (`F-OWN-026`); hidden-allocator rule already covers bare page/c heaps

## Boundary

Does not prove scratch is reset; naming heuristic only.
