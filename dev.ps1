param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CmdArgs
)
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot
. .\scripts\lib.ps1
Import-DotEnv

$containerName = Get-ContainerName "dev"
$running = & docker inspect -f '{{.State.Running}}' $containerName 2>$null
if ($LASTEXITCODE -ne 0 -or $running -ne "true") {
    Invoke-Die "The dev container isn't running. Start it with .\scripts\start.ps1 first."
}

if (-not $CmdArgs -or $CmdArgs.Count -eq 0) { $CmdArgs = @("shell") }
$cmd = $CmdArgs[0]

switch ($cmd) {
    "shell" {
        & docker compose exec -it dev bash
    }
    default {
        & docker compose exec -it dev @CmdArgs
    }
}
exit $LASTEXITCODE
