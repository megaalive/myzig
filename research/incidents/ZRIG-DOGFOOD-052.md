# ZRIG-DOGFOOD-052 — surgical str_replace (not Ast)

## Context

fpagnt ships AST `pascal_edit`. zrig V39 closes the honesty gap with
`files.str_replace`: unique old→new only. Ask/MCP must pass the full
arguments JSON so multiline needles survive.

## Do

`zrig run --allow fs.read --allow fs.write -- files.str_replace …`
and `python scripts/str_replace_smoke.py`. Expect fail on 0 or >1 matches.

## Friction tip

`F-ZRIG-055` / `docs/V39.md`.
