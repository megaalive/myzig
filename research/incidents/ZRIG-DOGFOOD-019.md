# ZRIG-DOGFOOD-019 — SSE stream parser + ArrayList slice lifetime

## Context

V9 adds `--stream` (OpenAI `stream: true`) and an incremental SSE parser used to
accumulate chat-completion deltas.

## Friction while shipping

1. **Slice lifetime:** taking `line = residual.items[0..nl]` then
   `clearRetainingCapacity()` + rewrite residual invalidated `line` — tests saw
   empty content with no compile error. Fix: dupe line/rest before mutating the
   list (F-OWN-069).
2. **Honesty:** `Client.fetch` still buffers the HTTP body; `--stream` means
   wire+parse path, not first-token latency yet (F-ZRIG-020 / F-HARNESS-018).

## Proof

- Unit: every-byte SSE split; OpenAI content + tool_call fragment accumulate
- CI: `ask --provider mock --stream` → `"streamed": true`

## Tips

- F-OWN-069, F-ZRIG-020, F-HARNESS-018
- Docs: `docs/V9.md`
