# EXT-STUDY-025 — Load/Unload resource pairing

## Pattern

```zig
const target = try RenderTexture.init(w, h);
defer target.unload(); // not deinit / not allocator.destroy

const sound = try loadSound(path);
defer unloadSound(sound); // free-function unload also valid
```

Game/graphics C APIs often expose `Load*` / `Unload*` (method `.unload`) instead
of Zig `init`/`deinit`. GPU and audio resources are opaque extern structs; GPA
leak checks do not see them.

## myzig promotion

- `lifecycle.init-without-deinit` accepts `name.unload` as matching teardown
- `memory.alloc-undischarged` treats `unload` like `free`/`destroy`/`release`
- Playbook (`F-OWN-027`)

## Boundary

Does not invent a `Load*` acquire detector; multi-arg loads stay invisible to
alloc heuristics (`EXT-STUDY-009`).
