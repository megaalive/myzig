# ZRIG-DOGFOOD-012 — V4 ask mock + openai_compat caps

## Context

Shipping `zrig ask` (V4). CI and agents must not depend on live model APIs.
Remote `openai_compat` reuses `net.connect` like `net.http.get`.

## Do

Use `--provider mock` for offline smoke and CI. Grant `net.connect` and set
API key env only for live calls. Record turns with `--receipt`.

## Friction tip

`F-HARNESS-011`.
