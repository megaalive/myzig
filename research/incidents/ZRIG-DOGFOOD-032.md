# ZRIG-DOGFOOD-032 — providers.json + cost meter (no secrets in file)

## Context

Ask/web/editor took `--provider` / env only. There was no durable list of
provider → model → key-env → pricing. Agents either repeated flags or wanted
to stash API keys beside models.

## Friction

F-ZRIG-033 — profiles file with `api_key_env` (not the key), plus budget.

## Fix

- `.zrig/providers.json` via `zrig init` / `examples/providers.example.json`
- Resolve named profiles; meter `cost_usd` / `session_cost_usd`; `budget` warn|stop
- Docs: `docs/V17.md`
