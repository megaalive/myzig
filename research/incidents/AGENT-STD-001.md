# AGENT-STD-001 — Zig 0.17 std.Io call-site churn

## Summary

While implementing zrig/myzig under Zig `0.17.0-dev`, agents and humans hit
repeated compile breaks: `std.fs.cwd`, `std.process.getEnvVarOwned`,
`std.time.timestamp`, and old Reader line APIs no longer matched the tree.

## Symptom

```text
error: root source file struct 'fs' has no member named 'cwd'
error: root source file struct 'process' has no member named 'getEnvVarOwned'
```

Apps rewritten to raw `std.Io.Dir.cwd().openFile(io, ...)` become brittle on the
next nearby toolchain bump.

## Why it matters for agents

LLM agents pattern-match on remembered std APIs. Zig std moves; agents reapply
stale shapes. Without a stable façade, every new project re-pays the same tax.

## Canonical improvement

`myzig.compat` — narrow versioned façade (`readFileAlloc`, `writeFile`,
`listDirAlloc`, `envGet`, `currentPathAlloc`, `unixSeconds`, …) with
`compat/zig_0_17.zig` adapter.

## Follow-ups

- Grow surface only when a new AGENT/ZRIG incident names a broken API  
- Keep coach rules aware of compat acquire/discharge when relevant  
- zrig (and future apps) prefer compat over raw volatile std  

## False-fitting risk

Do not absorb the entire stdlib. Compat stays small; ordinary Zig remains valid.
