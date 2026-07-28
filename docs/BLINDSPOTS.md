# Analyzer blind spots (honest limits)

myzig's early detectors are **local heuristics**, not whole-program proof.

**Published agent-facing summary:** `docs/LIMITS.md` (`myzig limits`).

## Known blind spots

| Area | Limitation |
|------|------------|
| Path sensitivity | Conditional free/close may be treated as function-wide discharge |
| Transfers | Only `return ... .alloc/.create/.dupe` lines count as transfer; returning a local variable that holds an allocation is not yet tracked |
| Aliasing | Renames / wrappers around allocator APIs are invisible |
| Cross-function | Callee frees / ownership handoff across functions are out of scope |
| Arenas | Arena-scoped lifetimes are not modeled beyond coarse `defer …deinit` discharge (see `AZIG-OWN-001`) |
| Zig AST/ZIR | Token/text scan, not Zig Ast or ZIR CFG (zwanzig-class analysis) |
| Certainty | Heuristics emit at most `likely` / `convention` |
| Compat preference | `compat.volatile-std` is opt-in (`--prefer-compat` / `.myzig/prefer_compat`) |
| Adapter paths | Volatile-std detector skips `compat/` sources by path heuristic |
| Comments | Needle hits after `//` on the same line are ignored (M7 FP guard) |

## Product stance

Prefer five stable rules with documented blind spots over twenty flaky ones.
Raise certainty only when local facts truly support it.
