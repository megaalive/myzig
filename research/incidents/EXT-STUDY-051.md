# EXT-STUDY-051 — LSP DocumentStore arenas are tooling-shaped

## Pattern

Language servers open/close documents, parse into arenas, and free on close.
AST trees and URIs are store-owned. This is tooling lifetime — not a template
for request servers (compare `EXT-STUDY-015`).

## myzig promotion

Playbook (`F-OWN-055`) / study boundary.

## Boundary

Does not model incremental reparse graphs.
