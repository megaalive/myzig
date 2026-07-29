# ZRIG-DOGFOOD-026 — provider behind web/editor (V11)

## Context

`ask` already resolved openai_compat/gemini; `web serve` and `editor` were
hardcoded to mock, so the loopback UI could not dogfood remote providers.

## Fix

- Shared `src/model/resolve.zig` (flag → `ZRIG_PROVIDER` → mock; load key when needed)
- CLI flags on `web serve` / `editor` match `ask`
- Cap order: require `net.connect` before treating missing key as fatal
- `GET /api/meta` + initialize `provider`/`model` for honest discovery

## Tip

F-ZRIG-027 / F-HARNESS-022
