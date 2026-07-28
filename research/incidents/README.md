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
| `MYZIG-OWN-003` | Two-step field store + collection put/insert transfers |
| `MYZIG-OWN-004` | Named takeOwnership handoff + same-file callee free |
| `MYZIG-OWN-005` | FFI wrapper init without deinit (C handle) |
| `AZIG-OWN-001` | Arena + coarse defer discharge limits |
| `AZIG-OWN-002` | Out-param / one-hop rename transfers |
| `AZIG-OWN-003` | `allocPrint` / related acquires were invisible |
| `AZIG-OWN-004` | `list.append(try dupe)` collection transfer |
| `AZIG-OWN-005` | Adjacent-line ptrcast permits |
| `AZIG-OWN-006` | `return .{ .field = try dupe }` struct transfer |
| `AZIG-OWN-007` | Assignment retarget `out = next; return out` |
| `AZIG-OWN-008` | Azig ptrcast hygiene annotated (`myzig.permit(ffi)`) |
| `EXT-STUDY-001` | Empty defer/errdefer stubs ? lifecycle rules |
| `EXT-STUDY-002` | Multi-line append ownership transfer |
| `EXT-STUDY-003` | Study boundary: CFG/ZIR/sentinel not cloned |
| `EXT-STUDY-004` | Hidden page/c allocator ? `ownership.hidden-allocator` |
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
| `EXT-STUDY-016` | Request-scoped arena reset / retain limit |
| `EXT-STUDY-017` | Query result deinit may release a pool connection |
| `EXT-STUDY-018` | FFI wrapper deinit closes C handle |
| `EXT-STUDY-019` | Fixed-region / linker-heap allocators |
| `EXT-STUDY-020` | Indexed out-store + init returned in struct |
| `EXT-STUDY-021` | Nested owner scopes outlive children |
| `EXT-STUDY-022` | Handle `release` vs allocator `destroy` |
| `EXT-STUDY-023` | Protocol `destroy` + listener teardown |
| `EXT-STUDY-024` | Lasting vs scratch allocator naming |
| `EXT-STUDY-025` | Load/Unload resource pairing (`.unload`) |
| `EXT-STUDY-026` | Staging unload + graphics context order |
| `EXT-STUDY-027` | begin/end mode scopes |
| `EXT-STUDY-028` | Post-Zig runtime = allocator-shape reference only |
| `EXT-STUDY-029` | Borrowed arena ptr + null?global fallback |
| `EXT-STUDY-030` | Single-buffer scratch + nullable allocator |
| `EXT-STUDY-031` | setup/shutdown + two-phase GPU destroy/dealloc |
| `EXT-STUDY-032` | Handle pools; releaseResource; drain GPU first |
| `EXT-STUDY-033` | WebGPU destroy/release/unmap + mid-scope release |
| `EXT-STUDY-034` | Managed Context vs borrowed Surface |
| `EXT-STUDY-035` | MemoryPool return + app init/deinit frames |
| `EXT-STUDY-036` | Binding generators ? Destroy* naming only |
| `EXT-STUDY-037` | Physical frame allocators ? Zig Allocator |
| `EXT-STUDY-038` | Layered PMM ? VMM ? kernel heap |
| `EXT-STUDY-039` | Boottime FBA sealed before runtime heap |
| `EXT-STUDY-040` | Bump linker RAM with no free |
| `EXT-STUDY-041` | Page-table ownership bits / refcount |
| `EXT-STUDY-042` | Guest quotas vs hypervisor heap |
| `EXT-STUDY-043` | Event-loop completions + cancel; zero runtime alloc |
| `EXT-STUDY-044` | Connection arena reset with retain limit |
| `EXT-STUDY-045` | Pooled buffer provider release/promote |
| `EXT-STUDY-046` | Socket close + global network init/deinit |
| `EXT-STUDY-047` | TLS close_notify + key material lifetime |
| `EXT-STUDY-048` | Wasm store owns instance memory |
| `EXT-STUDY-049` | Image PixelStorage same-allocator deinit |
| `EXT-STUDY-050` | Steady-state zero alloc / static limits |
| `EXT-STUDY-051` | LSP DocumentStore = tooling-shaped |
| `EXT-STUDY-052` | Tripwire injects errdefer failures |
| `EXT-STUDY-053` | Crypto keys are wipe-scoped secrets |
| `EXT-STUDY-054` | Finish external-study shortlists in one batch |
| `EXT-STUDY-055` | UEFI BootServices pool + exitBootServices |
| `EXT-STUDY-056` | Type-2 HV host allocator vs guest RAM |
| `EXT-STUDY-057` | Type-1 HV page allocator + EPT |
| `EXT-STUDY-058` | Fuller OS layered reclaim (confirmation) |
| `EXT-STUDY-059` | Signature decode arenas + HPKE exporters |
| `EXT-STUDY-060` | Minimal kernels / SBI ? no Zig heap |
| `EXT-STUDY-061` | Clone blockers still require API survey |
| `EXT-STUDY-062` | Cadangan / optional names are part of the set |
| `EXT-STUDY-063` | C-runtime HTTP facades + request arenas |
| `EXT-STUDY-064` | Sentinel type-loss same-line `[]u8` binding |
| `ZRIG-DOGFOOD-001` | Clean prefer-compat ratchet baseline |
| `ZRIG-DOGFOOD-002` | `envGetOrNull` for optional env vars |
| `AGENT-STD-001` / `002` | std churn ? compat + volatile rule |
| `AGENT-CLI-001` / `002` | Clean exits; exhaustive CLI / witness hash |
| `AGENT-STUDY-001` | Finish named external-study shortlists |
| `AGENT-STUDY-002` | Cadangan / link-only recommendations are debt |
| `AGENT-CI-001` | Private Actions empty-step failures = billing / spending limit |
| `docs/LIMITS.md` | Published honest ceilings (`myzig limits`) |

See `docs/agent-friction.md` and `docs/friction-playbook.md`.
