# Incident lab

Rules (and compat/contract improvements) are born from incidents.

| Prefix | Channel |
|--------|---------|
| `AZIG-OWN-*` | Legacy product defects / patterns (azig) |
| `ZRIG-OWN-*` / `ZRIG-DOGFOOD-*` | Greenfield dogfood (zrig) |
| `MYZIG-OWN-*` | Coach self-tests / fixtures |
| `AGENT-*` | LLM/agent authoring friction (std, ownership, CLI, harness) |

## Seed set (M7)

| ID | Role |
|----|------|
| `MYZIG-OWN-001` | Fixture alloc undischarged loop |
| `MYZIG-OWN-002` | Explicit free without defer |
| `AZIG-OWN-001` | Arena + coarse defer discharge limits |
| `AZIG-OWN-002` | Out-param / one-hop rename transfers |
| `AZIG-OWN-003` | `allocPrint` / related acquires were invisible |
| `ZRIG-DOGFOOD-001` | Clean prefer-compat ratchet baseline |
| `AGENT-STD-001` / `002` | std churn → compat + volatile rule |
| `AGENT-CLI-001` / `002` | Clean exits; exhaustive CLI / witness hash |
| `docs/LIMITS.md` | Published honest ceilings (`myzig limits`) |

See `docs/agent-friction.md` and `docs/friction-playbook.md`.
