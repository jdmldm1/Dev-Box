param(
    [string]$Archive = ""
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Assert-Command tar

$BundleDir = "offline\bundle"

if ($Archive) {
    if (-not (Test-Path $Archive)) { Invoke-Die "Archive not found: $Archive" }
    $shaSidecar = "$Archive.sha256"
    if (Test-Path $shaSidecar) {
        Write-Info "Verifying archive checksum..."
        $expected = (Get-Content $shaSidecar | Select-Object -First 1) -split '\s+' | Select-Object -First 1
        $actual = (Get-FileHash -Algorithm SHA256 -Path $Archive).Hash.ToLower()
        if ($actual -ne $expected.ToLower()) {
            Invoke-Die "Archive checksum mismatch - the transfer may be corrupt. Re-copy the file."
        }
    } else {
        Write-Warn "No .sha256 sidecar found for the archive - skipping archive-level checksum check."
    }
    Write-Info "Extracting $Archive into offline\..."
    New-Item -ItemType Directory -Force -Path "offline" | Out-Null
    if (Test-Path $BundleDir) { Remove-Item -Recurse -Force $BundleDir }
    & tar -C offline -xzf $Archive
    if ($LASTEXITCODE -ne 0) { Invoke-Die "Failed to extract $Archive" }
}

if (-not (Test-Path $BundleDir)) { Invoke-Die "No bundle found at $BundleDir. Pass the archive path as an argument." }

Write-Info "Verifying bundle contents against checksums\SHA256SUMS..."
& .\scripts\verify-offline.ps1 $BundleDir
if ($LASTEXITCODE -ne 0) { Invoke-Die "Bundle failed verification - aborting import." }

Write-Info "Loading container images..."
Get-ChildItem (Join-Path $BundleDir "images") -Filter "*.tar" | ForEach-Object {
    Write-Info "  docker load -i $($_.FullName)"
    & docker load -i $_.FullName
    if ($LASTEXITCODE -ne 0) { Invoke-Die "docker load failed for $($_.FullName)" }
}

Write-Info "Verifying expected images are now present..."
foreach ($img in @("airgap-dev-dev:local", "airgap-dev-code-server:local")) {
    & docker image inspect $img 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Invoke-Die "Image '$img' was not loaded successfully." }
}

Write-Info "Copying default configuration if not already present..."
if (-not (Test-Path ".env")) {
    Copy-Item (Join-Path $BundleDir "config\.env.example") ".env"
    Write-Warn "Created .env from the bundle's defaults - review it (esp. CODE_SERVER_PASSWORD)."
} else {
    Write-Info ".env already exists - leaving it untouched."
}

Write-Ok "Import complete."
Write-Info "Next: .\scripts\start.ps1"
