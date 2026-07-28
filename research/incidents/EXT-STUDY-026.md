# EXT-STUDY-026 — staging unload and graphics context order

## Pattern

```zig
initWindow(...);                 // creates GL/context — required before GPU loads
defer closeWindow();

const image = try loadImage(path);           // CPU / RAM
const texture = try loadTextureFromImage(image); // GPU / VRAM
unloadImage(image);                          // staging done — free CPU copy now
defer unloadTexture(texture);                // keep GPU resource for the loop
```

`defer` LIFO: register `closeWindow` first, then `unloadTexture`, so the texture
unloads before the context dies.

## myzig promotion

Playbook tips (`F-OWN-028`, `F-OWN-029`). No seed rule — ordering is
path/API-specific.

## Boundary

Does not prove OpenGL context readiness or that staging unload happened.
