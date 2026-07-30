# ZRIG-DOGFOOD-048 — optional embeddings for search_code

## Context

fpagnt enables cosine search when `embeddings.enabled`; otherwise BM25. zrig V35
adds the same gate: `--mock-embed` for offline CI, OpenAI-compat `/embeddings`
when configured, lexical fallback always.

## Do

Rebuild with `zrig index --mock-embed` (or `--embed` + API key). Keep BM25 as
the zero-network path. Match query embedder to store `embed_mode`.

## Friction tip

`F-ZRIG-051` / `docs/V35.md`.
