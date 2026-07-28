# EXT-STUDY-060 — minimal kernels and firmware SBI ownership

## Pattern

Hello-world / time-sharing teaching kernels often have no Zig heap: VGA print,
trap handlers, and OpenSBI calls. Memory ownership is firmware+linker script.
Do not invent GPA patterns when the sample has none.

## myzig promotion

Playbook (`F-OWN-063`); study boundary for minimal samples.

## Boundary

No obligation to add allocators to teaching kernels.
