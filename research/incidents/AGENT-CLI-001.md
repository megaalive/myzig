# AGENT-CLI-001 — expected coach outcomes must not dump stack traces

## Summary

While running `myzig check` / `explain` / unknown commands, agents treated Zig
error-return traces as crashes. Findings already exited cleanly; `Usage` and
`UnknownCommand` still returned from `main` and printed stacks.

## Symptom

```text
myzig: bad usage (try `myzig help`)
error: Usage
.../src/cli.zig:... in dispatch
.../src/main.zig:... in main
```

Harnesses also confuse exit code 1 (findings) with bad usage.

## Canonical improvement

`main` maps expected outcomes to clean `std.process.exit`:

| Outcome | Exit |
|---------|------|
| ok | 0 |
| findings / unexpected error | 1 |
| usage / unknown command | 2 |

Strip a leading `--` so `zig build run -- -- check` works.

## False-fitting risk

Unexpected internal errors still exit 1 with a short name; deeper debug may need
a future `--debug` / verbose mode.
