#!/usr/bin/env bash
# CLI smoke parity with GitHub Actions (run after zig build).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if [[ -f zig-out/bin/myzig.exe ]]; then
  BIN=zig-out/bin/myzig.exe
elif [[ -x zig-out/bin/myzig ]]; then
  BIN=zig-out/bin/myzig
else
  BIN=zig-out/bin/myzig.exe
fi
# head closes early; ignore SIGPIPE under pipefail
head1() { head -n "$1" || true; }

# Fresh project state so early receipt asserts empty claimed.
rm -rf .myzig

"$BIN" version
"$BIN" rules --json | head1 5
"$BIN" init
test -f .myzig/README.md
if "$BIN" check fixtures/fail/alloc_undischarged.zig; then echo "expected findings on fail fixture" >&2; exit 1; fi
if "$BIN" check fixtures/fail/alloc_print_undischarged.zig; then echo "expected allocPrint findings" >&2; exit 1; fi
if "$BIN" check fixtures/fail/alloc_concat_undischarged.zig; then echo "expected concat findings" >&2; exit 1; fi
"$BIN" check fixtures/pass/alloc_defer_free.zig
"$BIN" check fixtures/pass/alloc_return_local.zig
"$BIN" check fixtures/pass/alloc_return_alias.zig
"$BIN" check fixtures/pass/alloc_return_chain.zig
"$BIN" check fixtures/pass/alloc_out_param.zig
"$BIN" check fixtures/pass/alloc_explicit_free.zig
"$BIN" check fixtures/pass/alloc_print_return.zig
"$BIN" check fixtures/pass/alloc_append_transfer.zig
"$BIN" check fixtures/pass/alloc_append_multiline.zig
"$BIN" check fixtures/pass/alloc_struct_return.zig
"$BIN" check fixtures/pass/alloc_retarget.zig
"$BIN" check fixtures/pass/alloc_field_store.zig
"$BIN" check fixtures/pass/alloc_field_store_binding.zig
"$BIN" check fixtures/pass/alloc_put_transfer.zig
"$BIN" check fixtures/pass/alloc_take_ownership.zig
"$BIN" check fixtures/pass/alloc_callee_free.zig
"$BIN" check fixtures/pass/alloc_arena_backed.zig
"$BIN" check fixtures/pass/method_create_store.zig
"$BIN" check fixtures/pass/alloc_indexed_out.zig
"$BIN" check fixtures/pass/init_defer_deinit.zig
"$BIN" check fixtures/pass/init_struct_return.zig
"$BIN" check fixtures/pass/file_defer_close.zig
"$BIN" check fixtures/pass/file_return.zig
"$BIN" check fixtures/pass/ptrcast_remarked.zig
"$BIN" check fixtures/pass/ptrcast_adjacent.zig
if "$BIN" check fixtures/fail/empty_defer.zig; then echo "expected empty defer finding" >&2; exit 1; fi
if "$BIN" check fixtures/fail/empty_errdefer.zig; then echo "expected empty errdefer finding" >&2; exit 1; fi
if "$BIN" check fixtures/fail/hidden_allocator.zig; then echo "expected hidden allocator finding" >&2; exit 1; fi
if "$BIN" check fixtures/fail/swallow_error.zig; then echo "expected swallow error finding" >&2; exit 1; fi
if "$BIN" check fixtures/fail/init_without_deinit.zig; then echo "expected init-without-deinit finding" >&2; exit 1; fi
if "$BIN" check fixtures/fail/ffi_wrapper_init_without_deinit.zig; then echo "expected ffi wrapper init finding" >&2; exit 1; fi
"$BIN" check fixtures/pass/ffi_wrapper_deinit_closes.zig
if "$BIN" check fixtures/fail/file_undischarged.zig; then echo "expected file finding" >&2; exit 1; fi
if "$BIN" check fixtures/fail/ptrcast_unremarked.zig; then echo "expected ptrcast finding" >&2; exit 1; fi
if "$BIN" check --prefer-compat fixtures/fail/volatile_std.zig; then echo "expected volatile-std finding" >&2; exit 1; fi
"$BIN" check fixtures/fail/volatile_std.zig
set +e
out=$("$BIN" explain 2>&1)
code=$?
set -e
test "$code" -eq 2
echo "$out" | grep -q "bad usage"
if echo "$out" | grep -q "error: Usage"; then echo "usage still dumps error return trace" >&2; exit 1; fi
set +e
out=$("$BIN" nope 2>&1)
code=$?
set -e
test "$code" -eq 2
if echo "$out" | grep -q "error: UnknownCommand"; then echo "unknown still dumps error return trace" >&2; exit 1; fi
"$BIN" explain fixtures/fail/alloc_undischarged.zig:11 | head1 20
"$BIN" explain fixtures/fail/alloc_undischarged.zig:11 --json | grep -q '"repair_choices"'
"$BIN" explain --rule memory.alloc-undischarged --agent | grep -q "Repair intents"
set +e
"$BIN" receipt fixtures/fail/alloc_undischarged.zig > receipt.json
code=$?
set -e
head1 8 < receipt.json
test "$code" -ne 0
grep -q '"findings": 1' receipt.json
grep -q '"source_revision"' receipt.json
grep -q '"ruleset_revision"' receipt.json
grep -q '"claimed": {}' receipt.json
grep -q '"unsafe_by_kind"' receipt.json
"$BIN" explain --rule memory.alloc-undischarged | head1 10
"$BIN" explain --rule compat.volatile-std | head1 10
"$BIN" friction --sources | head1 20
"$BIN" friction | grep -q "F-STD-001"
rm -rf .myzig
"$BIN" adopt fixtures/pass > adopt.out
test -f .myzig/policy.md
test -f .myzig/baseline.json
grep -q "Zig files" adopt.out
"$BIN" check --ratchet fixtures/pass
if "$BIN" check --ratchet fixtures/fail; then echo "expected ratchet failure on fixtures/fail" >&2; exit 1; fi
"$BIN" baseline fixtures/fail > /dev/null
"$BIN" check --ratchet fixtures/fail
"$BIN" check fixtures/pass/ptrcast_remarked.zig
"$BIN" verify-cost --list | grep -q id-passthrough
"$BIN" verify-cost id-passthrough
test -f .myzig/cost-witnesses/id-passthrough.json
"$BIN" receipt fixtures/pass/alloc_defer_free.zig > receipt-cost.json
grep -q '"verify_cost"' receipt-cost.json
grep -q 'id-passthrough' receipt-cost.json
"$BIN" limits | grep -q "Certainty"
"$BIN" limits --sources | grep -q "docs/LIMITS.md"
"$BIN" agent | grep -q "Self-correction loop"
"$BIN" agent --full | grep -q "myzig agent rule card"
"$BIN" rules --sarif | grep -q "memory.alloc-undischarged"
set +e
"$BIN" check --sarif fixtures/fail/alloc_undischarged.zig > sarif.json
code=$?
set -e
test "$code" -ne 0
grep -q '"ruleId": "memory.alloc-undischarged"' sarif.json
grep -q '"version": "2.1.0"' sarif.json
grep -q '"ruleIndex"' sarif.json
grep -q 'primaryLocationLineHash' sarif.json
grep -q '"automationDetails"' sarif.json
grep -q 'helpUri' sarif.json
echo "ci-smoke: ok"