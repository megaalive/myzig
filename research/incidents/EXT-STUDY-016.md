# EXT-STUDY-016 — request-scoped arena reset

## Pattern

Long-lived connection owns a request arena. Between requests:

```zig
_ = self.req_arena.reset(.{ .retain_with_limit = n });
```

Handlers may `dupe`/`allocPrint` into `req.arena` without local `free`; reset
reclaims (optionally retaining a byte limit for keepalive).

## myzig stance

- Arena-token acquires already transfer (`EXT-STUDY-008`)
- Document reset-with-retain as the request boundary, not a leak
- Do not require static-only allocation for servers

## Boundary

Does not model which bytes survive `retain_with_limit`.
