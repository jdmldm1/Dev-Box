$ErrorActionPreference = "Continue"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Import-DotEnv

$codeServerPort = if ($env:CODE_SERVER_PORT) { $env:CODE_SERVER_PORT } else { "8080" }

Write-Host "=== Containers ==="
& docker compose -f compose.yml ps

Write-Host ""
Write-Host "=== Ports ==="
Write-Host "code-server: http://localhost:$codeServerPort"

Write-Host ""
Write-Host "=== code-server ==="
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:$codeServerPort/healthz" -UseBasicParsing -TimeoutSec 5
    if ($resp.StatusCode -eq 200) { Write-Ok "code-server is responding." }
    else { Write-Warn "code-server returned status $($resp.StatusCode)." }
} catch {
    Write-Warn "code-server is not responding on http://localhost:$codeServerPort"
}
