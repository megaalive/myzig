# EXT-STUDY-005 — swallowed errors + inline suppressions

## Pattern

```zig
mightFail() catch {};
mightFail() catch unreachable;
```

Empty / panic-on-error catch hides cleanup failures on ownership paths.

Comment-only catch bodies are a documented ignore:

```zig
mightFail() catch {
    // intentionally ignored
};
```

## myzig promotion

- New convention rule: `lifecycle.swallow-error`
- Inline suppressions: `myzig-disable-next-line` / `myzig-disable-current-line`
- Certainty ceiling: `convention`

## Boundary

Multi-line disable/enable regions and autofix stay out of scope.
