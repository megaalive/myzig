# ZRIG-DOGFOOD-053 — UTF-8 Windows paths + Unicode envGet

## Context

GROWTH flagged UTF-8 filesystem paths. Zig Io already uses WTF-8 wide APIs;
`envGet` still used ACP `getenv`. V40 switches Windows `envGet` to
`Environ.global.getAlloc` and adds a non-ASCII path roundtrip test.

## Do

`zig build test` in myzig (unicode path test). Prefer compat file APIs.

## Friction tip

`F-ZRIG-056` / `docs/V40.md`.
