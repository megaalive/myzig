# ZRIG-DOGFOOD-002 — envGetOrNull for missing env vars

## Friction

zrig `system.which` (and similar) used `envGet` + `catch EnvironmentVariableNotFound`
boilerplate when PATH may be unset.

## Promotion

`myzig.compat.envGetOrNull` returns `?[]u8` (null when unset) while other env errors
still propagate. Dogfood call sites stay insulated from std env churn.

## Boundary

Does not replace `envGet` for callers that want a hard error on missing keys.
