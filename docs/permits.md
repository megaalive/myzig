# Unsafe permits

myzig does not invent ownership policy for casts. Sites that use `@ptrCast` /
`@alignCast` need an adjacent remark.

## Accepted forms

```zig
return @ptrCast(p); // safety: opaque FFI handle

return @ptrCast(p); // myzig.permit(ptrcast): opaque FFI handle

return @alignCast(p); // unsafe.permit(aligncast): allocator alignment contract
```

## Kinds

| Kind | Use for |
|------|---------|
| `ptrcast` | `@ptrCast` |
| `aligncast` | `@alignCast` |
| `bitcast` | `@bitCast` (reserved for future detector) |
| `ffi` | wildcard when the reason is external ABI |
| `other` | last resort; prefer a precise kind |

Structured `myzig.permit(kind)` must match the operation (or use `ffi`/`other`).
Unstructured `myzig.permit` / `unsafe.permit` without `(kind)` still discharges
for migration, but structured forms are preferred.
