# EXT-STUDY-036 — binding generators use arenas; Destroy* is generated

## Pattern

XML/registry parsers for GPU APIs allocate the IR into an `ArenaAllocator`,
then emit Zig with `Destroy*` / `destroy*` entry points. The interesting
ownership for apps is the *generated* teardown vocabulary — not the generator
process heap.

## myzig promotion

Playbook (`F-OWN-040`) + study boundary: treat generators like language repos
(`EXT-STUDY-015`) — take naming/teardown contracts, not generator internals.

## Boundary

myzig does not parse generated Vulkan/WebGPU bindings specially.
