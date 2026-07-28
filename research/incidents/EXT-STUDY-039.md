# EXT-STUDY-039 — boottime allocator then runtime seal

## Pattern

```zig
// Boot: FixedBufferAllocator over early physical range
boottime_allocator = fba.allocator();
// …
init2(); // leftover boot buffer → free-block list
boottime_allocator = null; // sealed — no more boot FBA
// Runtime: block allocator / sbrk / malloc-backed Allocator
```

Early boot uses a throwaway FBA; leftover capacity becomes the lasting heap.
After seal, boot-time pointers must not be freed with the runtime heap.

## myzig promotion

- `boottime_allocator` / `boot_allocator` tokens count as arena-backed acquires
- Playbook (`F-OWN-043`); conceptual sibling of `PhaseAllocator` (`EXT-STUDY-010`)

## Boundary

Does not prove boot pointers die at seal.
