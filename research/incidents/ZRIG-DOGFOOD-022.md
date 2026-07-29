# ZRIG-DOGFOOD-022 — editor JSONL stdio protocol

## Context

V10.1 adds `zrig editor`: NDJSON session shaped like fpagnt's editor protocol
(`initialize`, `task.create`, `events.poll`, `reference.resolve`, `shutdown`).

## Friction / design notes

1. Request `id` is an idempotency key → `duplicate_request` on reuse (F-ZRIG-023).
2. V10.1 runs `task.create` **synchronously** (mock ask) and buffers events for
   `events.poll` — async worker/cancel/approval deferred.
3. `reference.resolve` rejects `..` and absolute paths.

## Proof

- Unit tests in `editor.zig`
- `python3 scripts/editor_smoke.py --bin ./zig-out/bin/zrig`

## Tips

- F-HARNESS-020 / F-ZRIG-023
- Docs: `docs/V10.1.md`
