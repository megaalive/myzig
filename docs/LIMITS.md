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
| `memory.alloc-undischarged` | likely | FP: coarse function-wide `defer …deinit/free`; FN: return of local alloc var |
| `resource.file-undischarged` | likely | FP: any `.close(` in function discharges; FN: close in callee |
| `unsafe.ptrcast-unremarked` | convention | FN: cast split across lines without remark |
| `compat.volatile-std` | convention | Opt-in only; adapter paths skipped |

## Tuned FP guards (M7)

- Needle hits after `//` on the same line are ignored (comment examples are not findings).

## Dogfood snapshot

| Project | Note |
|---------|------|
| zrig | `check --prefer-compat --ratchet src` held at 0 findings (see `ZRIG-DOGFOOD-001`) |
| azig | Arena-heavy modules illustrate coarse `defer deinit` discharge (`AZIG-OWN-001`) |

## Product stance

Prefer a small set of stable rules with published limits over a large flaky suite.
Promote playbook tips to code only when repeated or automatable.
