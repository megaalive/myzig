# ZRIG-DOGFOOD-049 — SPA slash palette + @ file picker

## Context

fpagnt ships `/api/commands` + `/api/files` for the composer. zrig V36 matches
that surface for a **honest SPA subset** (`/help` `/clear` `/reset` `/cancel`
`/metrics`) and relative `@` paths under `--cwd`.

## Do

Hit the APIs or type `/` / `@` in `zrig web`. Reject `..` queries. Do not assume
fpagnt's full slash table.

## Friction tip

`F-ZRIG-052` / `docs/V36.md`.
