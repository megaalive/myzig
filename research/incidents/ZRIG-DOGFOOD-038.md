# ZRIG-DOGFOOD-038 — nest ask tools + drop-oldest meter fanout

## Context

V22 recorded one opaque `ask` step and rejected WS past 32 fanout sinks.

## Friction

F-ZRIG-039 — `ask-tool` children with `parent_step`; subscribe replaces oldest.

## Fix

- `appendAskToolSteps` for plan + `--prompt`
- `Shared.subscribe` drop-oldest + `meter_fanout_replaced`
- Docs: `docs/V23.md`
