# Local CI parity when GitHub Actions is blocked (billing) or offline.
$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "== zig fmt --check =="
zig fmt --check src build.zig
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "== zig build =="
zig build
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "== zig build test =="
zig build test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "== CLI smoke =="
# Prefer Git Bash over WSL bash (WSL cannot see D: paths this way).
$bash = $null
foreach ($c in @(
        "C:\Program Files\Git\bin\bash.exe",
        "C:\Program Files (x86)\Git\bin\bash.exe"
    )) {
    if (Test-Path $c) { $bash = $c; break }
}
if (-not $bash) {
    $cmd = Get-Command bash -ErrorAction SilentlyContinue
    if ($cmd) { $bash = $cmd.Source }
}
if (-not $bash) {
    throw "bash not found. Install Git for Windows to run scripts/ci-smoke.sh"
}

# Relative path from repo root (avoids WSL/drive mapping issues).
& $bash "./scripts/ci-smoke.sh"
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "ci.ps1: ok"
