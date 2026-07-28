# EXT-STUDY-006 — study boundary (general lint not cloned)

## Context

General Zig linters often cover naming, ordering, unused decls, braces, and
build.zig-integrated AST hosts — useful tools, different product job.

## Ownership-adjacent ideas we adopted

| Idea | myzig stance |
|------|--------------|
| Prefer caller-supplied allocators over hidden globals | `ownership.hidden-allocator` (convention) |
| Empty / unreachable catch swallows errors | `lifecycle.swallow-error` (convention) |
| Line-scoped disable comments | `myzig-disable-*` suppressions |
| Require errdefer paired with every alloc | Soft heuristic later only if dogfood demands; not a seed rule yet |

## Product boundary

myzig: ownership obligations, evidence, honest ceilings.
General lint suites: style and AST hygiene with project-local build integration.

Study patterns; keep identities separate.
