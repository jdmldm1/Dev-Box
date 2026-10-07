param(
    [switch]$RemoveVolumes
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Import-DotEnv

if ($RemoveVolumes) {
    Write-Warn "Stopping and REMOVING volumes (code-server data will be lost)..."
    $confirm = Read-Host "Type 'yes' to confirm"
    if ($confirm -ne "yes") { Invoke-Die "Aborted." }
    Invoke-Compose -ComposeArgs @("down", "--volumes")
} else {
    Write-Info "Stopping airgap-dev (volumes preserved)..."
    Invoke-Compose -ComposeArgs @("down")
}

Write-Ok "Stopped."
