# Analyzer blind spots (honest limits)

myzig's early detectors are **local heuristics**, not whole-program proof.

**Published agent-facing summary:** `docs/LIMITS.md` (`myzig limits`).

## Known blind spots

| Area | Limitation |
|------|------------|
| Path sensitivity | Conditional free/close may be treated as function-wide discharge |
| Transfers | Return / out-param / rename / assignment retarget / `return .{ fields }` / same-line append tracked; wrapper / callee frees still weak |
| Aliasing | Exact RHS rename closure (bounded) is followed for transfer/free; wrapper APIs stay invisible |
| Local free | `.free(name)` / `.destroy(name)` / `name.deinit(` discharge that binding; coarse function-wide `defer …deinit/free` remains for arena-style sites |
| Permits | `@ptrCast`/`@alignCast` accept permit/safety on adjacent lines (prev/curr/next) |
| Cross-function | Callee frees / ownership handoff across functions are out of scope |
| Arenas | Arena-scoped lifetimes are not modeled beyond coarse `defer …deinit` discharge (see `AZIG-OWN-001`) |
| Zig AST/ZIR | Token/text scan, not Zig Ast or ZIR CFG (zwanzig-class analysis) |
| Certainty | Heuristics emit at most `likely` / `convention` |
| Compat preference | `compat.volatile-std` is opt-in (`--prefer-compat` / `.myzig/prefer_compat`) |
| Adapter paths | Volatile-std detector skips `compat/` sources by path heuristic |
| Comments | Needle hits after `//` on the same line are ignored (M7 FP guard) |
| SARIF | Forge-oriented SARIF 2.1.0 (`ruleIndex`, fingerprints, `automationDetails`, `helpUri`); CI may upload on ubuntu (`continue-on-error`) |

## Product stance

Prefer five stable rules with documented blind spots over twenty flaky ones.
Raise certainty only when local facts truly support it.
