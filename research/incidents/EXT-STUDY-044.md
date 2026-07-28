# EXT-STUDY-044 — connection arena reset with retain limit

## Pattern

HTTP/network servers reset a per-connection arena after each request while
retaining a byte limit (`retain_with_limit`). TLS session objects deinit with
the server; keep-alive reuses the provision without freeing the pool slot.

## myzig promotion

Playbook (`F-OWN-048`); sibling of request-arena tips (`EXT-STUDY-016`).

## Boundary

Not path-sensitive across keep-alive branches.
