# myzig friction playbook

Living **text** knowledge for humans and coding agents. Not every friction needs a
new Zig rule — many tips stay here until they prove worth promoting into code.

```text
hit friction → append/update an entry here (fast)
        → optional AGENT-* incident note
        → promote to compat/rule/CLI only when repeated or automatable
```

Run: `myzig friction` (prints package playbook + optional project overlay).

Project overlay (optional): `.myzig/friction-playbook.md`  
Env override for package file: `MYZIG_FRICTION_PLAYBOOK=/path/to/file.md`

## How to add an entry

1. Copy the template.
2. Use a new id (`F-STD-*`, `F-OWN-*`, `F-CLI-*`, `F-HARNESS-*`, `F-OTHER-*`).
3. Keep **symptom** concrete (command + error text).
4. Put the actionable fix under **do**.
5. Leave **promote-to-code-when** honest — empty if text is enough forever.

### Template

```markdown
### F-KIND-NNN · short title
- **symptom:** …
- **do:** …
- **don't:** …
- **promote-to-code-when:** …
- **incident:** none yet | AGENT-…
```

## Entries

### F-STD-001 · Zig 0.17 removed many remembered fs/env/time APIs
- **symptom:** `fs has no member named 'cwd'`; `getEnvVarOwned` missing; time helpers moved
- **do:** Prefer `myzig.compat` (`readFileAlloc`, `writeFile`, `listDirAlloc`, `envGet`, `unixSeconds`, …). Dogfood apps: `myzig check --prefer-compat` or `.myzig/prefer_compat`.
- **don't:** Rewrite every call site to raw `std.Io.Dir` on each toolchain bump.
- **promote-to-code-when:** already promoted → `myzig.compat` + `compat.volatile-std`
- **incident:** AGENT-STD-001, AGENT-STD-002

### F-CLI-001 · Expected myzig outcomes are not crashes
- **symptom:** Agent treats stack traces / non-zero exit as “binary broken”
- **do:** Interpret exits: `0` ok, `1` findings/error, `2` usage/unknown. Use `check` → `explain` → repair intent → `check` → `receipt`.
- **don't:** Retry random flags or rewrite the coach when exit is 1 with printed findings.
- **promote-to-code-when:** already promoted → clean `process.exit` in CLI
- **incident:** AGENT-CLI-001

### F-HARNESS-001 · Private sibling path deps break CI
- **symptom:** CI cannot fetch private `../myzig` or GitHub path dependency (404 / auth)
- **do:** Vendor a myzig snapshot into the dogfood repo (or inject a token explicitly). Keep a sync script. Prefer `myzig check` against the vendored tree.
- **don't:** Assume runners can see private siblings beside the checkout.
- **promote-to-code-when:** a reusable `myzig` packaging/release story exists
- **incident:** none yet (zrig vendor pattern)

### F-STD-003 · Prefer envGetOrNull when absence is normal
- **symptom:** repeated `envGet` + `catch EnvironmentVariableNotFound => null` in tools
- **do:** `myzig.compat.envGetOrNull(gpa, key)` when missing is an expected case
- **don't:** Re-learn std env APIs in every dogfood tool
- **promote-to-code-when:** already promoted → `compat.envGetOrNull`
- **incident:** ZRIG-DOGFOOD-002

### F-HARNESS-002 · Empty Actions runs usually mean billing, not Zig
- **symptom:** All matrix jobs fail in ~10s with 0 steps / no runner; annotation mentions spending limit or failed payments
- **do:** Fix GitHub Billing & plans (payment method / spending limit). Prefer ubuntu-only CI on private repos; macos is billed 10× — use `workflow_dispatch` full_matrix when needed. While Actions is blocked, run local parity: `powershell -File scripts/ci.ps1` (or `pwsh` if available)
- **don't:** Treat empty-step failures as Zig compile errors
- **promote-to-code-when:** process / workflow only
- **incident:** AGENT-CI-001

### F-STD-004 · Prefer compat for file copy/delete
- **symptom:** Dogfood tools call raw `std.Io.Dir.copyFile` / `deleteFile` and break on the next Zig reshape
- **do:** `myzig.compat.copyFile` / `deleteFile` / `renameFile` (zrig: `files.copy` / `files.delete` / `files.move`)
- **don't:** Re-learn Dir.copyFile/rename argument order in every app
- **promote-to-code-when:** already promoted → `compat.copyFile` / `deleteFile` / `renameFile`
- **incident:** ZRIG-DOGFOOD-009

### F-CLI-008 · Directory-check paths must outlive the walk
- **symptom:** `myzig check <dir>` prints `¬¬¬` / `0xAA`-filled paths; SARIF URIs unreadable
- **do:** Keep a durable owned path per file for diagnostics (do not free the walk `child` path while findings still point at it)
- **don't:** Assume GPA fills are “encoding issues” when dir checks look poisoned
- **promote-to-code-when:** already promoted → `check.Result.owned_paths` + path dupe in `checkFile`
- **incident:** AZIG-OWN-009

### F-OWN-001 · Do not invent ownership policy
- **symptom:** Agent adds `defer free` (or transfers) without knowing intent; or claims `proven`
- **do:** `myzig explain <file:line>` and pick a listed repair **intent**. Never claim above `certainty_ceiling`.
- **don't:** Silent “make it compile” ownership changes that change API contracts.
- **promote-to-code-when:** new repeated ownership pattern → incident + rule
- **incident:** MYZIG-OWN-001

### F-CLI-002 · Adopt + ratchet for legacy debt
- **symptom:** CI fails forever on existing findings; or agents “fix” debt by silencing rules
- **do:** `myzig adopt` → edit `.myzig/policy.md` → `myzig baseline` → CI `myzig check --ratchet <path>` (blocks increases only)
- **don't:** Treat ratchet ok as “no findings”; print still shows current debt
- **promote-to-code-when:** already promoted → adopt/baseline/`--ratchet` (M3 V0)
- **incident:** none yet

