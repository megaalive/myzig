# ZRIG-DOGFOOD-030 — mid-stream cancel ignored during SSE / faux deltas

## Context

zrig V10.2 cancel stopped approval waits. After V13 streaming, `task.cancel`
during live `message.delta` still let the ask finish and emit
`message.completed`.

## Command / error

```text
# editor: cancel after first delta still saw message.completed
task.cancel → {cancelled:true}
… message.completed (undesired)
```

## Friction

F-ZRIG-031 — cancel must be visible to the SSE chunk loop and faux-delta
emitter without holding the session mutex across I/O.

## Fix

- Session `cancel_flag: std.atomic.Value(bool)`
- Plumb `CompletionRequest.cancel_flag` into openai_compat stream loop
- Faux deltas pause + poll flag; no `message.completed` after cancel
- Smoke: `editor-smoke: mid_stream_cancel ok` (`docs/V15.md`)
