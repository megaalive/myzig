# ZRIG-DOGFOOD-004 — V2 agent tool-loop needs receipts

## Friction

Interactive `zrig run` is fine for humans, but agents need a **batch plan** and
an auditable **receipt** (which tools ran, ok/fail, sizes) without inventing
ownership policy mid-loop.

## Promotion

zrig V2: `zrig agent <plan> [--receipt path]` with line-oriented plans and JSON
receipts (`docs/V2.md`). Friction tips stay in the myzig playbook so other
harnesses learn the same pattern.

## Boundary

No embedded LLM in V2. Receipts record lengths, not full bodies (V0).
