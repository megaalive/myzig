# EXT-STUDY-047 — TLS close_notify and key material lifetime

## Pattern

Sessions signal clean shutdown with `close_notify`. Key/secret material lives
in handshake transcripts and must not outlive the session or be logged.
Application data ends with EndOfStream on clean close.

## myzig promotion

Playbook (`F-OWN-051`).

## Boundary

No secret-wiping detector.
