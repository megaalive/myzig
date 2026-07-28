# ZRIG-DOGFOOD-011 — MCP tool errors stay in-band

## Context

Host-parity smoke of `zrig mcp serve`: `net.tcp.probe` to a closed
`127.0.0.1:1` returns `tools/call` with `isError: true` and
`ConnectionRefused` text. The stdio server keeps running for later calls.

## Do

Treat `isError` as a normal tool outcome. Do not restart the MCP process or
rewrite Client wiring because one probe failed.

## Friction tip

`F-HARNESS-009`.