### F-CLI-003 · Receipts bind observed facts; claimed stays empty
- **symptom:** Agent invents `releasefast_equivalence: true` without running verify-cost
- **do:** Use `myzig receipt`; read `observed.*`; only trust `claimed` when a witness field was actually produced via `myzig verify-cost <case>`
- **don't:** Hand-edit claimed witnesses into CI artifacts
- **promote-to-code-when:** already promoted → M4 receipt + M6 verify-cost
- **incident:** none yet

### F-OWN-002 · Prefer structured myzig.permit(kind)
- **symptom:** `@ptrCast` without remark; or wrong permit kind
- **do:** `// myzig.permit(ptrcast): <reason>` (see `docs/permits.md`)
- **don't:** Silent casts; mismatched `permit(bitcast)` on `@ptrCast`
- **promote-to-code-when:** already promoted → permit kinds in detector
- **incident:** none yet

### F-CLI-004 · Zig 0.17 compile nits while shipping coach features
- **symptom:** `local variable is never mutated` (`var`→`const`); `unreachable else prong` after all CLI commands are implemented; crypto hash import path unclear on toolchain bump
- **do:** Prefer `const` by default; drop `else` when `Command` switch is exhaustive; use `std.hash.Wyhash` (or similar stable hash) for witnesses unless crypto is required
- **don't:** Leave stub `else => stubMessage` after real commands land — breaks the exe build even if `zig build test` looked green
- **promote-to-code-when:** already noted; re-hit → add CLI exhaustiveness test
- **incident:** AGENT-CLI-002

### F-CLI-005 · Start agent sessions with myzig agent
- **symptom:** Agent skips limits/friction and over-claims or reinvents policy
- **do:** Run `myzig agent` (or `--full`) once per session before editing Zig; follow the printed loop
- **don't:** Treat chat memory as the ownership policy source of truth
- **promote-to-code-when:** already promoted → `myzig agent` contract command
- **incident:** none yet

### F-CLI-006 · Zig 0.17 `trimLeft`/`trimRight` renamed
- **symptom:** `std.mem` has no member named `trimLeft` (or `trimRight`) on 0.17-dev
- **do:** Use `std.mem.trimStart` / `trimEnd` (or `trim`)
- **don't:** Copy snippets that still call `trimLeft`/`trimRight`
- **promote-to-code-when:** already hit once → keep playbook; optional compat shim only if dogfood apps keep tripping
- **incident:** none yet

### F-OWN-003 · Collection fills transfer ownership
- **symptom:** `try list.append(try allocator.dupe(...))` or `try map.put(k, try dupe(...))` flagged as undischarged
- **do:** Prefer append/put/insert + acquire (same-line or binding in args). Free collection items in `deinit` / explicit loops.
- **don't:** Add a redundant `defer free` on a pointer that was moved into an owning collection
- **promote-to-code-when:** already promoted → append/put/insert transfer (`AZIG-OWN-004`, `MYZIG-OWN-003`)
- **incident:** AZIG-OWN-004 / MYZIG-OWN-003

### F-OWN-004 · Permits may sit on the adjacent line
- **symptom:** `@ptrCast` flagged even with `// myzig.permit(ptrcast): …` on the previous line
- **do:** Keep permit on cast line or immediately adjacent line (prev/next)
- **don't:** Place the remark several lines away and expect discharge
- **promote-to-code-when:** already promoted → adjacent permit scan (`AZIG-OWN-005`)
- **incident:** AZIG-OWN-005

### F-OWN-005 · Returned struct fields take ownership
- **symptom:** `return .{ .id = try allocator.dupe(...) }` flagged as undischarged
- **do:** Prefer constructing owned structs in `return .{ ... }`; document who frees (`deinit`)
- **don't:** Add local `defer free` on a field that was returned to the caller
- **promote-to-code-when:** already promoted → returned-struct acquire span (`AZIG-OWN-006`)
- **incident:** AZIG-OWN-006

### F-OWN-006 · Empty defer is not cleanup
- **symptom:** `defer {}` left as a stub; agents think ownership is handled
- **do:** Put real free/close in the body, or delete the stub (`myzig` flags empty defer/errdefer)
- **don't:** Use comment-only defer bodies as “documentation of intent”
- **promote-to-code-when:** already promoted → `lifecycle.empty-defer` / `empty-errdefer`
- **incident:** EXT-STUDY-001

### F-OWN-007 · Prefer caller-supplied allocators
- **symptom:** helper uses `std.heap.page_allocator` / `c_allocator` so callers cannot choose arena/GPA
- **do:** Take `allocator: Allocator` (or anytype) as a parameter; skip globals outside tests
- **don't:** Hide heap policy inside library helpers
- **promote-to-code-when:** already promoted → `ownership.hidden-allocator`
- **incident:** EXT-STUDY-004

### F-OWN-008 · Do not swallow ownership-path errors
- **symptom:** `catch {}` / `catch unreachable` hides cleanup failures
- **do:** Handle, log, or document ignore with a comment inside the catch body
- **don't:** Leave empty catch on alloc/free/close paths
- **promote-to-code-when:** already promoted → `lifecycle.swallow-error`
- **incident:** EXT-STUDY-005

### F-OWN-009 · Suppress with intent, not silence
- **symptom:** need a one-off exception without disabling the rule project-wide
- **do:** `// myzig-disable-next-line rule.id - rationale` (or `myzig-disable-current-line`)
- **don't:** Broad-disable without a reason; do not expect multi-line region disables yet
- **promote-to-code-when:** already promoted → `suppress.zig`
- **incident:** EXT-STUDY-005

### F-OWN-010 · Store into owner fields
- **symptom:** `self.buf = try allocator.dupe(...)` or two-step `const x = try dupe; self.buf = x` flagged as undischarged
- **do:** Prefer field assignment into the owning struct; free in `deinit`
- **don't:** Add a local `defer free` on a pointer that was stored into `self`
- **promote-to-code-when:** already promoted → field-store transfer (same-line + binding)
- **incident:** EXT-STUDY-007 / MYZIG-OWN-003

### F-OWN-011 · Arena scratch does not need local free
- **symptom:** `try analyser.arena.dupe(...)` flagged even though arena owns it
- **do:** Allocate against the arena; let arena `deinit`/reset reclaim
- **don't:** Pair arena acquires with GPA `free` of the same pointer
- **promote-to-code-when:** already promoted → arena-token transfer
- **incident:** EXT-STUDY-008

