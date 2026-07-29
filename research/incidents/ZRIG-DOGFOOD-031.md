# ZRIG-DOGFOOD-031 — no-buffer + usage on editor stream

## Context

After V13–V15, clients already render from `message.delta`, but
`message.completed` still always carried a full duplicate `text`. Token usage
was invisible on the editor/WS surface (fpagnt emits `usage`).

## Friction

F-ZRIG-032 — optional no-buffer completed + `message.usage` (estimated or provider).

## Fix

- Session `buffer_final` / `params.buffer`
- DeltaBridge skips content accumulation when unbuffered
- Parse OpenAI stream/non-stream `usage`; else estimate bytes/4
- Smoke: `editor-smoke: no_buffer ok` (`docs/V16.md`)
