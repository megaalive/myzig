# EXT-STUDY-061 — clone blockers still require API survey

## Pattern

Some named study targets cannot fully check out on a given host (git-lfs
required, invalid Windows paths in tree). Ownership study continues via
remote tree/API/raw file reads; record the blocker in the incident.

## myzig promotion

Playbook (`F-AGENT-004`); process tip.

## Boundary

Local dogfood of those trees may remain incomplete until the host can clone.