### F-OWN-012 · Method create is not allocator.create
- **symptom:** `Context.create(handle, allocator)` flagged like `allocator.create(T)`
- **do:** Use single-arg `allocator.create(T)` for heap objects
- **don't:** Expect every `.create(` to be an ownership acquire
- **promote-to-code-when:** already promoted → single-arg `.create(` filter
- **incident:** EXT-STUDY-009

### F-OWN-013 · Pair init with deinit (or transfer)
- **symptom:** `var x = try Foo.init(...)` with no `x.deinit` and no `return x`
- **do:** `defer x.deinit(...)` or return/store the value to the owner
- **don't:** Assume every `.init` is fire-and-forget
- **promote-to-code-when:** already promoted → `lifecycle.init-without-deinit`
- **incident:** EXT-STUDY-012

### F-OWN-014 · Capability has a phase
- **symptom:** runtime alloc after “startup finished” in static-style programs
- **do:** Seal the allocator (`PhaseAllocator.seal`) or document the phase policy
- **don't:** Copy “all memory at startup” into every request-scoped app
- **promote-to-code-when:** already promoted → `myzig.compat.PhaseAllocator`
- **incident:** EXT-STUDY-010

### F-OWN-015 · Encode the mental model before fuzzing
- **symptom:** relying on fuzz/simulation alone to invent ownership rules
- **do:** Obligation → assertions/evidence → explain/repair → fuzz last
- **don't:** Mandate assertion counts or line caps as myzig policy
- **promote-to-code-when:** playbook (method); density rules intentionally not coded
- **incident:** EXT-STUDY-011

### F-OWN-016 · FFI cleanup is a separate contract
- **symptom:** Zig leak checks clean while C/OS/GPU resources still leak; wrapper `init` without `deinit`
- **do:** Document who frees across the FFI boundary; prefer `defer wrapper.deinit()` that calls C close/finalize; consider Valgrind-class tools
- **don't:** Treat GPA leak detection as whole-program proof
- **promote-to-code-when:** already promoted → `ffi.wrapper-init-without-deinit` on FFI-shaped files
- **incident:** EXT-STUDY-013 / MYZIG-OWN-005

### F-OWN-017 · Completions need stable storage
- **symptom:** stack completion reused/moved while async work is outstanding
- **do:** Keep caller-owned completion alive until callback; drain before deinit
- **don't:** Treat completion like a plain value that can be copied freely
- **promote-to-code-when:** playbook until CFG of submissions exists
- **incident:** EXT-STUDY-014

### F-OWN-018 · Request arenas reset; don't local-free
- **symptom:** `defer free` on a pointer allocated from `req.arena`
- **do:** Allocate from the request arena; let request-end `arena.reset` reclaim
- **don't:** Mix GPA `free` with arena-owned slices
- **promote-to-code-when:** arena-token transfer already covers most cases
- **incident:** EXT-STUDY-016

### F-OWN-019 · Result/query deinit may return a pool conn
- **symptom:** forgetting `defer result.deinit()` after `pool.query`
- **do:** Always pair query results with deinit; `drain` if you stop early
- **don't:** Assume row slices outlive the result/reader buffer
- **promote-to-code-when:** playbook; soft detector later if dogfood repeats
- **incident:** EXT-STUDY-017

### F-OWN-020 · Wrap C handles; deinit closes them
- **symptom:** calling raw C `close`/`finalize` at every exit while also using a Zig wrapper type
- **do:** Own the C handle behind `Wrapper.deinit` / statement-like `deinit`
- **don't:** Rely on GPA leak checks to prove C cleanup
- **promote-to-code-when:** already promoted → `ffi.wrapper-init-without-deinit`
- **incident:** EXT-STUDY-018 / MYZIG-OWN-005

### F-OWN-021 · Freestanding heaps are explicit regions
- **symptom:** hidden `page_allocator` on freestanding / embedded targets
- **do:** Use linker-heap / fixed-buffer allocator APIs for the region you own
- **don't:** Copy “no malloc ever” into hosted request-scoped servers
- **promote-to-code-when:** playbook (+ PhaseAllocator for phase-gated hosted apps)
- **incident:** EXT-STUDY-019

### F-OWN-022 · Fill caller buffers; return init in structs
- **symptom:** `into[i] = try dupe` or `return .{ .state = try State.init }` flagged
- **do:** Prefer these transfer shapes; free/`deinit` at the owner
- **don't:** Add local defer free on values stored into caller/`return .{…}`
- **promote-to-code-when:** already promoted → indexed-out + init struct return
- **incident:** EXT-STUDY-020

### F-OWN-023 · Nested owners outlive children
- **symptom:** tearing down a parent pool/env while child sessions still hold weak callbacks
- **do:** Keep identity/finalizer pools on the longest-lived owner; destroy children first
- **don't:** Assume child `deinit` frees parent-owned registration tables
- **promote-to-code-when:** playbook until cross-object CFG exists
- **incident:** EXT-STUDY-021

### F-OWN-024 · release vs destroy are different discharges
- **symptom:** calling `allocator.destroy` on a GPU/API handle, or skipping `view.release()`
- **do:** Match the API: `.release()` / object `.destroy()` for handles; `gpa.destroy` for Zig heap
- **don't:** Treat GPA leak checks as proof of external handle cleanup
- **promote-to-code-when:** `release` already discharges tracked acquires; multi-arg create still skipped
- **incident:** EXT-STUDY-022

### F-OWN-025 · Protocol teardown often uses destroy
- **symptom:** `try X.init` flagged when teardown is `name.destroy`, or listener frees the Zig wrapper
- **do:** Pair init with `defer name.destroy` when that is the API; free wrapper after protocol destroy
- **don't:** Invent a no-op `deinit` just to silence the convention note
- **promote-to-code-when:** already promoted → `destroy` matches init-without-deinit
- **incident:** EXT-STUDY-023

