# EXT-STUDY-033 — WebGPU destroy, release, and mid-scope unmap

## Pattern

```zig
defer buffer.release();   // drop refcount / free wrapper
buffer.destroy();         // invalidate GPU object (may be separate)
defer buffer.unmap();     // mapped ranges need unmap before teardown

const pass = encoder.beginComputePass(...);
// Must release pass here — not only at function end (API quirk / ordering).
pass.release();
```

Some GPU objects expose both `destroy` (invalidate) and `release` (drop). Pass
encoders may need immediate release after `end`. Mapped buffers need `unmap`.

## myzig promotion

- `unmap` discharges alloc heuristics (defer / method)
- Playbook (`F-OWN-037`); strengthens release/destroy tips (`EXT-STUDY-022`)

## Boundary

Does not enforce destroy-before-release ordering or pass-encoder timing.
