# EXT-STUDY-046 — sockets close; global network init/deinit

## Pattern

```zig
network.init();
defer network.deinit();
const sock = try Socket.create(...);
defer sock.close();
```

Sockets pair create/open with `close`. Some stacks also require process-wide
`init`/`deinit` (Winsock). `close` is the teardown word — not `deinit`.

## myzig promotion

- `name.close` matches init-without-deinit
- `close`/`cancel` discharge alloc heuristics
- Playbook (`F-OWN-050`)

## Boundary

Does not prove OS handle uniqueness after close.
