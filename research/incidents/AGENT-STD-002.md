# AGENT-STD-002 — prefer myzig.compat when insulating dogfood apps

## Summary

Agents repeatedly paste `std.fs.cwd`, `getEnvVarOwned`, `std.time.timestamp`, and
raw `std.Io.Dir.cwd` from training memory. `myzig.compat` already exists
(AGENT-STD-001); agents still need a coach signal that points to it.

## Symptom

Compile breaks on Zig 0.17 for stale APIs, or brittle raw Io call sites that
break again on the next std rename — even after compat landed.

## Canonical improvement

Rule `compat.volatile-std` (certainty: `convention`):

- Inactive by default (ordinary Zig first-class)
- Enabled with `myzig check --prefer-compat` or empty `.myzig/prefer_compat`
- Skips `compat/` adapter sources
- Repair intent `use_compat` → `myzig.compat.*`

## Follow-ups

Dogfood apps (zrig) should drop `.myzig/prefer_compat` when ready to enforce.

## False-fitting risk

Do not enable by default on every Zig repo — that would punish ordinary std use.
