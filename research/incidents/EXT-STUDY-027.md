# EXT-STUDY-027 — begin/end mode scopes

## Pattern

```zig
beginDrawing();
defer endDrawing();
// draw calls…
```

Some APIs push a global “mode” (drawing, texture target, 3D, scissor). The pair
is stack-like: every `begin*` needs a matching `end*`, often via `defer`, even
though no allocator acquire occurred.

Device globals (`initAudioDevice` / `closeAudioDevice`) follow the same
open/close shape as the window.

## myzig promotion

Playbook (`F-OWN-030`). Out of scope for alloc/file seed rules.

## Boundary

Does not track mode-stack depth or mismatched begin/end across branches.