### F-OWN-026 · Scratch allocators are arena-shaped
- **symptom:** `defer free` on a `scratch_allocator` / short-lived frame buffer string
- **do:** Allocate from scratch; let reset/parent lifetime reclaim; set lasting allocators explicitly
- **don't:** Fall back to hidden `page_allocator`/`c_allocator` for the lasting heap without documenting it
- **promote-to-code-when:** scratch tokens already arena-discharged; hidden-allocator covers bare page/c
- **incident:** EXT-STUDY-024

### F-OWN-027 · Graphics Load pairs with Unload
- **symptom:** inventing `deinit`/`allocator.destroy` for GPU/audio extern resources
- **do:** Pair `Load*` / `init` with `.unload()` or `Unload*`; defer before leaving the scope
- **don't:** Expect GPA leak detection to prove VRAM/audio cleanup
- **promote-to-code-when:** already promoted → `unload` matches init-without-deinit and alloc discharge
- **incident:** EXT-STUDY-025

### F-OWN-028 · Unload staging CPU after GPU upload
- **symptom:** keeping a CPU image/wave after it has been uploaded to a GPU/device resource
- **do:** `unload` the staging buffer once the lasting resource exists
- **don't:** Unload the GPU texture while still drawing it
- **promote-to-code-when:** playbook; staging graphs need CFG
- **incident:** EXT-STUDY-026

### F-OWN-029 · Load GPU only after context init
- **symptom:** `LoadTexture` before window/GL context, or closing context while textures remain
- **do:** Init context first; `defer close` then `defer unload` so LIFO unloads before close
- **don't:** Rely on process exit to reclaim device resources in long-lived apps
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-026

### F-OWN-030 · begin/end modes need defer end
- **symptom:** missing `endDrawing` / `endTextureMode` after `begin*`
- **do:** `beginX(); defer endX();` for mode stacks; same for device open/close pairs
- **don't:** Treat begin/end as allocator acquires in alloc rules
- **promote-to-code-when:** playbook until mode-stack modeling exists
- **incident:** EXT-STUDY-027

### F-OWN-031 · Post-Zig runtimes are shape references only
- **symptom:** expecting Zig fixtures / AST needles from a runtime that no longer ships Zig sources
- **do:** Extract allocator *contracts* (arena, scratch, optional heap); ignore host-language syntax
- **don't:** Promote non-Zig APIs into seed detectors
- **promote-to-code-when:** playbook / study boundary
- **incident:** EXT-STUDY-028

### F-OWN-032 · Borrowed arenas need an outlives contract
- **symptom:** resetting/moving an arena while thread-local / borrowed `Allocator` wrappers still allocate
- **do:** Document “pointee outlives every alloc”; null/absent scope → explicit global heap path
- **don't:** Mix frees across arena vs global without a heap-agnostic free story
- **promote-to-code-when:** playbook until pointer+dual-heap CFG exists
- **incident:** EXT-STUDY-029

### F-OWN-033 · Single-buffer scratch; optional allocators
- **symptom:** GPA churn for temporary parse/format buffers, or forcing a fake allocator into empty values
- **do:** Reuse one buffer + reset/scope; use `?Allocator` / nullable vtable; prefer `stackFallback` / FBA when it fits
- **don't:** Call per-pointer `free` on a no-op scratch API and assume GPA sees it
- **promote-to-code-when:** playbook; compat helper only if dogfood repeats
- **incident:** EXT-STUDY-030

### F-OWN-034 · Graphics modules use setup/shutdown
- **symptom:** inventing `deinit` for a gfx module that exposes `shutdown`, or leaking `make*` resources
- **do:** `setup` + `defer shutdown`; per-resource `destroy*` (or uninit+dealloc for async)
- **don't:** Assume process exit cleans GPU pools in long-lived apps
- **promote-to-code-when:** already promoted → `shutdown`/`dealloc` discharge
- **incident:** EXT-STUDY-031

### F-OWN-035 · GPU handle pools own the real objects
- **symptom:** calling `allocator.destroy` on a `BufferHandle` or forgetting `releaseResource`
- **do:** Create/lookup/release through the graphics context; handles are not Zig heap pointers
- **don't:** Cache raw GPU pointers across `releaseResource`
- **promote-to-code-when:** playbook; `release` already helps tracked creates
- **incident:** EXT-STUDY-032

### F-OWN-036 · Drain GPU before destroying the context
- **symptom:** tearing down device/pools while frames or `mapAsync` are outstanding
- **do:** Wait for CPU/GPU frame sync (and mapped staging) before pool/`device.release`
- **don't:** Treat context `destroy` as instantaneous with in-flight work
- **promote-to-code-when:** playbook (async CFG)
- **incident:** EXT-STUDY-032

### F-OWN-037 · destroy, release, and unmap are distinct
- **symptom:** only `release` without `destroy`, skipping `unmap`, or deferring pass-encoder release too late
- **do:** Match the API: invalidate (`destroy`), drop (`release`), unmap mapped ranges; release pass encoders when the API requires
- **don't:** Assume one teardown word covers WebGPU object graphs
- **promote-to-code-when:** `unmap`/`release`/`destroy` discharge; ordering stays playbook
- **incident:** EXT-STUDY-033

### F-OWN-038 · Context may not own the Surface
- **symptom:** assuming `Context.deinit` frees the pixel surface, or mixing allocators on one surface
- **do:** Caller owns `Surface`; Context owns managed Path/font; one allocator for the surface's life
- **don't:** Pass a different allocator into later surface methods
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-034

### F-OWN-039 · Pool destroy returns a slot
- **symptom:** `gpa.destroy` on a `MemoryPool.create` pointer, or leaking pool-backed UI wrappers
- **do:** Return objects with `pool.destroy`; pair app `init`/`deinit`
- **don't:** Treat pool slots like ordinary GPA allocations
- **promote-to-code-when:** playbook (multi-arg create skipped)
- **incident:** EXT-STUDY-035

### F-OWN-040 · Binding generators are not app templates
- **symptom:** copying generator arena/XML lifetime into a game loop
- **do:** Learn `Destroy*` naming from generated APIs; ignore generator process heaps
- **don't:** Promote XML-parser patterns into seed detectors
- **promote-to-code-when:** study boundary
- **incident:** EXT-STUDY-036

