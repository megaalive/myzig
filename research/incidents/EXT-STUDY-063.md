# EXT-STUDY-063 — C-runtime HTTP façades use request arenas

## Pattern

```zig
// Per-thread ArenaAllocator behind the Zig App; endpoints receive arena Allocator
track_arenas: AutoHashMapUnmanaged(Thread.Id, ArenaAllocator) = .empty;
// App.deinit drains every tracked arena then the endpoint table
```

Some HTTP stacks wrap a C event/HTTP runtime. Zig ownership still applies to
auth tokens, routers, and per-request arenas, but sockets/protocol objects may
close through the C layer (`on_close`, force_close) — sibling of FFI wrap
(`EXT-STUDY-018`) and connection arenas (`EXT-STUDY-044`). Prefer pure-Zig
servers when studying idiomatic GPA/arena graphs; use façades to learn the
boundary, not as the primary ownership template.

## myzig promotion

Playbook (`F-OWN-064`). Study boundary: do not import C-runtime APIs into seed
detectors.

## Boundary

Does not model fio/libuv-style callback graphs.
