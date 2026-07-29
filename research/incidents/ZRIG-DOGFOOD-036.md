# ZRIG-DOGFOOD-036 — agent LLM loop needs `--prompt` + cost on receipts

## Context

V20 recorded plan-step wall time only. GROWTH next was LLM agent token/cost,
but the agent harness was still plan-file / tools-only.

## Friction

F-ZRIG-037 — `zrig agent --prompt` reuses `model.turn`; receipt schema 0.0.3
adds `mode:llm` + cost fields. `turn.run` returns an owned Receipt.

## Fix

- `agent.runLlm` + CLI `--prompt` / provider flags
- Docs: `docs/V21.md`
