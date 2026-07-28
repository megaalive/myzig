# EXT-STUDY-029 — borrowed arena pointer with null→global fallback

## Pattern

```text
ArenaPtr { arena: *const Arena }  // may be null
alloc:
  if arena != null → arena.alloc
  else             → process-global heap
```

Callers publish a borrowed arena into thread-locals / long-lived contexts.
Contract: pointee is not moved, reset, or dropped while any allocation through
the pointer is live. Null means “no active scope → use the global heap.”

## myzig promotion

Playbook (`F-OWN-032`). Reinforces nested-owner / arena-token tips; no new
seed rule (raw pointer + dual heap needs CFG).

## Boundary

Does not prove pointee stability or that free matches the heap that allocated.
