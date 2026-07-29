# ZRIG-DOGFOOD-025 — thread-per-connection web fanout (V10.4)

## Context

V10.3 handled each TCP connection on the accept loop. A long-lived `/ws`
session blocked new HTTP/WS clients (unlike fpagnt's WS worker threads).

## Proof

`scripts/web_smoke.py` concurrent case: two clients both reach
`approval.requested` and rendezvous on a barrier before either approves.

## Fix / tip

- Main thread: accept + spawn + detach
- Worker: `page_allocator` for `ConnCtx` / session (F-ZRIG-026)
- Wait `active==0` before `serve` returns so stack atomics stay valid

## Artifacts

- Code: zrig `src/web.zig`
- Docs: `docs/V10.4.md`
- Playbook: F-HARNESS-021, F-ZRIG-026
