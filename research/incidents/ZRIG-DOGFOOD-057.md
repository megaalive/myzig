# ZRIG-DOGFOOD-057 — server sessions JSONL

## Context

V44 stores turns under `.zrig/sessions/*.jsonl` with list/new/append/export.
Not fpagnt HTML/undo/checkpoint restore.

## Do

SPA session sidebar + `/api/sessions`. Exclude `.zrig/` from git.

## Friction tip

`F-ZRIG-060` / `docs/V44.md`.
