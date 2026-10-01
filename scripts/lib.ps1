$script:RepoRoot = Split-Path $PSScriptRoot -Parent

function Write-Info  { param([string]$Message) Write-Host "[INFO]  $Message" -ForegroundColor Cyan }
function Write-Warn  { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Warn2 { param([string]$Message) Write-Host "[WARN]  $Message" -ForegroundColor Yellow }
function Write-Err   { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Err2  { param([string]$Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Ok    { param([string]$Message) Write-Host "[ OK ]  $Message" -ForegroundColor Green }

function Invoke-Die {
    param([string]$Message)
    Write-Err $Message
    exit 1
}

function Assert-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        Invoke-Die "Required command '$Name' not found on PATH."
    }
}

function Confirm-EnvFile {
    $envPath = Join-Path $script:RepoRoot ".env"
    $examplePath = Join-Path $script:RepoRoot ".env.example"
    if (-not (Test-Path $envPath)) {
        if (-not (Test-Path $examplePath)) {
            Invoke-Die ".env.example is missing; cannot bootstrap .env."
        }
        Write-Warn ".env not found - creating it from .env.example with default values."
        Write-Warn "Edit .env (at least CODE_SERVER_PASSWORD) before exposing this beyond localhost."
        Copy-Item $examplePath $envPath
    }
}

function Import-DotEnv {
    Confirm-EnvFile
    $envPath = Join-Path $script:RepoRoot ".env"
    Get-Content $envPath | ForEach-Object {
        $line = $_.Trim()
        if ($line -eq "" -or $line.StartsWith("#")) { return }
        $idx = $line.IndexOf("=")
        if ($idx -lt 1) { return }
        $key = $line.Substring(0, $idx).Trim()
        $value = $line.Substring($idx + 1).Trim()
        Set-Item -Path "Env:$key" -Value $value
    }
}

function Get-ContainerName {
    param([string]$Service)
    switch ($Service) {
        "dev"         { return "airgap-dev-dev" }
        "code-server" { return "airgap-dev-code-server" }
        default       { return $Service }
    }
}

function Invoke-Compose {
    param(
        [Parameter(Mandatory = $true)][string[]]$ComposeArgs
    )
    & docker compose -f compose.yml @ComposeArgs
    if ($LASTEXITCODE -ne 0) {
        Invoke-Die "docker compose $($ComposeArgs -join ' ') failed (exit $LASTEXITCODE)."
    }
}

function Wait-ForHealth {
    param(
        [Parameter(Mandatory = $true)][string]$ContainerName,
        [int]$TimeoutSeconds = 180
    )
    Write-Info "Waiting for $ContainerName to become healthy (timeout ${TimeoutSeconds}s)..."
    $waited = 0
    while ($waited -lt $TimeoutSeconds) {
        $status = & docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' $ContainerName 2>$null
        if ($LASTEXITCODE -ne 0 -or -not $status) { $status = "missing" }
        switch ($status.Trim()) {
            "healthy"        { Write-Ok "$ContainerName is healthy."; return $true }
            "no-healthcheck" { Write-Ok "$ContainerName is running (no healthcheck defined)."; return $true }
            "unhealthy"      { Write-Warn "$ContainerName reported unhealthy, still waiting..." }
            default          { Write-Warn "$ContainerName container not found yet..." }
        }
        Start-Sleep -Seconds 3
        $waited += 3
    }
    Write-Err "$ContainerName did not become healthy within ${TimeoutSeconds}s."
    return $false
}
