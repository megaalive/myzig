# EXT-STUDY-031 — setup/shutdown and two-phase GPU destroy

## Pattern

```zig
sg.setup(.{});
defer sg.shutdown(); // tears down the whole gfx module

const img = sg.makeImage(...);
defer sg.destroyImage(img); // or uninit + dealloc for async creation
```

Minimal C-header graphics stacks use `setup`/`shutdown` for the module and
`destroy*` for individual resources. Async creation splits into `uninit` +
`dealloc` (slot recycle); `destroy` is the combined path.

## myzig promotion

- `name.shutdown` matches `lifecycle.init-without-deinit`
- `shutdown` / `dealloc` discharge alloc heuristics
- Playbook (`F-OWN-034`)

## Boundary

Does not model resource-state machines (ALLOC/VALID/FAILED).
