# EXT-STUDY-043 — event-loop completions stay stable until cancel

## Pattern

Proactor loops submit work with a caller-owned `Completion` (and often a
cancel completion). Completions must remain at a stable address until the
loop notifies completion or cancel finishes. Zero runtime allocations is a
design goal: pool or stack-allocate completions up front.

## myzig promotion

Playbook (`F-OWN-047`); deepens `EXT-STUDY-014`. `cancel` discharges tracked
acquires when used as teardown.

## Boundary

Does not model outstanding submissions after loop deinit.
