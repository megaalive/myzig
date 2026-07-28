# EXT-STUDY-001 — empty defer/errdefer stubs

## Pattern

```zig
defer {}
errdefer { /* TODO */ }
```

Looks like cleanup; discharges nothing.

## myzig promotion

- New convention rules: `lifecycle.empty-defer`, `lifecycle.empty-errdefer`
- Text-scan V0 (brace body only whitespace/comments) — no Zig Ast dependency
- Certainty ceiling: `convention`

## Boundary

Full AST walkers / CFG cleanup proofs stay out of scope; this is a convention signal only.
