# EXT-STUDY-059 — signature decode arenas and HPKE secrets

## Pattern

```zig
var arena = ArenaAllocator.init(child);
errdefer arena.deinit();
// decode signature / comments into arena
pub fn deinit(self: *Signature) void { self.arena.deinit(); }
```

Signing tools parse untrusted text into an arena owned by the Signature value.
HPKE contexts hold exporter/key material — treat like wipe-scoped secrets
(`EXT-STUDY-053`).

## myzig promotion

Playbook (`F-OWN-062`).

## Boundary

No automatic wipe of exporter secrets.
