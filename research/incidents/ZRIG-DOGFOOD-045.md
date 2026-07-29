# ZRIG-DOGFOOD-045 — lexical search_code / index

## Context

fpagnt 0.2.0 ships `search_code` + `/index` with embedding-or-BM25. zrig V31
matches the **lexical** path first so agents can find code offline.

## Do

`zrig index` then `search_code`. Expect path:range + snippet. Rebuild after large edits.

## Friction tip

`F-ZRIG-047` / `docs/V31.md`.
