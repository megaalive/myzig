# Agent-authoring friction → myzig improvement

myzig is not only dogfooded by **zrig** and **azig**. It is also dogfooded by
**LLM coding agents** that write Zig — especially while building myzig/zrig
themselves — regardless of which IDE, CLI, or orchestration harness hosts them.

Why: future apps will often be created by agents in some harness. If the model
repeatedly trips on the same Zig/std/ownership hazards, those trips must become
durable myzig behavior (compat, rules, explain, receipts, contracts), not
one-off session knowledge.

## Loop

```text
1. Notice friction (build error, wrong ownership guess, noisy CLI, missing narrative)
2. Write research/incidents/AGENT-*.md (concrete command/error/assumption)
3. Smallest fix in myzig (prefer: compat | rule | explain | receipt | docs/CLI)
4. Add/adjust fixture when possible
5. Re-run agent loop: check → explain → repair intent → check → receipt
```

## What counts as friction

| Kind | Example | Typical myzig landing zone |
|------|---------|----------------------------|
| Std / toolchain churn | `std.fs.cwd` removed in 0.17 | `myzig.compat` adapter |
| Ownership ambiguity | agent adds `defer` on wrong intent | `explain` repair choices |
| Over-claiming | agent says “proven leak” from AST | `certainty_ceiling` |
| Harness/CI pain | private sibling dep breaks CI | docs + vendor/sync policy |
| Unusable output | stack traces on expected findings | clean process exit + receipt JSON |

## What does *not* count

- “Add a huge safe wrapper API” without a repeated incident
- Pretend borrow checker / dialect
- Inflating `proven` to sound confident

## ID scheme

- `AGENT-STD-*` — std/toolchain insulation  
- `AGENT-OWN-*` — ownership reasoning mistakes  
- `AGENT-CLI-*` — coach CLI / receipt / exit-code ergonomics  
- `AGENT-HARNESS-*` — CI, vendor, multi-repo agent workflows  

## Seed from early sessions

See `research/incidents/AGENT-STD-001.md` (Zig 0.17 Io churn → compat).
