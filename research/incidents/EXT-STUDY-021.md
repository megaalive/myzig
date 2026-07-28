# EXT-STUDY-021 — nested owner scopes outlive children

## Pattern

Long-lived parent owns identity / finalizer pools; children (session, page, request)
are created and destroyed many times while the parent stays alive. A pool or weak-
callback table on the parent must outlive every child that registers into it.

Teardown order: unregister watchdogs / listeners → destroy children → only then
tear down the parent's env / pool.

## myzig promotion

Playbook tip (`F-OWN-023`). No seed rule — cross-object lifetimes need CFG.

## Boundary

Does not model parent/child graphs or GC finalizer queues.
