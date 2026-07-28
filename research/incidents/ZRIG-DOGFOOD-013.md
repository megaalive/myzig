# ZRIG-DOGFOOD-013 — V5 MCP client NDJSON + proc.spawn

## Context

Shipping `zrig mcp probe` / `remote-call` to consume external MCP servers.
zrig serve speaks NDJSON; fpagnt uses Content-Length. Spawning the child needs
`proc.spawn`.

## Do

Grant `--allow proc.spawn`, pass server argv after `--`, smoke against self
`mcp serve`. Record F-HARNESS-012 / F-ZRIG-011.

## Friction tip

`F-HARNESS-012`.
