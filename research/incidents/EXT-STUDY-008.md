# EXT-STUDY-008 — arena-backed acquires

## Pattern

```zig
const held = try analyser.arena.dupe(u8, slice);
const msg = try std.fmt.allocPrint(analyser.arena, "{s}", .{name});
```

Scratch allocations against a long-lived arena are discharged by the arena
owner (`deinit` / reset), not by a local `free`.

## myzig promotion

- Acquire lines that name an arena allocator token count as transferred
- Complements coarse `defer …deinit` discharge for local arenas
- Certainty stays `likely`

## Boundary

Does not model arena reset timing or cross-thread arena sharing.
