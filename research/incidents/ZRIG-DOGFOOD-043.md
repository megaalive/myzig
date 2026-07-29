# ZRIG-DOGFOOD-043 — update_plan + reasoning.delta SPA events

## Context

fpagnt 0.2.0 shows a live Task checklist (`update_plan` / `plan.updated`) and a
collapsible thinking panel (`reasoning.delta`). zrig V28/V29 match that surface
on the mock/editor/web path.

## Do

Call `update_plan` with a full `plan` array. Listen for `plan.updated` and
`reasoning.delta` on live push. Keep reasoning out of receipt final text.

## Friction tip

`F-ZRIG-044` / `F-ZRIG-045` / `docs/V28.md` / `docs/V29.md`.
