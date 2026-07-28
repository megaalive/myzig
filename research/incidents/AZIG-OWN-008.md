# AZIG-OWN-008 — remaining ptrcast debt is product hygiene

## Summary

After struct-return / retarget / append / allocPrint calibration, `myzig check`
on azig `src/` reports **0** `memory.alloc-undischarged` findings.

Leftover hits were `unsafe.ptrcast-unremarked` on FFI/callback opaque casts
(`@ptrCast` / `@alignCast`) without an adjacent permit remark.

## Resolution

Annotated remaining sites with adjacent `// myzig.permit(ffi): …` (wildcard
covers both `ptrcast` and `aligncast` on chained casts). Verify:

```text
myzig check <azig>/src   # 0 unsafe.ptrcast-unremarked
```

## Why it matters

This is **not** a myzig detector FN. The coach already accepts adjacent
`// myzig.permit(…)` / `// safety: …` (`AZIG-OWN-005`). The legacy code simply
had not annotated those sites yet.

## Candidate action

- Keep annotating when new opaque callback casts appear
- Or `myzig adopt` / baseline if a ratchet gate is desired on the legacy tree
- Do **not** weaken the ptrcast rule to silence uncommented casts

## False-positive / fitting risk

Treating missing remarks as “not worth flagging” would erase the convention
signal agents need when editing FFI glue.
