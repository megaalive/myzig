# ZRIG-DOGFOOD-051 — reply language → ## BAHASA

## Context

fpagnt UI lang (id|en) rewrites the system prompt with an explicit
`## BAHASA` block covering answers and reasoning traces. zrig V38 mirrors
that with `lang.zig`, `ask --lang`, editor `params.lang`, and SPA select /
`/lang` (localStorage). Also fixed missing SPA `flushPromptQueue` left from V37.

## Do

`zrig ask --provider mock --lang en hi` and toggle SPA lang before ask.
Invalid `--lang` must usage-exit.

## Friction tip

`F-ZRIG-054` / `docs/V38.md`.
