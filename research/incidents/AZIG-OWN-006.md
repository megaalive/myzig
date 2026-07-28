# AZIG-OWN-006 — `return .{ .field = try dupe }` transfers ownership

## Summary

Legacy constructors often build owned structs inline:

```zig
return .{
    .id_sesi = try allocator.dupe(u8, id),
    .cwd = try allocator.dupe(u8, cwd),
};
```

Seen in session/config clone helpers (`inti/sesi.zig`, `cli/perintah.zig`).

## Why it matters

Early detectors only treated direct `return buf` / out-params / append as transfer.
Field initializers inside `return .{ ... }` transfer to the caller, including
locals later named in those fields (`const daftar = try alloc; return .{ .pesan = daftar }`).

## False-positive / fitting risk

Do not treat non-returned struct literals as transfers.
