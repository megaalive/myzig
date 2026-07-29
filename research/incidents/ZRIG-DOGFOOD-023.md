# ZRIG-DOGFOOD-023 — async editor worker (V10.2)

## Context

V10.1 `task.create` ran mock ask synchronously, so stdin could not accept
`events.poll` / cancel / approval while a task ran (fpagnt gap).

## Commands / errors

1. Zig 0.17: `root source file struct 'Thread' has no member named 'Mutex'`
2. GPA used from main + worker without serialization → undefined behavior risk
3. Holding mutex across `model.turn.run` would block `events.poll`

## Fix / tip

- Background `std.Thread` for ask; `task.create` → `{started:true}`
- `Io.Mutex` / `Io.Condition` with session `io` (`F-OWN-072`)
- session.allocator only under mutex; ask buffers via `page_allocator` (`F-ZRIG-024`)
- Smoke: interactive `python3 scripts/editor_smoke.py` (approval + cancel)

## Artifacts

- Code: zrig `src/editor.zig`
- Docs: zrig `docs/V10.2.md`
- Playbook: F-HARNESS-020, F-OWN-072, F-ZRIG-024
