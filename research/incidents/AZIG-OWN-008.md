# AZIG-OWN-008 — remaining ptrcast debt is product hygiene

## Summary

After struct-return / retarget / append / allocPrint calibration, `myzig check`
on azig `src/` reports **0** `memory.alloc-undischarged` findings.

The leftover ~25 hits are all `unsafe.ptrcast-unremarked` on FFI/callback
opaque casts (`@ptrCast` / `@alignCast`) without an adjacent permit remark.

## Why it matters

This is **not** a myzig detector FN. The coach already accepts adjacent
`// myzig.permit(ptrcast): …` / `// safety: …` (`AZIG-OWN-005`). The legacy
code simply has not annotated those sites yet.

## Candidate action

- Optional: add permits in azig when touching those call sites
- Or `myzig adopt` / baseline if a ratchet gate is desired on the legacy tree
- Do **not** weaken the ptrcast rule to silence uncommented casts

## False-positive / fitting risk

Treating missing remarks as “not worth flagging” would erase the convention
signal agents need when editing FFI glue.
