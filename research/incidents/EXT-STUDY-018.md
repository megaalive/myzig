# EXT-STUDY-018 — FFI wrapper deinit closes the C handle

## Pattern

```zig
pub fn deinit(self: *Db) void {
    _ = c.some_close(self.handle);
}
// statements: prepare → defer stmt.deinit() → finalize
```

Zig `deinit` is the ownership boundary; the C API (`close`/`finalize`) is the
actual resource release. GPA leak checks will not see the C handle.

## myzig stance

- Prefer `defer wrapper.deinit()` over calling C cleanup at every site
- Documents EXT-STUDY-013 with a concrete wrapper shape
- Seed `ffi.*` rules still deferred until dogfood repeats

## Boundary

myzig does not parse `@cImport` symbol contracts.
