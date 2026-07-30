# ZRIG-DOGFOOD-050 — cancel kills shell + SPA queue

## Context

fpagnt Stop terminates the process tree and the SPA queues prompts while busy.
zrig V37 passes `cancel_flag` into `proc.run` (Child.kill) and queues SPA
prompts during a running turn.

## Do

Cancel from editor/web during a tool-heavy turn. Type the next prompt without
waiting — it should enqueue. Zig `Child.kill` already cleans; avoid a second
`wait` without handling cleanup races.

## Friction tip

`F-ZRIG-053` / `docs/V37.md`.