### F-OWN-041 · Physical frames ≠ Zig Allocator
- **symptom:** `allocator.free` on a phys page address, or `pmm.free` on a heap pointer
- **do:** Keep PMM/buddy/stack APIs separate from `std.mem.Allocator`; free with the layer that allocated
- **don't:** Treat multiboot/mmap frame lists as GPA
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-037

### F-OWN-042 · Free at the right memory layer
- **symptom:** heap-free after unmap, or leaking frames when VMM tears down
- **do:** PMM owns frames; VMM owns mappings; heap owns bytes inside mapped regions
- **don't:** Use the HV heap as anonymous guest RAM
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-038

### F-OWN-043 · Seal boottime heaps before runtime
- **symptom:** freeing boot FBA pointers with the runtime allocator after `boottime_allocator = null`
- **do:** Boot FBA → hand leftover to lasting heap → seal; use `PhaseAllocator` when phases are explicit
- **don't:** Keep using boottime tokens after seal
- **promote-to-code-when:** `boottime_allocator` already arena-discharged
- **incident:** EXT-STUDY-039

### F-OWN-044 · Bump RAM may never free
- **symptom:** inventing `free` for a linker `__free_ram` bump allocator
- **do:** Treat bump pages as immortal (or reboot-scoped); size the RAM window honestly
- **don't:** Expect GPA leak checks on freestanding bump heaps
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-040

### F-OWN-045 · Unmap only frees owned frames
- **symptom:** `pmem.free` on every unmap, including identity/bootloader pages
- **do:** Honor PTE ownership / refcount / COW flags before returning frames to PMM
- **don't:** Assume every mapped phys page was kernel-allocated
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-041

### F-OWN-046 · Guest quotas isolate hypervisor RAM
- **symptom:** guest pages allocated without quota, or HV control objects from guest pools
- **do:** Track per-guest RAM/vCPU quotas; keep HV heap for hypervisor structures
- **don't:** Collapse guest GPA space into the HV free-list
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-042

### F-OWN-047 · Completions outlive the submit call
- **symptom:** stack Completion goes out of scope while the event loop still owns the op; forgetting cancel
- **do:** Keep completions stable until done; allocate cancel completions when required; prefer zero runtime alloc pools
- **don't:** defer loop.deinit while ops are outstanding without draining/cancel
- **promote-to-code-when:** cancel discharges; outstanding-op CFG stays playbook
- **incident:** EXT-STUDY-043

### F-OWN-048 · Connection arenas reset with a retain cap
- **symptom:** unbounded arena growth across keep-alive requests, or freeing connection buffers the pool still owns
- **do:** arena.reset(.{ .retain_with_limit = N }) per request; deinit TLS with the server
- **don't:** Mix GPA free with connection-arena slices
- **promote-to-code-when:** playbook (see also F-OWN-018)
- **incident:** EXT-STUDY-044

### F-OWN-049 · Buffer pools release or promote carefully
- **symptom:** allocator.free on a still-pooled buffer, or leaking after grow promotes out of the pool
- **do:** pool.release when pooled; after promotion free with the allocator only
- **don't:** Assume resize keeps the buffer in the pool
- **promote-to-code-when:** playbook; 
elease already helps
- **incident:** EXT-STUDY-045

### F-OWN-050 · Sockets close; network may need global init
- **symptom:** inventing deinit for sockets, or skipping process-wide network init/deinit
- **do:** defer sock.close(); pair global init/deinit when the stack requires it
- **don't:** Treat socket fds like Zig heap pointers
- **promote-to-code-when:** already promoted → close matches init + alloc discharge
- **incident:** EXT-STUDY-046

### F-OWN-051 · TLS ends with close_notify
- **symptom:** hard-closing without alert, or retaining handshake key material
- **do:** Prefer clean close_notify; scope secrets to the session
- **don't:** Log transcript secrets
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-047

### F-OWN-052 · Wasm store deinit owns memories
- **symptom:** freeing linear memory while the store still references it, or leaking the store
- **do:** defer store.deinit(); pair Memory.init/deinit; treat exports as store handles
- **don't:** Assume host slices outlive guest memory after deinit
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-048

### F-OWN-053 · Image buffers keep one allocator
- **symptom:** deinit with a different allocator than PixelStorage.init, or leaking scaled temps
- **do:** Same allocator for life; errdefer/defer every temp image
- **don't:** Return pixel slices after image deinit
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-049

### F-OWN-054 · Steady-state paths avoid GPA
- **symptom:** hot-path allocator.alloc in journals/replicas/event loops sized for static limits
- **do:** Size at startup / use static buffers; seal with PhaseAllocator when phases exist
- **don't:** Copy fuzz-only GPA usage into production steady state
- **promote-to-code-when:** playbook + PhaseAllocator
- **incident:** EXT-STUDY-050

### F-OWN-055 · Language-server stores are tooling-shaped
- **symptom:** copying DocumentStore open/close arenas into a game/server loop
- **do:** Learn document arenas for tooling; do not treat LSP as an app template
- **don't:** Promote zls-specific graphs into seed detectors
- **promote-to-code-when:** study boundary
- **incident:** EXT-STUDY-051

### F-OWN-056 · Tripwire every important errdefer
- **symptom:** errdefer paths never fail in tests
- **do:** Inject fail points; assert cleanup; reset the tripwire module
- **don't:** Assume happy-path tests prove ownership on errors
- **promote-to-code-when:** playbook / agent testing tip
- **incident:** EXT-STUDY-052

### F-OWN-057 · Wipe crypto secrets when done
- **symptom:** keys lingering in heap logs or long-lived structs
- **do:** Prefer fixed buffers; minimize copies; wipe when the API allows
- **don't:** Print nonces/keys from TLS or AEAD state
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-053

### F-AGENT-003 · Finish named external-study shortlists
- **symptom:** agent lists N concrete study repos then ships only a subset (“optional next”)
- **do:** Clone/survey/promote/ship the entire named set in one batch (or write an explicit dated debt with owners)
- **don't:** End a turn with unpaid concrete targets presented as finished work
- **promote-to-code-when:** process forever (text)
- **incident:** EXT-STUDY-054 / EXT-STUDY-062 / AGENT-STUDY-002

