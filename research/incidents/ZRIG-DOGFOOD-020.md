# ZRIG-DOGFOOD-020 — incremental SSE HTTP + readSliceShort trap

## Context

V9.1 moves `--stream` off `Client.fetch` buffering onto `Client.request` +
chunked body reads so the first OpenAI SSE content delta can be handled before
HTTP EOF (`--stream-progress` handshake).

## Friction while shipping

1. **`readSliceShort` fills the destination buffer** before returning. A 1KiB
   buf caused the first “read” to block until `[DONE]`, so the handshake timed
   out even though the first chunk was already on the wire (F-OWN-070 / F-ZRIG-021).
2. Fix: `peekGreedy(1)` + `toss` (one underlying `stream()` / typically one HTTP chunk).
3. Dupe peeked bytes before `toss` when feeding the SSE parser.

## Proof

- `python3 scripts/sse_stream_smoke.py --bin ./zig-out/bin/zrig`
- Receipt: `streamed` + `stream_incremental` on remote ask

## Tips

- F-OWN-070, F-ZRIG-021, F-HARNESS-018
- Docs: `docs/V9.1.md`
