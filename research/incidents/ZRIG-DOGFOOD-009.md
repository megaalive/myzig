# ZRIG-DOGFOOD-009 — compat file copy/delete

## Context

zrig needed `files.copy` / `files.delete` for richer dogfood plans. Raw
`std.Io.Dir.copyFile` argument order already differs from older mental models.

## Observation

Growing `myzig.compat` with `copyFile` / `deleteFile` keeps dogfood apps on the
stable façade and gives the coach a concrete tip (`F-STD-004`).

## Friction tip

`F-STD-004` in `docs/friction-playbook.md`.

## Promotion

`myzig.compat.copyFile` / `deleteFile` + zrig tools.