### F-OWN-058 · UEFI BootServices pool ends at exitBootServices
- **symptom:** treating firmware `allocatePool` like GPA, or calling BootServices after exit
- **do:** Pair `allocatePool`/`freePool` (or `uefi.pool_allocator`); loop getMemoryMap until the key matches; after `exitBootServices`, only RuntimeServices remain
- **don't:** Assume Zig heap semantics for BootServicesData
- **promote-to-code-when:** playbook (sibling freestanding regions)
- **incident:** EXT-STUDY-055

### F-OWN-059 · Type-2 HV: host allocator ≠ guest RAM
- **symptom:** allocating guest payloads with the host Zig allocator, or leaking VMM device graphs
- **do:** Host GPA for VMM objects; guest RAM via HV memslots/mmap; `defer kvm_ctx.deinit()`
- **don't:** Mix guest-physical regions into Zig `free`
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-056

### F-OWN-060 · Type-1 HV: page allocator + EPT
- **symptom:** inventing Zig heap for bare-metal HV frames, or conflating EPT walks with GPA
- **do:** Frame/page IDs from the HV page allocator; guest-phys→host-phys via EPT; seal boot UEFI map before runtime HV pages
- **don't:** Claim detectors prove EPT correctness
- **promote-to-code-when:** playbook
- **incident:** EXT-STUDY-057

### F-OWN-061 · Fuller OS stacks still layer reclaim
- **symptom:** copying one OS’s heap API into another domain, or skipping page reclaim on task teardown
- **do:** Keep PMM → VMM → heap layers; reclaim pages when unmapping; arenas for tools only
- **don't:** Promote OS-specific APIs into seed rules
- **promote-to-code-when:** playbook confirmation of kernel tips
- **incident:** EXT-STUDY-058

### F-OWN-062 · Signature arenas and HPKE exporters
- **symptom:** leaking decode arenas, or retaining HPKE export secrets
- **do:** Signature/secret decode owns an arena (`deinit` drains it); wipe/export-scope secrets like other crypto material
- **don't:** Log exporter secrets
- **promote-to-code-when:** playbook (strengthens F-OWN-057)
- **incident:** EXT-STUDY-059

### F-OWN-063 · Minimal kernels may have no Zig heap
- **symptom:** inventing GPA/arena patterns for hello/SBI teaching kernels
- **do:** Treat ownership as firmware + linker script when there is no allocator; study traps/SBI without forcing heap
- **don't:** Add allocators just to satisfy ownership dogma
- **promote-to-code-when:** study boundary
- **incident:** EXT-STUDY-060

### F-AGENT-004 · Clone blockers still require survey
- **symptom:** skipping a named study because git-lfs/Windows path/checkout failed
- **do:** Survey via GitHub API/raw README/tree; record the blocker in the incident; promote patterns that remain visible
- **don't:** Treat a failed local clone as “not named”
- **promote-to-code-when:** process forever (text)
- **incident:** EXT-STUDY-061 / AGENT-STUDY-002

### F-OWN-064 · C-runtime HTTP façades keep Zig arenas at the edge
- **symptom:** treating a C event/HTTP core as idiomatic Zig ownership, or leaking per-thread request arenas
- **do:** Drain tracked arenas on App.deinit; free Zig-owned auth/router state; learn close callbacks as FFI boundary
- **don't:** Import C-runtime APIs into seed detectors; prefer pure-Zig servers for GPA/arena templates
- **promote-to-code-when:** study boundary
- **incident:** EXT-STUDY-063

### F-OWN-065 · Named handoff or same-file freeing callee transfers
- **symptom:** `takeOwnership(buf)` or `adoptBuf(allocator, buf)` (callee frees) flagged as undischarged
- **do:** Use a named handoff API myzig knows, or keep the freeing helper in the same file; otherwise free/transfer locally
- **don't:** Expect arbitrary `foo(buf)` or other-file callees to discharge the acquire
- **promote-to-code-when:** already promoted → handoff needles + same-file callee free
- **incident:** MYZIG-OWN-004

### F-OWN-066 · FFI wrappers pair init with deinit that closes C
- **symptom:** `var db = try Db.init()` in a `c.` / `@cImport` file without `defer db.deinit()`
- **do:** Own the Zig wrapper; call C `close`/`finalize` inside `deinit`; use `myzig explain` FFI repair intents
- **don't:** Scatter bare C cleanup at every call site without a wrapper boundary
- **promote-to-code-when:** already promoted → `ffi.wrapper-init-without-deinit`
- **incident:** MYZIG-OWN-005

### F-OWN-067 · Keep sentinel types from dupeZ/allocSentinel
- **symptom:** `const plain: []u8 = try allocator.dupeZ(u8, s)` (or `[]const u8`) then `free` mismatches `len+1`
- **do:** Annotate as `[:0]u8` / matching sentinel type, or free with an explicit `ptr[0..len+1]` if erasure is intentional
- **don't:** Rely on inferred `[]u8` after a sentinel acquire
- **promote-to-code-when:** already promoted → `memory.sentinel-type-loss` (same-line only)
- **incident:** EXT-STUDY-064

### F-CLI-007 · Expected zrig outcomes are not crashes
- **symptom:** `CapabilityDenied` / `Usage` dumps Zig error-return traces; agents retry randomly
- **do:** Treat exits like myzig: `0` ok, `1` denied/failed step, `2` usage/unknown. Grant caps via `.zrig/capabilities` / `--allow` / plan `allow`
- **don't:** Assume the binary is broken when exit is 1 with a clear denial line
- **promote-to-code-when:** already promoted → zrig `std.process.exit` in `main` (ZRIG-DOGFOOD-003)
- **incident:** ZRIG-DOGFOOD-003

### F-HARNESS-003 · Prove net.http.get on loopback first
- **symptom:** External URL timeouts look like a broken HTTP tool
- **do:** `--allow net.connect`, smoke `http://127.0.0.1:<port>/` via `scripts/http-loopback-smoke.ps1` (or CI loopback step), then try outbound
- **don't:** Rewrite Client wiring before proving loopback
- **promote-to-code-when:** already promoted → zrig `scripts/http-loopback-smoke.ps1` + CI loopback gate
- **incident:** ZRIG-DOGFOOD-005

