#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

BUNDLE_DIR="${1:-offline/bundle}"
SUMS_FILE="${BUNDLE_DIR}/checksums/SHA256SUMS"

require_cmd sha256sum
[[ -d "$BUNDLE_DIR" ]] || die "Bundle directory '${BUNDLE_DIR}' not found."
[[ -f "$SUMS_FILE" ]] || die "Checksum manifest '${SUMS_FILE}' not found - bundle is incomplete or corrupt."

log_info "Verifying checksums in ${SUMS_FILE}..."
if ( cd "$BUNDLE_DIR" && sha256sum -c checksums/SHA256SUMS ); then
    log_ok "Bundle verified OK: every file matches its recorded checksum."
    if [[ -f "${BUNDLE_DIR}/manifests/version-manifest.json" ]]; then
        log_info "Bundle version manifest:"
        cat "${BUNDLE_DIR}/manifests/version-manifest.json"
    fi
    exit 0
else
    log_error "Bundle verification FAILED - one or more files are missing or corrupted."
    log_error "Do not import this bundle. Re-transfer it from the source machine."
    exit 1
fi
