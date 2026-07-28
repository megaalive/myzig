# Analyzer blind spots (honest limits)

myzig's early detectors are **local heuristics**, not whole-program proof.

**Published agent-facing summary:** `docs/LIMITS.md` (`myzig limits`).

## Known blind spots

| Area | Limitation |
|------|------------|
| Path sensitivity | Conditional free/close may be treated as function-wide discharge |
| Transfers | Return / out-param / indexed-out / rename / retarget / field-store / `return .{ fields }` / append / arena-backed; wrapper / callee frees still weak |
| Aliasing | Exact RHS rename closure (bounded) is followed for transfer/free; wrapper APIs stay invisible |
| Local free | `.free`/`.destroy`/`.release`/`.unload`/`.dealloc`/`.unmap`(name) and `name.deinit`/`.destroy`/`.release`/`.unload`/`.shutdown`/`.dealloc`/`.unmap(` discharge that binding; coarse function-wide `defer …` discharge remains for arena-style sites |
| Permits | `@ptrCast`/`@alignCast` accept permit/safety on adjacent lines (prev/curr/next) |
| Cross-function | Callee frees / ownership handoff across functions are out of scope |
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
| FFI / C boundaries | Zig allocator tracking does not prove external cleanup (`EXT-STUDY-013`) |
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

## Product stance

Prefer a small set of stable rules with documented blind spots over a large flaky suite.
Raise certainty only when local facts truly support it.
