# EXT-STUDY-053 — crypto keys are wipe-scoped secrets

## Pattern

AEAD/minisign-style APIs take fixed-size key arrays. Treat keys/nonces as
secrets: limit copies, prefer stack/fixed buffers, wipe when the API allows.
Do not log key material from TLS transcripts or charm state.

## myzig promotion

Playbook (`F-OWN-057`).

## Boundary

No automatic secret-wipe enforcement.
