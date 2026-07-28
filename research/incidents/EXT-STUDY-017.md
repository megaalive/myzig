# EXT-STUDY-017 — query result deinit may release a pool

## Pattern

```zig
var result = try pool.query(...);
defer result.deinit(); // may also conn.release()
```

`deinit` is not only memory teardown: it can return a pooled connection and
clear row buffers that alias reader memory.

Callers may need an explicit `drain()` before deinit when not consuming all rows.

## myzig stance

- Playbook: treat pool-aware `deinit` as multi-obligation cleanup
- Future: soft note when `query`/`exec` result lacks `defer …deinit`

## Boundary

No CFG of pool checkout/checkin yet.
