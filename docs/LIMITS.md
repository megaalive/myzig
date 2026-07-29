# myzig honest limits

Published limits for humans and coding agents. Detectors are **local heuristics**,
not a borrow checker and not a proof tool.

Run: `myzig limits`

Also see `docs/BLINDSPOTS.md` (analyzer detail) and `docs/friction-playbook.md`.

## Certainty

| Claim | Allowed when |
|-------|----------------|
| `proven` | Never from current heuristic rules (`certainty_ceiling` is `likely` or `convention`) |
| `likely` | Local ownership heuristics with incomplete path sensitivity |
| `convention` | Style / permit / compat preference signals |

## What myzig will not claim

- Whole-program absence of leaks, UAF, or data races
- That `defer` on one resource proves all resources in the function are fine
- That `claimed.verify_cost` is true without `myzig verify-cost` having been run
- That ordinary Zig must import `myzig` to be correct

## Detector ceilings (current seed)

| Rule | Ceiling | Typical FP / FN |
|------|---------|-----------------|
| `memory.alloc-undischarged` | likely | FP: coarse function-wide `defer …deinit/free`; FN: wrapper handoffs / callee frees |
| `resource.file-undischarged` | likely | FP: any `.close(` in function discharges; FN: close in callee / multi-hop |
| `unsafe.ptrcast-unremarked` | convention | FN: cast split across lines without remark |
| `compat.volatile-std` | convention | Opt-in only; adapter paths skipped |
| `lifecycle.empty-defer` | convention | Comment-only bodies still count as empty |
| `lifecycle.empty-errdefer` | convention | Same as empty-defer on error path |
| `ownership.hidden-allocator` | convention | FN: aliased globals / non-needle heaps; skips `test` |
| `lifecycle.swallow-error` | convention | Comment-only catch allowed; FN: non-block catch shapes |
| `lifecycle.init-without-deinit` | convention | Only `try …init(`; FP: examples inside string literals; FN: infallible init |
| `ffi.wrapper-init-without-deinit` | convention | Same heuristic on `@cImport`/`c.` files; does not prove C close correctness |
| `memory.sentinel-type-loss` | convention | Same-line `: []u8` / `: []const u8` only; FN: multi-hop / inferred erasure |

## Tuned FP / FN guards

- Needle hits after `//` on the same line are ignored (comment examples are not findings).
- `const buf = try allocator.alloc(...); return buf;` counts as transfer (not `return buf.len`).
- One-hop rename (`const owned = buf; return owned;`) and out-params (`out.* = buf` / `out.* = try …alloc`) count as transfer.
- Explicit `.free`/`.destroy`/`.release`/`.unload`/`.dealloc`/`.unmap`/`.cancel`/`.close`(name) and `name.deinit`/`.destroy`/`.release`/`.unload`/`.shutdown`/`.dealloc`/`.unmap`/`.cancel`/`.close(` discharge that binding (and rename aliases), with or without `defer`.
- Returning an opened file handle counts as transfer for `resource.file-undischarged`.
- Acquires also include `.allocPrint(` / `.allocPrintZ(` / `.alignedAlloc(` / `.dupeZ(` / `.dupeSentinel(` / `.realloc(` / `mem.concat(` / `mem.join(` (see `AZIG-OWN-003`).
- Rename chains (`a → b → c`) are followed for transfer/free (bounded closure).
- Same-line `list.append(try …dupe/alloc…)` / `map.put(…, try …dupe…)` and multi-line forms that name the binding in args count as collection transfer (`AZIG-OWN-004`, `EXT-STUDY-002`, `MYZIG-OWN-003`); markers include put/insert siblings.
- `@ptrCast` / `@alignCast` permits may sit on the previous/current/next line (`AZIG-OWN-005`).
- Field initializers inside `return .{ ... }` count as transfer (`AZIG-OWN-006`), including `const x = try …; return .{ .f = x }`.
- Exact assignment retarget `out = next` joins the alias closure (`AZIG-OWN-007`).
- Field assignment `self.x = try …alloc/dupe/create` and two-step `const x = try …; self.x = x` count as store transfer (`EXT-STUDY-007`, `MYZIG-OWN-003`).
- Indexed store `into[i] = try …dupe/alloc` counts as transfer into a caller buffer (`EXT-STUDY-020`).
- Arena-token acquires (`analyser.arena`, `arena_allocator`, `scratch_allocator`, `boottime_allocator`, …) count as transferred (`EXT-STUDY-008`, `EXT-STUDY-024`, `EXT-STUDY-039`).
- `.create(` is an acquire only for single-argument calls (`allocator.create(T)`) (`EXT-STUDY-009`).
- Empty `defer {}` / `errdefer {}` (whitespace/comment-only) are convention notes (`EXT-STUDY-001`).
- Hidden `page_allocator` / `c_allocator` use on alloc/free lines is a convention note (`EXT-STUDY-004`).
- Empty `catch {}` / `catch unreachable` are convention notes; comment-only catch and documented unreachable are allowed (`EXT-STUDY-005`, `EXT-STUDY-009`).
- Inline suppressions: `// myzig-disable-next-line` / `myzig-disable-current-line` [`rule_id…`] (`EXT-STUDY-005`).
- `.init(` bindings without `.deinit` / `.destroy` / `.unload` / `.shutdown` / `.close` / return transfer are convention notes (`EXT-STUDY-012`, `EXT-STUDY-023`, `EXT-STUDY-025`, `EXT-STUDY-031`, `EXT-STUDY-046`); `return .{ .f = name }` transfers (`EXT-STUDY-020`).
- Optional `myzig.compat.PhaseAllocator` seals alloc capability after startup (`EXT-STUDY-010`); boottime→runtime seal is the kernel sibling (`EXT-STUDY-039`).
- Post-Zig / foreign runtimes are allocator-*shape* references only (`EXT-STUDY-028`); borrowed-arena and single-buffer scratch tips stay playbook (`EXT-STUDY-029`, `EXT-STUDY-030`).
- Kernel PMM/VMM/guest-quota patterns stay playbook (`EXT-STUDY-037`..`042`).
- Async/net/wasm/image/crypto/tooling tips: `EXT-STUDY-043`..`054` (named shortlists must be finished in-batch).
- UEFI/HV/OS cadangan + clone-blocker process: `EXT-STUDY-055`..`063` (optional/cadangan names count; API survey when clone fails).
- Named ownership handoffs (`takeOwnership` / `assumeOwnership` / …) and same-file callees that free the matching parameter count as transfer (`MYZIG-OWN-004`); other-file callees and arbitrary `foo(buf)` do not.

## Dogfood snapshot

| Project | Note |
|---------|------|
| zrig | Primary unbounded dogfood; `check --prefer-compat --ratchet src` at 0 (see `ZRIG-DOGFOOD-001`); V10.2 async editor (`docs/GROWTH.md` in zrig) |
| azig | Retired lab — historical calibration only (`AZIG-OWN-*`); do not maintain for coach maturity |
| fpagnt | Capability bar (Free Pascal coding agent); not a myzig dependency |
| external studies | Pattern notes only (`EXT-STUDY-*`); take checkable methods, not domain-specific bans |

## Product stance

Prefer a small set of stable rules with published limits over a large flaky suite.
Promote playbook tips to code only when repeated or automatable.
