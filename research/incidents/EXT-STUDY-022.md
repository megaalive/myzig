# EXT-STUDY-022 — handle release vs allocator destroy

## Pattern

```zig
const view = try device.createView(...); // external / GPU-style handle
defer view.release();                    // refcount / API release — not free()
// vs
const node = try gpa.create(Node);
defer gpa.destroy(node);                 // Zig heap
```

GPU and protocol handles often use `.release()` / `.destroy()` on the object;
Zig heap objects use `allocator.destroy`. Mixing them leaks or double-frees.

## myzig promotion

- `memory.alloc-undischarged` treats `release` like `free`/`destroy`/`deinit`
  (defer mention + `name.release(` / `.release(name)`)
- Playbook (`F-OWN-024`) for createView / swapchain per-frame release habits

## Boundary

Multi-arg `.create(` acquires stay skipped (`EXT-STUDY-009`); release discharge
helps when the binding is already tracked or a coarse defer mentions release.
