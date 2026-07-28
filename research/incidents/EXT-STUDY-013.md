# EXT-STUDY-013 — FFI / external resource blind spots

## Pattern

Owned Zig memory handed to C/OS/GPU APIs may outlive Zig allocator tracking.
Leak detectors that only see Zig allocators miss those paths.

## myzig stance

Future rule candidates (not seed yet):

- `ffi.external-resource-unverified`
- `ffi.cleanup-contract-unknown`
- `ffi.pointer-lifetime-escape`

Document as blind spots until dogfood produces repeatable incidents.

## Boundary

myzig stays an ownership coach for Zig sources; it is not a Valgrind replacement.
