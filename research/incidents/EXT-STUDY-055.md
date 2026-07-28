# EXT-STUDY-055 — UEFI BootServices pool and exitBootServices

## Pattern

```zig
// allocatePool may change the memory map — loop getMemoryMap until stable
boot_services.allocatePool(BootServicesData, size, &ptr);
boot_services.freePool(ptr);
// exitBootServices(image, memory_map_key) — after success BootServices are gone
```

Firmware pools are not GPA. The memory-map key must match the last successful
`getMemoryMap`. After `exitBootServices`, only runtime services remain.

Some loaders expose `uefi.pool_allocator` as an Allocator façade over the same pool.

## myzig promotion

Playbook (`F-OWN-058`). Sibling of freestanding regions (`EXT-STUDY-019`).

## Boundary

No detector for BootServices lifetime or map-key freshness.
