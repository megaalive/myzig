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
- **symptom:** `try list.append(try allocator.dupe(...))` flagged as undischarged
- **do:** Prefer same-line append+acquire (myzig treats as transfer). Free list items in `deinit` / explicit loops.
- **don't:** Add a redundant `defer free` on a pointer that was appended into a owning list
- **promote-to-code-when:** already promoted → same-line append transfer (`AZIG-OWN-004`)
- **incident:** AZIG-OWN-004

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
- **symptom:** `self.buf = try allocator.dupe(...)` flagged as undischarged
- **do:** Prefer field assignment into the owning struct; free in `deinit`
- **don't:** Add a local `defer free` on a pointer that was stored into `self`
- **promote-to-code-when:** already promoted → field-store transfer
- **incident:** EXT-STUDY-007

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
- **symptom:** Zig leak checks clean while C/OS/GPU resources still leak
- **do:** Document who frees across the FFI boundary; consider Valgrind-class tools
- **don't:** Treat GPA leak detection as whole-program proof
- **promote-to-code-when:** future `ffi.*` rules if incidents repeat
- **incident:** EXT-STUDY-013

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
- **promote-to-code-when:** future `ffi.*` if incidents repeat
- **incident:** EXT-STUDY-018

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
