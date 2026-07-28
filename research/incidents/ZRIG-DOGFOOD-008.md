# ZRIG-DOGFOOD-008 — named MCP tool arguments

## Context

Generic `args: string[]` works for CLI parity but MCP hosts (and models) do
better with explicit fields like `host`, `path`, and `url`.

## Observation

zrig `tools/list` now advertises per-tool `inputSchema` fields while keeping
`args` as an escape hatch. Unordered string-property fallback is last resort.

## Friction tip

`F-HARNESS-007` in `docs/friction-playbook.md`.

## Promotion

Per-tool schemas live in zrig `src/mcp.zig` (`writeInputSchema` / `collectArgs`).
