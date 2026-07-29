# ZRIG-DOGFOOD-018 — multi-server MCP hub namespaces

## Context

V8 adds `--mcp-servers` / `.zrig/mcp_servers.json` so one ask turn can talk to
several MCP children. Tools are offered as `{server_id}.{remote_tool}`.

## Friction while shipping

1. Optional path after `--mcp-servers` must not swallow the prompt — only take
   tokens that look like paths (`.json` / `/` / `\`).
2. Server `id` must not contain `.` (namespace separator); duplicates rejected.
3. Prefer NDJSON framing for Windows Zig self-spawn (see ZRIG-DOGFOOD-017).
4. Exclusive with single-server `--mcp`.

## Proof

- Unit: `mcp_servers.zig` config parse
- CI: generated `mcp-hub-ci.json` → `mcp servers` / `mcp tools` / `ask --mcp-servers … tool:self.system.info`
- Receipt: `tools_source=mcp-hub`, tool step `server`

## Tips

- F-ZRIG-019 / F-HARNESS-017
- Docs: `docs/V8.md`, `examples/mcp_servers.example.json`
