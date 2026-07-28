# EXT-STUDY-014 — completion / callback storage stability

## Pattern

Event-loop completions are often caller-owned stack/heap objects whose address
must remain stable until the callback fires. Moving/copying them, or
`deinit` while submissions are outstanding, is a use-after-free class.

## myzig stance

Playbook guidance only for now:

- Keep completion objects alive for the async lifetime
- Prefer `*const` / pointer APIs for large or identity-sensitive values
- Cancel or drain before teardown

## Boundary

No CFG of outstanding submissions yet — would need deeper analysis than seed heuristics.
