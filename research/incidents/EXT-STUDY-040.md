# EXT-STUDY-040 — bump linker RAM with no free

## Pattern

```zig
extern const __free_ram: u8;
extern const __free_ram_end: u8;
var used_mem: usize = 0;

fn allocPages(pages: usize) []u8 {
    // bump used_mem; never free — process/page tables live forever
}
```

Minimal kernels allocate page frames by bumping through a linker-defined RAM
window. There is no per-page free; “ownership” is forever (or until reboot).

## myzig promotion

Playbook (`F-OWN-044`). Strengthens fixed-region tips (`EXT-STUDY-019`).

## Boundary

Bump allocators are invisible to alloc-undischarged (no `.alloc(` needle).
