# ZRIG-DOGFOOD-055 — zig_edit Ast lite

## Context

fpagnt `pascal_edit` bar. zrig V42 adds `zig_edit` with `replace_fn` and
`rename_decl` via `std.zig.Ast` + re-parse; optional str_replace fallback.

## Do

`python scripts/zig_edit_smoke.py`. Root decls only — not cross-ref rename.

## Friction tip

`F-ZRIG-058` / `docs/V42.md`.