### F-HARNESS-004 · Agent tool loops need plans + receipts
- **symptom:** Agents invent ad-hoc shell scripts around `zrig run` with no audit trail
- **do:** Use `zrig agent <plan> [--receipt path] [--artifacts dir]`; record friction in this playbook
- **don't:** Embed an LLM inside zrig V2 just to get a loop
- **promote-to-code-when:** already promoted → zrig V2 agent harness
- **incident:** ZRIG-DOGFOOD-004

### F-HARNESS-005 · Receipt stop flags must match CLI behavior
- **symptom:** Agents assume every plan step ran after a mid-plan failure, or misread exit 1
- **do:** Default stops early (`stopped_early: true`); use `--continue` only when intentional; treat exit 1 + receipt `ok: false` as a failed harness run, not a crash
- **don't:** Ignore `stopped_early` / `keep_going` when debugging multi-step plans
- **promote-to-code-when:** already promoted → receipt schema 0.0.1 + V2 docs
- **incident:** ZRIG-DOGFOOD-006

### F-HARNESS-006 · MCP stdio is tools-only JSON-RPC
- **symptom:** Client expects resources/prompts/SSE, or hangs waiting for HTTP
- **do:** Point hosts at `zrig mcp serve` (stdio). Use `examples/mcp-smoke.jsonl` / `docs/mcp-client.md`. Prefer named `inputSchema` fields; `{"args":[...]}` still works. Grant caps via `.zrig/capabilities`, `ZRIG_ALLOW`, or `serve --allow`
- **don't:** Expect resources/prompts/SSE from the V3 stdio surface; use V4+ docs for model routing growth
- **promote-to-code-when:** already promoted → stdio `initialize`/`tools/*` in `src/mcp.zig`
- **incident:** ZRIG-DOGFOOD-007

### F-HARNESS-007 · Prefer named MCP tool fields over raw argv guesswork
- **symptom:** Hosts call `net.dns` / `files.read` with wrong key order or invent `query`/`file`
- **do:** Read each tool's `inputSchema` (`host`, `path`, `url`, `command`, …); fall back to `args` only when needed
- **don't:** Assume map iteration order of string fields is stable across hosts
- **promote-to-code-when:** already promoted → per-tool schemas in zrig `writeInputSchema`
- **incident:** ZRIG-DOGFOOD-008

### F-HARNESS-008 · Cursor MCP on Windows needs zrig.exe path
- **symptom:** Cursor shows zrig MCP as failed / cannot spawn; `${workspaceFolder}/zig-out/bin/zrig` without `.exe`
- **do:** Use project `.cursor/mcp.json` with an absolute `…/zrig.exe` (see zrig docs/mcp-client.md); `zig build` first; reload MCP
- **don't:** Only edit the user-global `~/.cursor/mcp.json` and forget the Windows extension
- **promote-to-code-when:** playbook + checked-in `.cursor/mcp.json` example
- **incident:** ZRIG-DOGFOOD-010

### F-HARNESS-009 · MCP tool failure is `isError`, not a server crash
- **symptom:** Host treats refused TCP / missing file as a broken MCP session, or expects process exit
- **do:** Read `tools/call` result `isError: true` and the text payload (`ConnectionRefused`, etc.). Server stays up for the next request. Smoke with `examples/mcp-smoke-iserror.jsonl` / `scripts/mcp-smoke.ps1` (PowerShell: `$ErrorActionPreference = Continue` so native stderr does not abort the pipe)
- **don't:** Restart `zrig mcp serve` or rewrite Client wiring because one tool returned an error
- **promote-to-code-when:** already promoted → `examples/mcp-smoke-iserror.jsonl` + CI/local mcp-smoke assert
- **incident:** ZRIG-DOGFOOD-011

### F-HARNESS-010 · zrig growth is unbounded; azig is retired
- **symptom:** Agents maintain azig for dogfood or refuse V4+ because of an old lock note
- **do:** Grow zrig via `docs/GROWTH.md` / `docs/V4.md`; use fpagnt as capability bar; leave azig alone unless product revival is explicit
- **don't:** Treat “V3 MCP closed” as end of zrig, or schedule azig care to mature myzig
- **promote-to-code-when:** stay text; product slices land in zrig
- **incident:** none yet

### F-HARNESS-011 · V4 ask uses mock in CI; openai_compat needs net.connect
- **symptom:** CI hangs on missing API keys, or agents call openai_compat without caps
- **do:** `zrig ask --provider mock` (+ `--receipt`) locally/CI; live path: `--provider openai_compat --allow net.connect` + `OPENAI_API_KEY` / `--api-key-env`. Cap is checked **before** missing-key. See zrig `docs/ask.md`
- **don't:** Require outbound model HTTPS for green CI; don't bypass capability policy for tools invoked mid-turn; don't chase API keys first when allow is missing
- **promote-to-code-when:** already promoted → `zrig ask` + mock CI smoke
- **incident:** ZRIG-DOGFOOD-012

### F-HARNESS-012 · zrig V5 MCP client is NDJSON + `proc.spawn`
- **symptom:** Agents use Content-Length framing against `zrig mcp serve`, or `mcp probe` without spawn allow
- **do:** `zrig mcp probe|remote-call --allow proc.spawn -- <server argv…>`; NDJSON like serve (`docs/V5.md`). Smoke in CI against self `mcp serve`
- **don't:** Assume fpagnt Content-Length client talks to zrig without an adapter
- **promote-to-code-when:** already promoted → `src/mcp_client.zig` + CI probe/remote-call
- **incident:** ZRIG-DOGFOOD-013

### F-HARNESS-013 · `ask --mcp` is double-`--` + one session
- **symptom:** Agents invent `--mcp-server=` flags or spawn a new MCP process per tool call in ask
- **do:** `zrig ask … --allow proc.spawn --mcp -- <server…> -- <prompt>`; check receipt `tool_steps[].via == "mcp"`. See zrig `docs/ask.md` / F-ZRIG-013
- **don't:** Put prompt before the second `--`
- **promote-to-code-when:** already promoted → ask `--mcp` + CI ask-mcp-receipt
- **incident:** ZRIG-DOGFOOD-014

