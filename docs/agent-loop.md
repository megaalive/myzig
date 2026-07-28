# Agent loop (M1)

Deterministic self-correction loop for coding agents using myzig:

```text
1. myzig check <path>
2. pick a finding (file:line)
3. myzig explain <file:line>
4. choose a repair intent from the listed options (do not invent policy)
5. apply the repair in source
6. myzig check <path>   # expect 0 findings
7. myzig receipt <path> # optional observed evidence
```

## Example (fixtures)

```text
myzig check fixtures/fail/alloc_undischarged.zig
myzig explain fixtures/fail/alloc_undischarged.zig:11
# choose intent=local_lifetime → add defer free (see pass fixture)
myzig check fixtures/pass/alloc_defer_free.zig
myzig receipt fixtures/pass/alloc_defer_free.zig
```

Agents must not claim `proven` above a rule's `certainty_ceiling`.
Receipts only include `claimed` witnesses when a verify step actually ran.

When the agent itself stumbles (std churn, unclear repair, CI harness), capture
it as `AGENT-*` friction — see `docs/agent-friction.md`.
