$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Import-DotEnv

Write-Info "Starting airgap-dev (project: $env:COMPOSE_PROJECT_NAME)..."

$devImage = & docker image inspect airgap-dev-dev:local 2>$null
$csImage = & docker image inspect airgap-dev-code-server:local 2>$null
if (-not $devImage -or -not $csImage) {
    Invoke-Die "Required images are missing. Run scripts\prepare-online.ps1 (online) or scripts\import-offline.ps1 (air-gapped) first."
}

Invoke-Compose -ComposeArgs @("up", "-d", "--remove-orphans")

Wait-ForHealth -ContainerName (Get-ContainerName "code-server") -TimeoutSeconds 120 | Out-Null

Write-Host ""
$codeServerPort = if ($env:CODE_SERVER_PORT) { $env:CODE_SERVER_PORT } else { "8080" }
Write-Ok "code-server: http://localhost:$codeServerPort"
Write-Ok "Run .\scripts\status.ps1 for a full health report."
