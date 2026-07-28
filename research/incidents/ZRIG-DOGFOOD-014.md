# ZRIG-DOGFOOD-014 — ask --mcp double-dash + via receipt

## Context

V5.1 merges MCP client into `zrig ask`. Tool calls share one NDJSON session.
CLI uses two `--` separators: server argv, then prompt. Receipt records `via: mcp`.

## Do

`--allow proc.spawn --mcp -- <server…> -- <prompt>`. Verify receipt `via`.
If handshake fails with silence, smoke `mcp serve` alone (child stderr ignored).

## Friction tip

`F-HARNESS-013` / `F-ZRIG-013` / `F-ZRIG-014`.
