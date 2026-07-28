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
