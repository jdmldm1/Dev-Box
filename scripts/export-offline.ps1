$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

Assert-Command docker
Import-DotEnv

$BundleDir = "offline\bundle"
$Images = @(
    @{ Name = "airgap-dev-dev:local"; Dest = "images\dev.tar" },
    @{ Name = "airgap-dev-code-server:local"; Dest = "images\code-server.tar" }
)

Write-Info "Verifying required images exist locally..."
foreach ($img in $Images) {
    & docker image inspect $img.Name 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Invoke-Die "Image '$($img.Name)' not found locally. Run .\scripts\prepare-online.ps1 first." }
}

Write-Info "Resetting $BundleDir..."
if (Test-Path $BundleDir) { Remove-Item -Recurse -Force $BundleDir }
foreach ($sub in @("images", "manifests", "config", "scripts", "checksums", "compose")) {
    New-Item -ItemType Directory -Force -Path (Join-Path $BundleDir $sub) | Out-Null
}

Write-Info "Saving container images (this can take a few minutes)..."
foreach ($img in $Images) {
    $dest = Join-Path $BundleDir $img.Dest
    Write-Info "  docker save $($img.Name) -> $dest"
    & docker save $img.Name -o $dest
    if ($LASTEXITCODE -ne 0) { Invoke-Die "docker save failed for $($img.Name)" }
}

Write-Info "Copying config, compose files, and scripts into the bundle..."
Copy-Item -Recurse -Force config (Join-Path $BundleDir "config")
Copy-Item -Force .env.example (Join-Path $BundleDir "config\.env.example")
Copy-Item -Force compose.yml (Join-Path $BundleDir "compose")
Copy-Item -Recurse -Force scripts (Join-Path $BundleDir "scripts")
if (Test-Path docker) { Copy-Item -Recurse -Force docker (Join-Path $BundleDir "docker") }
if (Test-Path dev) { Copy-Item -Force dev (Join-Path $BundleDir "dev") }
if (Test-Path dev.ps1) { Copy-Item -Force dev.ps1 (Join-Path $BundleDir "dev.ps1") }
if (Test-Path README.md) { Copy-Item -Force README.md (Join-Path $BundleDir "README.md") }

Write-Info "Writing version manifest..."
function Get-Digest($name) {
    $d = & docker image inspect --format='{{index .RepoDigests 0}}' $name 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $d) { return "n/a" }
    return $d
}
$manifest = @{
    bundle_format  = 1
    built_on_host  = $env:COMPUTERNAME
    images         = @{
        "airgap-dev-dev:local"         = Get-Digest "airgap-dev-dev:local"
        "airgap-dev-code-server:local" = Get-Digest "airgap-dev-code-server:local"
    }
    versions       = @{
        GO_VERSION           = $env:GO_VERSION
        GOPLS_VERSION        = $env:GOPLS_VERSION
        DOTNET_VERSION       = $env:DOTNET_VERSION
        ZARF_VERSION         = $env:ZARF_VERSION
        CODE_SERVER_VERSION  = $env:CODE_SERVER_VERSION
        GOLANG_EXT_VERSION   = $env:GOLANG_EXT_VERSION
        CSHARP_EXT_VERSION   = $env:CSHARP_EXT_VERSION
    }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 (Join-Path $BundleDir "manifests\version-manifest.json")

Write-Info "Generating checksums..."
Push-Location $BundleDir
try {
    $files = Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\\checksums\\' } | Sort-Object FullName
    $lines = foreach ($f in $files) {
        $hash = (Get-FileHash -Algorithm SHA256 -Path $f.FullName).Hash.ToLower()
        $rel = $f.FullName.Substring((Get-Location).Path.Length + 1) -replace '\\', '/'
        "$hash  $rel"
    }
    Set-Content -Encoding utf8 -Path "checksums\SHA256SUMS" -Value $lines
} finally {
    Pop-Location
}

Assert-Command tar
$ArchiveName = "airgap-dev-offline-bundle.tar.gz"
Write-Info "Creating transfer archive offline\$ArchiveName..."
$archivePath = Join-Path "offline" $ArchiveName
if (Test-Path $archivePath) { Remove-Item -Force $archivePath }
& tar -C offline -czf $archivePath bundle
if ($LASTEXITCODE -ne 0) { Invoke-Die "Failed to create $archivePath" }
(Get-FileHash -Algorithm SHA256 -Path $archivePath).Hash.ToLower() + "  $ArchiveName" | Set-Content -Encoding utf8 "$archivePath.sha256"

Write-Ok "Offline bundle ready:"
Write-Ok "  Directory: $BundleDir\"
Write-Ok "  Archive:   $archivePath"
Write-Info "Transfer the archive (and its .sha256 file) to the air-gapped machine, then run .\scripts\import-offline.ps1."
