# ZRIG-DOGFOOD-041 — web.fetch needs net.connect + HTML simplify

## Context

fpagnt 0.2.0 ships `web_fetch` behind a network capability with HTML→text.
zrig V26 adds `web.fetch` / `web_fetch` on the existing `net.connect` gate
(same family as `net.http.get`), rejecting non-http(s) URLs.

## Do

Grant `net.connect`. Prefer `web.fetch` when the model needs readable page
text; keep `net.http.get` for raw bodies. Prove on loopback via
`scripts/http-loopback-smoke.ps1`.

## Friction tip

`F-ZRIG-042` / `docs/V26.md`.
