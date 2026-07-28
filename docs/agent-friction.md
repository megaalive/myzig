# Agent-authoring friction → myzig improvement

myzig is not only dogfooded by **zrig** and **azig**. It is also dogfooded by
**LLM coding agents** that write Zig — especially while building myzig/zrig
themselves — regardless of which IDE, CLI, or orchestration harness hosts them.

Why: future apps will often be created by agents in some harness. If the model
repeatedly trips on the same Zig/std/ownership hazards, those trips must become
durable guidance — often as **updatable text**, and only sometimes as new Zig code.

## Two landing zones

| Landing zone | When | Where |
|--------------|------|--------|
| **Text playbook** (default) | Tip, workaround, harness note, “do/don't” | `docs/friction-playbook.md` + optional `.myzig/friction-playbook.md` |
| **Code** (promote) | Repeated, automatable, needs CI teeth | `compat` / rule / explain / receipt / CLI |

```text
hit friction
  → append playbook entry (myzig friction)
  → optional AGENT-* incident
  → promote to code only if repeated or automatable
  → fixtures + tests when code lands
```

Run `myzig friction` (add `--sources` to see which files loaded).

## Loop (code path)

```text
1. Notice friction (build error, wrong ownership guess, noisy CLI, missing narrative)
2. Write/update playbook entry (and optional research/incidents/AGENT-*.md)
3. If promoting: smallest fix in myzig (compat | rule | explain | receipt | docs/CLI)
4. Add/adjust fixture when possible
5. Re-run agent loop: check → explain → repair intent → check → receipt
```

## What counts as friction

| Kind | Example | Typical landing zone |
|------|---------|----------------------|
| Std / toolchain churn | `std.fs.cwd` removed in 0.17 | playbook → then `myzig.compat` |
| Ownership ambiguity | agent adds `defer` on wrong intent | playbook + `explain` |
| Over-claiming | agent says “proven leak” from AST | playbook + `certainty_ceiling` |
| Harness/CI pain | private sibling dep breaks CI | **playbook text** (often enough) |
| Unusable output | stack traces on expected findings | playbook → then clean CLI exits |

## What does *not* count

- “Add a huge safe wrapper API” without a repeated incident
- Pretend borrow checker / dialect
- Inflating `proven` to sound confident
- Turning every one-off tip into a detector

## ID scheme

Incidents:

- `AGENT-STD-*` — std/toolchain insulation  
- `AGENT-OWN-*` — ownership reasoning mistakes  
- `AGENT-CLI-*` — coach CLI / receipt / exit-code ergonomics  
- `AGENT-HARNESS-*` — CI, vendor, multi-repo agent workflows  

Playbook entries: `F-STD-*`, `F-OWN-*`, `F-CLI-*`, `F-HARNESS-*`, `F-OTHER-*`.

## Seed from early sessions

- `docs/friction-playbook.md` — living tips (`myzig friction`)
- `research/incidents/AGENT-STD-001.md` — Zig 0.17 Io churn → `myzig.compat`
- `research/incidents/AGENT-STD-002.md` — opt-in `compat.volatile-std` coach signal
- `research/incidents/AGENT-CLI-001.md` — clean CLI exits (no stack traces)
