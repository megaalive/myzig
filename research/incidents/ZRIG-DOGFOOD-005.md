# ZRIG-DOGFOOD-005 — prove net.http.get on loopback first

## Friction

Outbound `net.http.get http://example.com` hit `IO_TIMEOUT` on a locked-down
dev host while `http://127.0.0.1:<port>/` against a local server returned 200.
Agents assumed the HTTP tool was broken.

## Do

1. Capability: `--allow net.connect` or `.zrig/capabilities`
2. Smoke against loopback (python `-m http.server` / tiny Zig listener)
3. Only then try external URLs

## myzig knowledge

Playbook `F-HARNESS-003`. Not a myzig detector — harness/network tip.

## Boundary

Does not change TLS/certificate policy; documents environment variance.
