# ZRIG-DOGFOOD-029 — live_push + dual build (V14)

## live_push

Unsolicited `{"event":…}` on stdio/WS. Smoke must stash push lines before
matching RPC `id`s (F-HARNESS-025). Output mutex: F-ZRIG-030.

## Dual build

`zig build` installs `zrig` (Debug) and `zrig-release` (ReleaseFast). See
`docs/BUILD.md`.
