#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

require_cmd docker
require_cmd tar

ARCHIVE="${1:-}"
BUNDLE_DIR="offline/bundle"

if [[ -n "$ARCHIVE" ]]; then
    [[ -f "$ARCHIVE" ]] || die "Archive not found: $ARCHIVE"
    if [[ -f "${ARCHIVE}.sha256" ]]; then
        log_info "Verifying archive checksum..."
        ( cd "$(dirname "$ARCHIVE")" && sha256sum -c "$(basename "${ARCHIVE}.sha256")" ) \
            || die "Archive checksum mismatch - the transfer may be corrupt. Re-copy the file."
    else
        log_warn "No .sha256 sidecar found for the archive - skipping archive-level checksum check."
    fi
    log_info "Extracting ${ARCHIVE} into offline/..."
    mkdir -p offline
    rm -rf "$BUNDLE_DIR"
    tar -C offline -xzf "$ARCHIVE"
fi

[[ -d "$BUNDLE_DIR" ]] || die "No bundle found at ${BUNDLE_DIR}. Pass the archive path as an argument."

log_info "Verifying bundle contents against checksums/SHA256SUMS..."
scripts/verify-offline.sh "$BUNDLE_DIR" || die "Bundle failed verification - aborting import."

log_info "Loading container images..."
for tarball in "${BUNDLE_DIR}"/images/*.tar; do
    [[ -f "$tarball" ]] || die "Expected image tarball missing: $tarball"
    log_info "  docker load -i ${tarball}"
    docker load -i "$tarball"
done

log_info "Verifying expected images are now present..."
for img in airgap-dev:local; do
    docker image inspect "$img" >/dev/null 2>&1 || die "Image '$img' was not loaded successfully."
done

log_info "Copying default configuration if not already present..."
if [[ ! -f .env ]]; then
    cp "${BUNDLE_DIR}/config/.env.example" .env
    log_warn "Created .env from the bundle's defaults - review it (esp. CODE_SERVER_PASSWORD)."
else
    log_info ".env already exists - leaving it untouched."
fi

log_ok "Import complete."
log_info "Next: scripts/start.sh"
