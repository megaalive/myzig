# ZRIG-DOGFOOD-015 — ask --mcp tools/list catalog

## Context

V5.2: with `--mcp`, ask discovers tools via `tools/list` and advertises that
catalog to the provider. Receipt records `tools_source` / `tools_offered`.

## Do

Check receipt after MCP ask. Mock refuses `tool:<missing>`.

## Friction tip

`F-HARNESS-014` / `F-ZRIG-015`.
