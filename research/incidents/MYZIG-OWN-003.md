# MYZIG-OWN-003 — two-step field store and collection put transfers

## Summary

Local acquires handed to an owner field or map via a **second statement** were
still flagged as undischarged. Same-line field store and `.append(` were already
modeled (`EXT-STUDY-007`, `AZIG-OWN-004`); the two-step forms were not.

## Original patterns

```zig
const name = try allocator.dupe(u8, src);
self.name = name;

const value = try allocator.dupe(u8, src);
try map.put(key, value);
```

## Why wrong (as FN)

Ownership left the local binding. Freeing locally would be a double-free once
the owner deinits. The detector treated only same-line acquire RHS and
append/appendSlice as collection transfer.

## Fix in myzig

- `bindingStoredToField`: `recv.field = name` (exact ident; reject `.len` / `[i]`)
- Collection markers also: `.put(`, `.putNoClobber(`, `.putAssumeCapacity(`, `.insert(`

## Boundary

Still does not model cross-function callee frees or opaque `takeOwnership(buf)`.
Does not prove the owner later frees the field.

## Fixtures

- `fixtures/pass/alloc_field_store_binding.zig`
- `fixtures/pass/alloc_put_transfer.zig`
