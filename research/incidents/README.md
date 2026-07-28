# Incident lab

Rules (and compat/contract improvements) are born from incidents.

| Prefix | Channel |
|--------|---------|
| `AZIG-OWN-*` | Legacy product defects / patterns (azig) |
| `EXT-STUDY-*` | External pattern studies (brand-neutral; patterns only, not product clones) |
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
| `AZIG-OWN-004` | `list.append(try dupe)` collection transfer |
| `AZIG-OWN-005` | Adjacent-line ptrcast permits |
| `AZIG-OWN-006` | `return .{ .field = try dupe }` struct transfer |
| `AZIG-OWN-007` | Assignment retarget `out = next; return out` |
| `AZIG-OWN-008` | Azig memory-clean; remaining ptrcast remarks are product hygiene |
| `EXT-STUDY-001` | Empty defer/errdefer stubs → lifecycle rules |
| `EXT-STUDY-002` | Multi-line append ownership transfer |
| `EXT-STUDY-003` | Study boundary: CFG/ZIR/sentinel not cloned |
| `EXT-STUDY-004` | Hidden page/c allocator → `ownership.hidden-allocator` |
| `EXT-STUDY-005` | Swallow error + `myzig-disable-*` suppressions |
| `EXT-STUDY-006` | Study boundary: general lint / build-step hosts not cloned |
| `EXT-STUDY-007` | Field-store ownership transfer |
| `EXT-STUDY-008` | Arena-backed acquires |
| `EXT-STUDY-009` | `allocator.create(T)` vs method create; documented unreachable |
| `EXT-STUDY-010` | Phase-gated allocator capability (`PhaseAllocator`) |
| `EXT-STUDY-011` | Encode obligations as assertions (method, not density rules) |
| `EXT-STUDY-012` | init/deinit symmetry convention |
| `EXT-STUDY-013` | FFI external-resource blind spots (future) |
| `EXT-STUDY-014` | Completion/callback storage stability (playbook) |
| `EXT-STUDY-015` | Language repo as semantic reference, not app template |
| `ZRIG-DOGFOOD-001` | Clean prefer-compat ratchet baseline |
| `AGENT-STD-001` / `002` | std churn → compat + volatile rule |
| `AGENT-CLI-001` / `002` | Clean exits; exhaustive CLI / witness hash |
| `docs/LIMITS.md` | Published honest ceilings (`myzig limits`) |

See `docs/agent-friction.md` and `docs/friction-playbook.md`.
