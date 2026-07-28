# ZRIG-DOGFOOD-007 — MCP serve is a scaffold stub

## Context

V3 starts with `zrig mcp list` / `call` / `serve`. Agents may assume `serve`
speaks MCP JSON-RPC over stdio immediately.

## Observation

`serve` prints an honest stub pointing at `docs/V3.md`. Real stdio protocol is
explicitly out of the scaffold slice.

## Friction tip

`F-HARNESS-006` in `docs/friction-playbook.md`.

## Promotion

Keep as playbook until JSON-RPC lands; then flip the tip and V3 success criteria.
