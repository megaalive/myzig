# MYZIG-OWN-005 — FFI wrapper init without deinit

## Summary

Files that use `@cImport` / `c.` symbols and construct wrappers with `.init(`
need a matching `deinit`/`close` that releases the external handle. GPA leak
checks will not see the C resource (`EXT-STUDY-013`, `EXT-STUDY-018`).

## Promotion

- When a source looks FFI-shaped, `lifecycle.init-without-deinit` findings are
  emitted as `ffi.wrapper-init-without-deinit` (same heuristic, FFI category /
  repairs).
- Playbook `F-OWN-066`.

## Fixtures

- `fixtures/fail/ffi_wrapper_init_without_deinit.zig`
- `fixtures/pass/ffi_wrapper_deinit_closes.zig`

## Boundary

Does not parse `@cImport` symbol contracts or prove the C close is correct.
