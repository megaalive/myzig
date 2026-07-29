# ZRIG-DOGFOOD-040 — Content-Length hang was `readSliceShort`, not “Windows pipes”

## Context

V7 documented Windows Zig-spawn Content-Length as hanging (`PIPE_CLOSING`).
Batch `mcp_cl_smoke.py` passed; interactive Python and `mcp probe --framing content-length` hung until stdin EOF.

## Cause

`Io.Reader.readSliceShort` loops until the destination buffer is full or EOF.
After one CL frame (~hundreds of bytes) into a 4KiB tmp, the next fill blocked
while the peer waited for a response — classic request/response deadlock.
NDJSON used `takeDelimiterInclusive` and never hit this path.

## Fix

V25: `mcp_framing.readContentLength` uses `readSome` (buffered drain or one
`readVec`), then parses from residual. Writers emit `\r\n\r\n` headers.

## Friction tip

`F-ZRIG-041` / `F-HARNESS-016` / `F-ZRIG-018` (updated). Same class as F-ZRIG-021.
