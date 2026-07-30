# ZRIG-DOGFOOD-056 — zig_edit nested + same-file refs

## Context

V43 walks nested container methods and renames same-file identifier tokens
when `rename_refs` is true (default).

## Do

Nested `replace_fn` / unique `rename_decl` with call sites in the same file.

## Friction tip

`F-ZRIG-059` / `docs/V43.md`.
