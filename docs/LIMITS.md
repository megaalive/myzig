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

## Tuned FP / FN guards

- Needle hits after `//` on the same line are ignored (comment examples are not findings).
- `const buf = try allocator.alloc(...); return buf;` counts as transfer (not `return buf.len`).
- One-hop rename (`const owned = buf; return owned;`) and out-params (`out.* = buf` / `out.* = try …alloc`) count as transfer.
- Explicit `.free(name)` / `.destroy(name)` / `name.deinit(` discharge that binding (and rename aliases), with or without `defer`.
- Returning an opened file handle counts as transfer for `resource.file-undischarged`.
- Acquires also include `.allocPrint(` / `.allocPrintZ(` / `.alignedAlloc(` / `.dupeZ(` / `.dupeSentinel(` / `.realloc(` / `mem.concat(` / `mem.join(` (see `AZIG-OWN-003`).
- Rename chains (`a → b → c`) are followed for transfer/free (bounded closure).
- Same-line `list.append(try …dupe/alloc…)` and multi-line append that names the binding in args count as collection transfer (`AZIG-OWN-004`, `EXT-STUDY-002`).
- `@ptrCast` / `@alignCast` permits may sit on the previous/current/next line (`AZIG-OWN-005`).
- Field initializers inside `return .{ ... }` count as transfer (`AZIG-OWN-006`), including `const x = try …; return .{ .f = x }`.
- Exact assignment retarget `out = next` joins the alias closure (`AZIG-OWN-007`).
- Field assignment `self.x = try …alloc/dupe/create` counts as store transfer (`EXT-STUDY-007`).
- Indexed store `into[i] = try …dupe/alloc` counts as transfer into a caller buffer (`EXT-STUDY-020`).
- Arena-token acquires (`analyser.arena`, `arena_allocator`, …) count as transferred (`EXT-STUDY-008`).
- `.create(` is an acquire only for single-argument calls (`allocator.create(T)`) (`EXT-STUDY-009`).
- Empty `defer {}` / `errdefer {}` (whitespace/comment-only) are convention notes (`EXT-STUDY-001`).
- Hidden `page_allocator` / `c_allocator` use on alloc/free lines is a convention note (`EXT-STUDY-004`).
- Empty `catch {}` / `catch unreachable` are convention notes; comment-only catch and documented unreachable are allowed (`EXT-STUDY-005`, `EXT-STUDY-009`).
- Inline suppressions: `// myzig-disable-next-line` / `myzig-disable-current-line` [`rule_id…`] (`EXT-STUDY-005`).
- `.init(` bindings without `.deinit` / return transfer are convention notes (`EXT-STUDY-012`); `return .{ .f = name }` transfers (`EXT-STUDY-020`).
- Optional `myzig.compat.PhaseAllocator` seals alloc capability after startup (`EXT-STUDY-010`).

## Dogfood snapshot

| Project | Note |
|---------|------|
| zrig | `check --prefer-compat --ratchet src` held at 0 findings (see `ZRIG-DOGFOOD-001`) |
| azig | Memory heuristics calibrated to **0** alloc findings on `src/`; leftover is ptrcast remarks (`AZIG-OWN-008`) + arena coarseness (`AZIG-OWN-001`) |
| external studies | Pattern notes only (`EXT-STUDY-*`); take checkable methods, not domain-specific bans |

## Product stance

Prefer a small set of stable rules with published limits over a large flaky suite.
Promote playbook tips to code only when repeated or automatable.
