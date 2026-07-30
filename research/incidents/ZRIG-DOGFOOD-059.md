# ZRIG-DOGFOOD-059 — Cross-file Ast rename honesty

## Context

V46 `zig_edit` `cross_file=true` walks `.zig` under `root` and renames
identifier tokens. Agents may treat this like IDE rename-symbol.

## Error / trap

Expecting `@import("…")` path rewrite, ZIR semantics, or skipping same-named
locals in other files.

## Fix / guidance

Use unique primary decl; set `cross_file` + optional `root`/`max_files`.
See `docs/V46.md`, tip **F-ZRIG-062**.
