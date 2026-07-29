# ZRIG-DOGFOOD-028 — untrack local `.cursor/mcp.json` + V13 deltas

## `.cursor` policy

- **myzig** `.cursor/rules/agent-dogfood.mdc` — **keep tracked** (shared agent contract).
- **zrig** `.cursor/mcp.json` — **untrack** (absolute Windows path to `zrig.exe`);
  gitignore `.cursor/` in zrig.

## V13

Editor/WS emit `message.delta` (faux for mock, live SSE sink for remote).
See `docs/V13.md`, F-ZRIG-029.
