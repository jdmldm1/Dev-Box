$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Import-DotEnv

Write-Info "Starting airgap-dev (project: $env:COMPOSE_PROJECT_NAME)..."

$image = & docker image inspect airgap-dev:local 2>$null
if (-not $image) {
    Invoke-Die "Required image is missing. Run scripts\prepare-online.ps1 (online) or scripts\import-offline.ps1 (air-gapped) first."
}

Invoke-Compose -ComposeArgs @("up", "-d", "--remove-orphans")

Wait-ForHealth -ContainerName (Get-ContainerName "dev-box") -TimeoutSeconds 120 | Out-Null

Write-Host ""
$codeServerPort = if ($env:CODE_SERVER_PORT) { $env:CODE_SERVER_PORT } else { "8080" }
Write-Ok "code-server: http://localhost:$codeServerPort"
Write-Ok "Run .\scripts\status.ps1 for a full health report."
