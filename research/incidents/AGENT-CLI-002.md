# AGENT-CLI-002 — exhaustive CLI switch + witness hash choice

## Summary

While landing M6 (`verify-cost`, permits), the library tests compiled but the
executable failed: after every `Command` variant gained a real arm, a leftover
`else => stubMessage(...)` became an unreachable prong. Separately, reaching for
`std.crypto.hash.sha2.Sha256` was awkward on this toolchain; `std.hash.Wyhash`
was enough for a non-cryptographic witness id.

Also: Zig required `const` instead of `var` for an immutable `Report`.

## Symptom

```text
error: unreachable else prong; all cases already handled
error: local variable is never mutated
```

`zig build test` could still look green while `zig build` (install exe) failed.

## Canonical improvement

- Keep CLI `switch` exhaustive without a stub `else` once commands are real.
- Prefer `Wyhash` (or FNV) for cost-witness fingerprints unless integrity/crypto is required.
- Record tip as `F-CLI-004` in the friction playbook.

## False-fitting risk

Do not add a heavyweight crypto dependency just to name a witness file.
