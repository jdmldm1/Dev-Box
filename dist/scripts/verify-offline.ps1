param(
    [string]$BundleDir = "offline\bundle"
)
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
. .\scripts\lib.ps1

$sumsFile = Join-Path $BundleDir "checksums\SHA256SUMS"
if (-not (Test-Path $BundleDir)) { Invoke-Die "Bundle directory '$BundleDir' not found." }
if (-not (Test-Path $sumsFile)) { Invoke-Die "Checksum manifest '$sumsFile' not found - bundle is incomplete or corrupt." }

Write-Info "Verifying checksums in $sumsFile..."
$failures = 0
$checked = 0
Get-Content $sumsFile | ForEach-Object {
    $line = $_
    if (-not $line.Trim()) { return }
    if ($line -notmatch '^([0-9a-fA-F]{64})\s+(.+)$') {
        Write-Warn "Skipping unparseable line: $line"
        return
    }
    $expected = $Matches[1].ToLower()
    $rel = $Matches[2] -replace '/', '\'
    $path = Join-Path $BundleDir $rel
    $script:checked++
    if (-not (Test-Path $path)) {
        Write-Err "MISSING: $rel"
        $script:failures++
        return
    }
    $actual = (Get-FileHash -Algorithm SHA256 -Path $path).Hash.ToLower()
    if ($actual -ne $expected) {
        Write-Err "MISMATCH: $rel"
        $script:failures++
    }
}

if ($failures -eq 0) {
    Write-Ok "Bundle verified OK: all $checked files match their recorded checksum."
    $manifestPath = Join-Path $BundleDir "manifests\version-manifest.json"
    if (Test-Path $manifestPath) {
        Write-Info "Bundle version manifest:"
        Get-Content $manifestPath | Write-Host
    }
    exit 0
} else {
    Write-Err "Bundle verification FAILED - $failures file(s) missing or corrupted."
    Write-Err "Do not import this bundle. Re-transfer it from the source machine."
    exit 1
}
