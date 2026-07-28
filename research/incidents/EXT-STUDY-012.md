# EXT-STUDY-012 — init/deinit symmetry

## Pattern

```zig
var loop = try Loop.init(.{});
defer loop.deinit();
```

Caller-owned resources constructed with `.init(` need a matching `.deinit`
unless ownership is transferred (`return loop`).

## myzig promotion

- Convention rule: `lifecycle.init-without-deinit`
- Certainty ceiling: `convention` (not every `.init` is a resource)

## Boundary

Does not model async completion objects still in flight after `deinit`.
