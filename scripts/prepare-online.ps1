$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Import-DotEnv

Write-Info "Building dev image (Go $env:GO_VERSION, .NET $env:DOTNET_VERSION, Zarf $env:ZARF_VERSION)..."
Invoke-Compose -ComposeArgs @("build", "--pull", "dev")

Write-Info "Building code-server image (code-server $env:CODE_SERVER_VERSION)..."
Invoke-Compose -ComposeArgs @("build", "--pull", "code-server")

Write-Ok "Online preparation complete."
Write-Info "Next: .\scripts\export-offline.ps1 to build the transferable bundle."
