# Analyzer blind spots (honest limits)

myzig's early detectors are **local heuristics**, not whole-program proof.

**Published agent-facing summary:** `docs/LIMITS.md` (`myzig limits`).

## Known blind spots

| Area | Limitation |
|------|------------|
| Path sensitivity | Conditional free/close may be treated as function-wide discharge |
| Transfers | Return / out-param / indexed-out / rename / retarget / field-store (same-line + two-step binding) / `return .{ fields }` / append / put / insert / arena-backed / named takeOwnership* / same-file callee that frees matching param; other-file callee frees still weak |
| Aliasing | Exact RHS rename closure (bounded) is followed for transfer/free; wrapper APIs stay invisible |
| Local free | `.free`/`.destroy`/`.release`/`.unload`/`.dealloc`/`.unmap`/`.cancel`/`.close`(name) and `name.deinit`/`.destroy`/`.release`/`.unload`/`.shutdown`/`.dealloc`/`.unmap`/`.cancel`/`.close(` discharge that binding; coarse function-wide `defer …` discharge remains for arena-style sites |
| Permits | `@ptrCast`/`@alignCast` accept permit/safety on adjacent lines (prev/curr/next) |
| Cross-function | Same-file callee that frees the matching param is transfer (`MYZIG-OWN-004`); other files / packages out of scope |
| Arenas | Arena-scoped lifetimes are not modeled beyond coarse `defer …deinit` discharge (see `AZIG-OWN-001`) |
| Double-free / UAF | Not modeled (CFG territory — see `EXT-STUDY-003`) |
| Sentinel types | `.dupeZ` / allocSentinel acquire tracked; sentinel→`[]u8` type-loss not modeled |
| Zig AST/ZIR | Token/text scan, not Zig Ast or ZIR CFG |
| Certainty | Heuristics emit at most `likely` / `convention` |
| Compat preference | `compat.volatile-std` is opt-in (`--prefer-compat` / `.myzig/prefer_compat`) |
| Adapter paths | Volatile-std detector skips `compat/` sources by path heuristic |
| Comments | Needle hits after `//` on the same line are ignored (M7 FP guard) |
| SARIF | Forge-oriented SARIF 2.1.0 (`ruleIndex`, fingerprints, `automationDetails`, `helpUri`); CI may upload on ubuntu (`continue-on-error`) |
| Hidden allocators | Needle-based (`page_allocator` / `c_allocator`); aliased heaps / non-call uses FN (`EXT-STUDY-004`) |
| Swallow errors | Empty catch always; bare `catch unreachable` flagged; adjacent-comment unreachable allowed |
| Suppressions | Line-scoped `myzig-disable-*` only (not multi-line enable/disable regions) |
| General lint | Naming, unused, braces, build-step AST hosts — out of product scope (`EXT-STUDY-006`) |
| `.create(` | Single-arg only (`allocator.create(T)`); multi-arg methods skipped (`EXT-STUDY-009`) |
| Arena acquires | Token heuristic (`arena` / `arena_allocator` / `scratch_allocator` / `scratch.`); does not prove arena/scratch reset |
| FFI / C boundaries | Zig allocator tracking does not prove external cleanup; FFI-shaped init uses `ffi.wrapper-init-without-deinit` (`EXT-STUDY-013`, `MYZIG-OWN-005`) |
| Async completions | Outstanding submissions after deinit not modeled (`EXT-STUDY-014`) |
| Phase allocators | Optional helper only; sealed-phase misuse is assert-time, not a check rule |
| Language semantics | Prefer std/compiler truth over folk patterns (`EXT-STUDY-015`) |
| Request arenas | Reset/retain boundaries documented; not path-sensitive (`EXT-STUDY-016`) |
| Pooled resources | `deinit` may release pool handles — not modeled beyond playbook (`EXT-STUDY-017`) |
| FFI wrappers | C `close`/`finalize` inside Zig `deinit` is convention, not a seed rule yet (`EXT-STUDY-018`) |
| Region heaps | Linker/fixed-buffer allocators are playbook/helper territory (`EXT-STUDY-019`) |
| Nested owners | Parent/child finalizer pools are playbook only (`EXT-STUDY-021`) |
| Handle release | `release` discharges tracked bindings; multi-arg GPU create still skipped (`EXT-STUDY-022`) |
| Protocol destroy | `name.destroy` matches init convention; listeners not modeled (`EXT-STUDY-023`) |
| Load/Unload | `name.unload` matches init; no `Load*` acquire detector (`EXT-STUDY-025`) |
| Context order | GPU-after-window and staging unload are playbook only (`EXT-STUDY-026`) |
| begin/end modes | Mode stacks not tracked (`EXT-STUDY-027`) |
| Post-Zig samples | Non-Zig runtimes teach shapes only — not detectors (`EXT-STUDY-028`) |
| Borrowed arenas | Outlives + null→global dual heap not modeled (`EXT-STUDY-029`) |
| Scratch buffers | Single-buffer / nullable allocator APIs are playbook (`EXT-STUDY-030`) |
| setup/shutdown | `shutdown`/`dealloc` discharge; resource state machines not modeled (`EXT-STUDY-031`) |
| Handle pools | Opaque GPU handles / releaseResource are playbook (`EXT-STUDY-032`) |
| destroy+release | Dual teardown + unmap timing not ordered (`EXT-STUDY-033`) |
| Context/Surface | Borrowed surface + same-alloc lifetime playbook (`EXT-STUDY-034`) |
| Memory pools | Pool vs GPA destroy not distinguished (`EXT-STUDY-035`) |
| Binding gens | Generators are naming references only (`EXT-STUDY-036`) |
| Phys frames | PMM/buddy/stack APIs not modeled as Allocator (`EXT-STUDY-037`) |
| Memory layers | PMM/VMM/heap free graphs are playbook (`EXT-STUDY-038`) |
| Boottime heaps | `boottime_allocator` token only; seal not proven (`EXT-STUDY-039`) |
| Bump RAM | Linker bump allocators invisible to alloc needles (`EXT-STUDY-040`) |
| PTE ownership | Ownership/refcount flags not parsed (`EXT-STUDY-041`) |
| Guest isolation | Hypervisor quotas playbook only (`EXT-STUDY-042`) |
| Event-loop cancel | `cancel`/`close` discharge; outstanding ops not CFG (`EXT-STUDY-043`, `046`) |
| Conn arenas | Keep-alive retain limits playbook (`EXT-STUDY-044`) |
| Buffer pools | Pool vs heap promotion not tracked (`EXT-STUDY-045`) |
| TLS secrets | close_notify / wipe playbook (`EXT-STUDY-047`, `053`) |
| Wasm stores | Store/memory graphs playbook (`EXT-STUDY-048`) |
| Image allocators | Same-alloc identity not proven (`EXT-STUDY-049`) |
| Static steady-state | Zero-alloc hot paths not proven (`EXT-STUDY-050`) |
| Tooling stores | LSP/DocumentStore = boundary (`EXT-STUDY-051`) |
| Tripwire | errdefer injection is test harness only (`EXT-STUDY-052`) |
| Study batching | Named shortlists (incl. cadangan/optional) must be finished or dated (`EXT-STUDY-054`, `062`) |
| UEFI BootServices | Pool/map-key/exit not modeled (`EXT-STUDY-055`) |
| HV guest RAM | Memslots/EPT vs host GPA playbook only (`EXT-STUDY-056`, `057`) |
| Clone blockers | Failed checkout ≠ unpaid skip; API survey required (`EXT-STUDY-061`) |
| C-HTTP façades | Runtime close graphs not detectors (`EXT-STUDY-063`) |

## Product stance

Prefer a small set of stable rules with documented blind spots over a large flaky suite.
Raise certainty only when local facts truly support it.
