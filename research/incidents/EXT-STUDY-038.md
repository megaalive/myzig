# EXT-STUDY-038 — layered PMM → VMM → kernel heap

## Pattern

```text
PMM  — physical frames (bitmap / stack / buddy)
VMM  — virtual ranges + page tables (may call PMM)
Heap — FreeListAllocator / HeapAllocator over a mapped virt region
```

Each layer has its own free. Unmapping a virt range may return frames to PMM;
heap `free` only returns bytes to the free-list inside an already-mapped
region. Guest/hypervisor heaps must not allocate “for less-privileged code”
from the HV heap without an explicit handoff.

## myzig promotion

Playbook (`F-OWN-042`).

## Boundary

Does not model cross-layer free graphs.
