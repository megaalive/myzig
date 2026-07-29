# ZRIG-DOGFOOD-017 — Content-Length framing + Windows spawn hang

## Context

V7 adds `--framing content-length` for MCP serve/client (fpagnt parity).
Serve framing is proven via piped binary frames. On Windows, Zig-spawned
client↔server CL sessions can hang with `PIPE_CLOSING`.

## Do

Match framing both sides. Use `python3 scripts/mcp_cl_smoke.py` for serve proof.
Prefer NDJSON for Windows self-spawn until pipes are fixed.

## Friction tip

`F-HARNESS-016` / `F-ZRIG-018`.
