# ZRIG-DOGFOOD-042 — verify unavailable is neutral

## Context

fpagnt treats verification `unavailable` (no discoverable build/test command)
as neutral — not a failed task. zrig V27 mirrors that for empty workspaces and
unknown markers, while detecting Zig via `build.zig`.

## Do

`zrig verify` / `project.detect` / `project.verify`. Exit 0 on unavailable.
Use `--dry-run` to show `zig build` without spawn; `--allow proc.spawn` to run.

## Friction tip

`F-ZRIG-043` / `docs/V27.md`.
