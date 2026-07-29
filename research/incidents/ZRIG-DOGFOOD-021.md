# ZRIG-DOGFOOD-021 — loopback web serve + Head.invalidateStrings

## Context

V10 adds `zrig web serve` (127.0.0.1 HTTP UI + `POST /api/ask` mock) gated by
`net.listen`.

## Friction while shipping

1. **`readerExpectNone` invalidates `Head` strings** — must `dupe` the path
   before opening the body reader (F-ZRIG-022).
2. **`std.mem.trimRight` missing on Zig 0.17** — trim `\r\n` manually (F-OWN-071).
3. CI uses `--max-requests` so the server exits after the smoke client finishes.

## Proof

- Unit: `pathOnly` / `extractPrompt`
- `python3 scripts/web_smoke.py --bin ./zig-out/bin/zrig`

## Tips

- F-ZRIG-022, F-HARNESS-019, F-OWN-071
- Docs: `docs/V10.md`
