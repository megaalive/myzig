# ZRIG-DOGFOOD-001 — clean ratchet baseline on portable tool deck

## Summary

After myzig M3–M6 dogfood, zrig `src/` reports **0** ownership findings with
`myzig check --prefer-compat`, and CI gates with `check --ratchet` against a
tracked `.myzig/baseline.json` (total_findings: 0).

## Why it matters

Greenfield dogfood proves the coach loop (check → ratchet → receipt) without
forcing ownership wrappers. Compat insulation + prefer_compat holds on the deck.

## Evidence

- Tracked policy/baseline under zrig `.myzig/`
- CI: `myzig check --prefer-compat --ratchet src`

## Follow-ups

When findings appear, raise baseline only after intentional accept; record
`ZRIG-OWN-*` for real defects (not for toolchain noise — that is `AGENT-STD-*`).
