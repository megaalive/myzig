# ZRIG-DOGFOOD-027 — skills on web/editor (V12)

## Context

`ask --skills-dir` injected system addons; web/editor ignored skills packs, so
the loopback UI could not dogfood project SKILL.md guidance.

## Fix

- `skills.loadSystem` helper
- `--skills-dir` / `--no-skills` on `web serve` and `editor`
- Pass `system` into `model.turn.run` for `/api/ask` and editor tasks
- Advertise `skills` + `skills_dir` on `/api/meta` and `initialize`

## Tip

F-ZRIG-028 / F-HARNESS-023
