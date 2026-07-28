# EXT-STUDY-034 — managed draw Context vs borrowed Surface

## Pattern

```zig
var ctx = Context.init(io, alloc, &surface);
defer ctx.deinit(); // frees managed Path/font — not the Surface
defer surface.deinit(alloc); // caller still owns the pixel buffer
// Same allocator for every Surface method for the object's life
```

CPU 2D stacks often split “managed frontend” from “borrowed target.” Mixing
allocators across `init`/`grow`/`deinit` is illegal for that surface.

## myzig promotion

Playbook (`F-OWN-038`). Init/deinit symmetry already covers Context;
allocator-identity across methods is not checked.

## Boundary

Does not prove the same allocator was used on every call.
