# ZRIG-DOGFOOD-006 — agent stop vs continue honesty

## Context

V2 agent harness needs a receipt that tells agents whether later plan steps ran
after a failure. Without `stopped_early` / `keep_going`, exit code 1 alone is
ambiguous.

## Observation

Default `zrig agent` stops after the first failed `run`. With `--continue`,
remaining steps still execute and the receipt stays `ok: false` if any failed.

## Friction tip

`F-HARNESS-005` in `docs/friction-playbook.md`.

## Promotion

Receipt schema `0.0.1` + `docs/V2.md` exit-code table (already in zrig).
