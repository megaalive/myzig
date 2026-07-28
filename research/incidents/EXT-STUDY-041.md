# EXT-STUDY-041 — page-table ownership bits

## Pattern

```zig
// On remap/unmap: free physical page only if PAGE_ALLOCATED was set
if (pt_entry.* & PAGE_ALLOCATED != 0) pmem.free(pt_entry.*);
```

Virtual maps may point at bootloader/identity frames the kernel does not own.
An ownership bit (or refcount / COW flag on a page descriptor) decides whether
unmap returns the frame to the PMM.

## myzig promotion

Playbook (`F-OWN-045`).

## Boundary

Does not parse PTE flags or refcounts.
