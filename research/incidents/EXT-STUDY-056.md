# EXT-STUDY-056 — type-2 HV host allocator vs guest RAM

## Pattern

```zig
var kvm_ctx = try Kvm.init(allocator, vm, cpus);
defer kvm_ctx.deinit();
// Host GPA paths allocate control structures; guest RAM is separate mmap/slots
```

Type-2 hypervisors (KVM-backed) use the host Zig allocator for VMM objects
(devices, interrupt managers, CPUID lists) while guest physical memory is
mapped through the hypervisor API — not `allocator.alloc` of guest payloads.

## myzig promotion

Playbook (`F-OWN-059`); sibling of guest quotas (`EXT-STUDY-042`).

## Boundary

Does not model KVM memslot graphs.
