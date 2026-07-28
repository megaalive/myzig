# EXT-STUDY-007 — field-store ownership transfer

## Pattern

```zig
self.name = try allocator.dupe(u8, src);
server.client_name = try server.allocator.dupe(u8, info.name);
lazy.value = try Context.create(handle, allocator);
```

Ownership moves into a longer-lived owner field; local free would be wrong.

## myzig promotion

- Same-line field assignment with an acquire on the RHS counts as transfer
- Two-step `const x = try …; self.field = x` also transfers (`MYZIG-OWN-003`)
- Certainty stays `likely`

## Boundary

Does not prove the field is later freed in `deinit`; documents local handoff only.
