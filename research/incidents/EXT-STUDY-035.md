# EXT-STUDY-035 — MemoryPool return and app init/deinit frames

## Pattern

```zig
const font = try pool.create();
errdefer pool.destroy(font);
// …
pool.destroy(font); // returns slot to pool — not always gpa.destroy
```

UI/framework layers allocate wrappers from `MemoryPool(T)` while the backend
owns GPU fonts/textures. App templates pair `init(app, allocator)` with
`deinit(app)`.

## myzig promotion

Playbook (`F-OWN-039`). Pool `create`/`destroy` stays multi-arg-skipped for
alloc acquire (`EXT-STUDY-009`).

## Boundary

Does not distinguish pool.destroy from allocator.destroy by type.
