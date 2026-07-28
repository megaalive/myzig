# Analyzer blind spots (honest limits)

myzig's early detectors are **local heuristics**, not whole-program proof.

**Published agent-facing summary:** `docs/LIMITS.md` (`myzig limits`).

## Known blind spots

| Area | Limitation |
|------|------------|
| Path sensitivity | Conditional free/close may be treated as function-wide discharge |
| Transfers | Return / out-param / rename / retarget / `return .{ fields }` / append (same-line or binding-in-args) tracked; wrapper / callee frees still weak |
| Aliasing | Exact RHS rename closure (bounded) is followed for transfer/free; wrapper APIs stay invisible |
| Local free | `.free(name)` / `.destroy(name)` / `name.deinit(` discharge that binding; coarse function-wide `defer …deinit/free` remains for arena-style sites |
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
| Swallow errors | Empty / unreachable catch only; multi-line disable regions not supported |
| Suppressions | Line-scoped `myzig-disable-*` only (not multi-line enable/disable regions) |
| General lint | Naming, unused, braces, build-step AST hosts — out of product scope (`EXT-STUDY-006`) |

## Product stance

Prefer a small set of stable rules with documented blind spots over a large flaky suite.
Raise certainty only when local facts truly support it.
