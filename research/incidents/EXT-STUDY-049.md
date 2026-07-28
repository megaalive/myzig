# EXT-STUDY-049 — image PixelStorage same-allocator deinit

## Pattern

```zig
var pixels = try PixelStorage.init(allocator, format, count);
errdefer pixels.deinit(allocator);
// decode…
defer image.deinit(allocator); // same allocator for life
```

CPU image libraries allocate pixel buffers with an explicit allocator and
require that same allocator on `deinit`. Temporary scaled copies need their
own defer.

## myzig promotion

Playbook (`F-OWN-053`); sibling of Context/Surface same-alloc (`EXT-STUDY-034`).

## Boundary

Does not prove allocator identity across calls.
