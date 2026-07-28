# EXT-STUDY-042 — guest quotas vs hypervisor heap

## Pattern

```zig
// HV HeapAllocator: for hypervisor structures only — not guest payloads
Guest.quotas.max_ram_pages / used_ram_pages
Guest.space // guest GPA↔HPA mapping separate from HV heap
```

Hypervisors separate (1) HV heap for control objects, (2) physical page pools
with refcount/COW, and (3) per-guest RAM quotas. Allocating guest RAM from the
HV free-list without quota accounting leaks isolation.

## myzig promotion

Playbook (`F-OWN-046`).

## Boundary

No guest/host ownership CFG.
