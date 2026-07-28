# EXT-STUDY-052 — tripwire injects errdefer failures

## Pattern

Improper `errdefer` is a top Zig bug source. Inject fail points (`try
tw.check(.alloc_buf)`) so unit tests exercise every cleanup path, then
`tw.end(.reset)`.

## myzig promotion

Playbook (`F-OWN-056`); agent-facing testing tip.

## Boundary

Not a seed rule — test harness pattern only.
