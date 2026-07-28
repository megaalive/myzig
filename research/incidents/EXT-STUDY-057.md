# EXT-STUDY-057 — type-1 HV page allocator and EPT

## Pattern

Bare-metal hypervisors allocate physically contiguous pages from a direct-map
region (`PageAllocator` / frame IDs) and build Extended Page Tables (guest-phys
→ host-phys). Boot may consume a UEFI memory map first, then switch to the HV
page allocator. Guest GPA walks use EPT levels — separate from host Zig heap.

## myzig promotion

Playbook (`F-OWN-060`); strengthens PMM + guest isolation tips.

## Boundary

EPT walks and direct-map invariants are not checked by seed rules.
