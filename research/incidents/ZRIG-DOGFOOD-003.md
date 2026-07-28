# ZRIG-DOGFOOD-003 — expected zrig errors must not dump stack traces

## Friction

During dogfood, `CapabilityDenied` / `Usage` returned from `main` printed Zig
error-return traces. Coding agents treat traces as “binary crashed” and retry
randomly instead of granting a capability or fixing the plan.

## Symptom

```text
error: CapabilityDenied
…src/policy.zig:… in check …
```

## Fix

Mirror myzig `AGENT-CLI-001`: map expected errors to `std.process.exit(1|2)`
after flushing stderr. Do not `return err` from `main` for control-flow cases.

## myzig knowledge

Playbook `F-CLI-007`. Same class as myzig clean exits — dogfood apps should
rhyme with the coach CLI.

## Boundary

Unexpected failures may still print `@errorName`; traces stay off.
