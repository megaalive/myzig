# ZRIG-DOGFOOD-007 — MCP serve stdio (updated)

## Context

V3 started as `list` / `call` plus an honest `serve` stub. Agents must not treat
a stub as live MCP, and once stdio ships they must not expect full MCP feature
surface (resources, HTTP, OAuth, router).

## Observation

`zrig mcp serve` now speaks newline-delimited JSON-RPC for `initialize`,
`tools/list`, `tools/call`, and `ping`. Capability denials return
`isError: true` without killing the server. V4 router stays locked in
`docs/V4.md`.

## Friction tip

`F-HARNESS-006` in `docs/friction-playbook.md` (stdio tools-only).

## Promotion

Stdio handlers in zrig `src/mcp.zig`; CI pipes `examples/mcp-smoke.jsonl`.
