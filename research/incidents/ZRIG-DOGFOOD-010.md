# ZRIG-DOGFOOD-010 — Cursor MCP Windows spawn path

## Context

Dogfooding `zrig mcp serve` from Cursor on Windows fails when `command` omits
`.exe` or relies on an unresolved `${workspaceFolder}` form.

## Do

Check in `.cursor/mcp.json` with an absolute `zrig.exe` for this repo, document
in `docs/mcp-client.md`, and keep `scripts/mcp-smoke.ps1` as host-free proof.

## Friction tip

`F-HARNESS-008`.
