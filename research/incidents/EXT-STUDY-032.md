# EXT-STUDY-032 — handle pools and releaseResource vs destroyResource

## Pattern

```zig
const buf = gctx.createBuffer(...); // returns BufferHandle, not *Buffer
defer gctx.releaseResource(buf);    // pool slot + GPU release
// destroyResource(handle) additionally calls GPU destroy where applicable
```

A graphics context owns typed pools. Callers hold opaque handles; lookup maps
handle → GPU object. Context teardown waits for in-flight GPU/map work, then
releases pools and `device`/`swapchain`.

## myzig promotion

Playbook (`F-OWN-035`, `F-OWN-036`). `release` already discharges tracked
bindings; handle pools themselves are not modeled.

## Boundary

Does not track handle validity after `releaseResource` or pool exhaustion.
