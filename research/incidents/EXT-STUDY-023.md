# EXT-STUDY-023 — protocol destroy and listener teardown

## Pattern

```zig
const decoration = try gpa.create(Decoration);
errdefer gpa.destroy(decoration);
// …
decoration.destroy(); // method tears down protocol object then frees Zig wrapper
```

Event-driven stacks register listeners (`destroy` callback on a surface). When
the protocol object dies, the listener must free the Zig wrapper — and Zig
`init` is often paired with `.destroy`, not `.deinit`.

## myzig promotion

- `lifecycle.init-without-deinit` accepts `name.destroy` as matching teardown
- Playbook (`F-OWN-025`) for listener-owned teardown order

## Boundary

Does not prove the listener runs, or that `gpa.destroy` happens after protocol
`destroy`.
