# MYZIG-OWN-004 — named ownership handoff and same-file callee free

## Summary

After M9b, two named gaps remained in chat: opaque `takeOwnership(buf)` and
cross-function callee free. Those counts as debt once named (`F-AGENT-003`).

## Patterns

```zig
const buffer = try allocator.alloc(u8, n);
takeOwnership(buffer);

fn adoptBuf(allocator: anytype, buf: []u8) void {
    defer allocator.free(buf);
}
// caller:
adoptBuf(allocator, buffer);
```

## myzig promotion

- Explicit handoff needles: `takeOwnership` / `assumeOwnership` / `adoptOwnership` /
  `intoOwned` / `stealOwnership` / `consumeOwned` / `takeOwned`
- Same-file only: call `foo(..., binding)` where `fn foo` releases the matching
  parameter (arg index → param name → `.free`/`.destroy`/method discharge)

## Boundary

- Does **not** follow callees in other files / packages
- Does **not** treat arbitrary `foo(buf)` as transfer without a freeing callee or
  a named handoff needle
- Certainty remains `likely`

## Fixtures

- `fixtures/pass/alloc_take_ownership.zig`
- `fixtures/pass/alloc_callee_free.zig`
