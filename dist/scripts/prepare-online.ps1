$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Import-DotEnv

Write-Info "Building image (Go $env:GO_VERSION, .NET $env:DOTNET_VERSION, Zarf $env:ZARF_VERSION, code-server $env:CODE_SERVER_VERSION)..."
Invoke-Compose -ComposeArgs @("build", "--pull", "dev-box")

Write-Ok "Online preparation complete."
Write-Info "Next: .\scripts\export-offline.ps1 to build the transferable bundle."
