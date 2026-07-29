# ZRIG-DOGFOOD-047 — multimodal gate + runtime metrics

## Context

fpagnt 0.2.0 gates image paste on `mcImages` and exposes `/api/metrics` for a
Performance card. zrig V33/V34 match: mock ignores images; doctor/metrics JSON
reports turn counters without cloud calls.

## Do

Check `images` capability before attaching. Use `doctor --json` / `/api/metrics`
for process stats (RSS may be 0 on Windows).

## Friction tip

`F-ZRIG-049` / `F-ZRIG-050` / `docs/V33.md` / `docs/V34.md`.
