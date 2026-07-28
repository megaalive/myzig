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

## Tuned FP / FN guards

- Needle hits after `//` on the same line are ignored (comment examples are not findings).
- `const buf = try allocator.alloc(...); return buf;` counts as transfer (not `return buf.len`).
- One-hop rename (`const owned = buf; return owned;`) and out-params (`out.* = buf` / `out.* = try …alloc`) count as transfer.
- Explicit `.free(name)` / `.destroy(name)` / `name.deinit(` discharge that binding (and rename aliases), with or without `defer`.
- Returning an opened file handle counts as transfer for `resource.file-undischarged`.
- Acquires also include `.allocPrint(` / `.allocPrintZ(` / `.alignedAlloc(` / `.dupeZ(` / `.dupeSentinel(` / `.realloc(` / `mem.concat(` / `mem.join(` (see `AZIG-OWN-003`).
- Rename chains (`a → b → c`) are followed for transfer/free (bounded closure).
- Same-line `list.append(try …dupe/alloc…)` counts as collection transfer (`AZIG-OWN-004`).
- `@ptrCast` / `@alignCast` permits may sit on the previous/current/next line (`AZIG-OWN-005`).

## Dogfood snapshot

| Project | Note |
|---------|------|
| zrig | `check --prefer-compat --ratchet src` held at 0 findings (see `ZRIG-DOGFOOD-001`) |
| azig | Arena-heavy modules illustrate coarse `defer deinit` discharge (`AZIG-OWN-001`) |

## Product stance

Prefer a small set of stable rules with published limits over a large flaky suite.
Promote playbook tips to code only when repeated or automatable.
