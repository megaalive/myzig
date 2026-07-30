# ZRIG-DOGFOOD-060 — Undo lite vs conversation checkpoint

## Context

V47 adds process-local SHA-gated undo for write tools and lite HTML session
export. fpagnt also has `.checkpoint.json` for conversation restore — different.

## Error / trap

Expecting undo after process restart, or session-switch model-context restore
from `/api/undo` / HTML export.

## Fix / guidance

`GET|POST /api/undo` same process only; HTML is prompt/answer bubbles.
See `docs/V47.md`, tip **F-ZRIG-063**.
