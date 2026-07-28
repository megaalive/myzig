# EXT-STUDY-048 — Wasm store owns instance memory

## Pattern

```zig
var store = ArrayListStore.init(alloc);
defer store.deinit(); // tears down functions/memories/tables
var memory = Memory.init(alloc, min, max);
defer memory.deinit();
```

A store holds shared runtime objects across modules. Linear memory grows by
pages; deinit frees the backing list. Imports/exports are handles into the store.

## myzig promotion

Playbook (`F-OWN-052`).

## Boundary

Does not model host↔guest pointer aliasing.