### F-HARNESS-014 · `--mcp` uses remote `tools/list` as the model catalog
- **symptom:** Agents assume local registry tools are still advertised under `--mcp`
- **do:** Expect receipt `tools_source=mcp` and `tools_offered` from list; mock refuses unknown catalog names
- **don't:** Mix local-only tool names with `--mcp` without checking list
- **promote-to-code-when:** already promoted → turn listTools + CI greps
- **incident:** ZRIG-DOGFOOD-015

### F-HARNESS-015 · V6 plan-first / checkpoint / skills
- **symptom:** Agents skip `--approve`, misuse `--resume`, or invent skill formats
- **do:** `plan-first` + `--approve`; `--checkpoint`/`--resume`; skills = `.zrig/skills/*/SKILL.md` or `--skills-dir` (`docs/V6.md`)
- **don't:** Expect SSE streaming or web UI yet; Content-Length is V7 (`docs/V7.md`); multi-server hub is V8 (`docs/V8.md`)
- **promote-to-code-when:** already promoted → agent/skills + CI smokes
- **incident:** ZRIG-DOGFOOD-016

### F-HARNESS-016 · MCP `--framing content-length` vs ndjson
- **symptom:** Client/server hang or parse failures when framing mismatched; Windows Zig-spawn CL self-talk hangs
- **do:** Pass the same `--framing` on serve and probe/remote-call/ask; smoke serve with `python3 scripts/mcp_cl_smoke.py` (`docs/V7.md`, F-ZRIG-018)
- **don't:** Mix NDJSON lines with Content-Length peers; don't gate Win dogfood on Zig-spawn CL until pipes are fixed
- **promote-to-code-when:** already promoted → `mcp_framing.zig` + CI python smoke
- **incident:** ZRIG-DOGFOOD-017

### F-HARNESS-017 · Multi-server MCP hub namespaces
- **symptom:** Agents use bare tool names with `--mcp-servers`, or spawn one server when they meant a hub
- **do:** Offer/call `{id}.{tool}`; config under `.zrig/mcp_servers.json`; exclusive with `--mcp` (`docs/V8.md`, F-ZRIG-019)
- **don't:** Put `.` in server ids; assume local registry under hub mode
- **promote-to-code-when:** already promoted → `mcp_servers.zig` + CI hub smoke
- **incident:** ZRIG-DOGFOOD-018

### F-HARNESS-018 · Ask `--stream` vs true incremental HTTP
- **symptom:** Agents treat mock `--stream` as HTTP incremental; or regress to `readSliceShort`
- **do:** Remote receipt `stream_incremental=true`; smoke `python3 scripts/sse_stream_smoke.py` (`docs/V9.1.md`, F-ZRIG-021)
- **don't:** Use `readSliceShort` for streaming bodies; claim mock has transport incremental
- **promote-to-code-when:** already promoted → peekGreedy loop + CI handshake
- **incident:** ZRIG-DOGFOOD-020

### F-OWN-070 · `readSliceShort` fills the whole buffer before returning
- **symptom:** Streaming/chunked protocols appear buffered until EOF despite “incremental” read loops
- **do:** Use `peekGreedy(1)` + `toss`, or a single `readVec`, when one underlying `stream()` should surface early
- **don't:** Assume `readSliceShort` returns as soon as any bytes are available
- **promote-to-code-when:** stay text unless a detector is cheap
- **incident:** ZRIG-DOGFOOD-020

### F-OWN-071 · Zig 0.17 has no `std.mem.trimRight`
- **symptom:** `struct 'mem' has no member named 'trimRight'`
- **do:** Trim trailing bytes manually (`while` on `\r`/`\n`) or use `std.mem.trim` with a charset if suitable
- **don't:** Copy older Zig snippets that call `trimRight`/`trimLeft` without checking the toolchain
- **promote-to-code-when:** stay text unless agents keep repeating
- **incident:** ZRIG-DOGFOOD-021

### F-HARNESS-019 · `zrig web serve` is loopback + `net.listen`
- **symptom:** Agents forget `--allow net.listen`, or expect public bind / live providers in V10
- **do:** `web serve --allow net.listen [--max-requests N]`; smoke `python3 scripts/web_smoke.py` (`docs/V10.md`, F-ZRIG-022)
- **don't:** Bind non-loopback in V10; use `zrig editor` for stdio protocol (V10.1)
- **promote-to-code-when:** already promoted → `web.zig` + CI smoke
- **incident:** ZRIG-DOGFOOD-021

### F-HARNESS-020 · `zrig editor` JSONL stdio protocol
- **symptom:** Agents treat editor as MCP JSON-RPC, or skip `events.poll` after `task.create`
- **do:** One JSON object per line; unique `id`; methods in `docs/V10.1.md`; smoke `python3 scripts/editor_smoke.py`
- **don't:** Expect async worker/cancel/approval in V10.1; reject `..` paths in `reference.resolve`
- **promote-to-code-when:** already promoted → `editor.zig` + CI smoke
- **incident:** ZRIG-DOGFOOD-022

### F-OWN-069 · Do not use ArrayList slices after mutating the list
- **symptom:** Silent empty parses / use-after-free when a line slice into `residual.items` is kept across `clearRetainingCapacity` / `appendSlice`
- **do:** `dupe` the line (and rest) before clearing/compacting the buffer
- **don't:** Point field parsers at `items` that the next residual rewrite invalidates
- **promote-to-code-when:** stay text unless a detector is cheap
- **incident:** ZRIG-DOGFOOD-019

### F-OWN-068 · Comment-only `catch` must not hide `};`
- **symptom:** `expected ';' after statement` after documenting empty `catch {}` for swallow-error
- **do:** Multi-line `catch {\n    // intentional …\n};` so the closing brace is not line-commented
- **don't:** One-liner `catch { // reason };` (Zig comments out `};`)
- **promote-to-code-when:** stay text unless agents keep repeating
- **incident:** none yet
