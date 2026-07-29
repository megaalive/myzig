# ZRIG-DOGFOOD-044 — complexity model routing

## Context

fpagnt 0.2.0 routes simple vs complex models from a prompt heuristic before the
completion call and announces `model.route_selected`. zrig V30 matches that
surface (config + CLI flags + receipt + editor event).

## Do

Enable only with both model ids set. Trust the documented score. Surface route
changes to agents/UI — never silent.

## Friction tip

`F-ZRIG-046` / `docs/V30.md`.
