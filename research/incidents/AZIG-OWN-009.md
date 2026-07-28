# AZIG-OWN-009 — directory check path use-after-free

## Context

Running `myzig check` over azig's `src/` tree printed poisoned path strings
(`0xAA` / `¬` fills) in text and SARIF. Single-file checks looked fine.

## Root cause

`checkDir` joined a `child` path, passed it into analyzers that store the
pointer on diagnostics, then `defer gpa.free(child)` — findings kept a dangling
path.

## Fix

`check.Result.owned_paths` + dupe path in `checkFile` before analysis.

## Friction tip

`F-CLI-008` in `docs/friction-playbook.md`.
