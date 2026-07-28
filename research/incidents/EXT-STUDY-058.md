# EXT-STUDY-058 — fuller OS stacks reinforce layered reclaim

## Pattern

Larger hobby/desktop OS trees still separate: bootloader handoff, physical
pages, virtual maps with `reclaim_pages` on task teardown, virtio rings on
page-aligned queues, and user heaps. Tools may use arenas for image builders
while the kernel path stays page-based.

## myzig promotion

Playbook (`F-OWN-061`); confirmation of `EXT-STUDY-037`..`042`, not new detectors.

## Boundary

Does not import OS-specific APIs into myzig.
