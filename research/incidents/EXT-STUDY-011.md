# EXT-STUDY-011 — encode obligations as assertions

## Pattern

Build a mental model → encode it as assertions (pre/post/invariant) → explain
in code → use fuzzing/simulation as the last line of defense.

Programmer errors crash via assert; operational errors are handled.

## myzig alignment

| External idea | myzig surface |
|---------------|---------------|
| Mental model | obligation kinds |
| Assertions | evidence / permits / local facts |
| Explain in code | `myzig explain` repair intents |
| Last-line defense | receipts + ratchet + verify-cost |

## Not promoted

Mandatory assertion density, function line caps, or “all memory at startup”.
Those are domain policies, not universal ownership rules.
