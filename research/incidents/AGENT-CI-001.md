# AGENT-CI-001 — private Actions empty-step failures are billing

## Symptom

GitHub Actions jobs for a **private** repo conclude `failure` in a few seconds
with **zero steps** and no `runner_name`. GraphQL annotations say spending
limit / failed payments must be fixed under Billing & plans.

## Cause

Not a Zig/build regression. Private Actions minutes (especially macos at 10×)
exhausted the account spending limit after a dense push day with a 3-OS matrix.

## Fix

1. Restore payment method / raise Actions spending limit.
2. Keep default CI on `ubuntu-latest` only; opt into full matrix via
   `workflow_dispatch` input `full_matrix`.
3. Re-run the workflow after billing is healthy.

## Boundary

Local `zig build` / `zig build test` still prove product health while Actions
is blocked.
