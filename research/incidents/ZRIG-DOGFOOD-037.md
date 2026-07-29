# ZRIG-DOGFOOD-037 — plan files need `ask` steps with cost rollup

## Context

V21 added `agent --prompt` only. GROWTH next was mid-plan LLM steps plus
fanout cap visibility.

## Friction

F-ZRIG-038 — `ask <prompt>` in plans; provider flags on plan mode; receipt
`plan+llm` / schema 0.0.4; `meter_fanout_rejected` on meta.

## Fix

- `runPlan` ask branch + `examples/agent-ask.plan`
- Shared `subscribe_rejected` counter
- Docs: `docs/V22.md`
