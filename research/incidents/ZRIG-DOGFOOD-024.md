# ZRIG-DOGFOOD-024 — WebSocket handshake flush (V10.3)

## Context

`std.http.Server.respondWebSocket` writes the 101 Switching Protocols headers
into a buffered writer but does not flush. If the caller enters `readSmallMessage`
without flushing, the client never receives the upgrade response and times out.

## Error

```
web-smoke FAIL: WS connect timeout
```

## Fix

```zig
var ws = try request.respondWebSocket(.{ .key = key.? });
try ws.flush(); // ← required before entering read loop
handleWs(allocator, io, &ws, options.version) catch ...;
```

## Tip: F-ZRIG-025
