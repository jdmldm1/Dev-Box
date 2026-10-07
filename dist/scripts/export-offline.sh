#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

require_cmd docker
load_env

BUNDLE_DIR="offline/bundle"
IMAGES=(
    "airgap-dev:local|images/airgap-dev.tar"
)

log_info "Verifying required images exist locally..."
for entry in "${IMAGES[@]}"; do
    img="${entry%%|*}"
    if ! docker image inspect "$img" >/dev/null 2>&1; then
        die "Image '$img' not found locally. Run scripts/prepare-online.sh first."
    fi
done

log_info "Resetting ${BUNDLE_DIR}..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"/{images,manifests,checksums,compose}

log_info "Saving container images (this can take a few minutes)..."
for entry in "${IMAGES[@]}"; do
    img="${entry%%|*}"
    dest="${entry#*|}"
    log_info "  docker save $img -> ${dest}"
    docker save "$img" -o "${BUNDLE_DIR}/${dest}"
done

log_info "Copying config, compose files, and scripts into the bundle..."
cp -r config "${BUNDLE_DIR}/config"
cp .env.example "${BUNDLE_DIR}/config/.env.example"
cp compose.yml "${BUNDLE_DIR}/compose/"
cp -r scripts "${BUNDLE_DIR}/scripts"
cp -r docker "${BUNDLE_DIR}/docker" 2>/dev/null || true
[[ -f dev ]] && cp dev "${BUNDLE_DIR}/dev"
[[ -f dev.ps1 ]] && cp dev.ps1 "${BUNDLE_DIR}/dev.ps1"
[[ -f README.md ]] && cp README.md "${BUNDLE_DIR}/README.md" 2>/dev/null || true

log_info "Writing version manifest..."
IMAGE_DIGEST="$(docker image inspect --format='{{index .RepoDigests 0}}' airgap-dev:local 2>/dev/null || echo 'n/a (locally built, no registry digest)')"
BUILD_HOST="$(hostname 2>/dev/null || echo unknown)"

cat > "${BUNDLE_DIR}/manifests/version-manifest.json" <<EOF
{
  "bundle_format": 1,
  "built_on_host": "${BUILD_HOST}",
  "images": {
    "airgap-dev:local": "${IMAGE_DIGEST}"
  },
  "versions": {
    "GO_VERSION": "${GO_VERSION}",
    "GOPLS_VERSION": "${GOPLS_VERSION}",
    "DOTNET_VERSION": "${DOTNET_VERSION}",
    "ZARF_VERSION": "${ZARF_VERSION}",
    "CODE_SERVER_VERSION": "${CODE_SERVER_VERSION}",
    "GOLANG_EXT_VERSION": "${GOLANG_EXT_VERSION}",
    "CSHARP_EXT_VERSION": "${CSHARP_EXT_VERSION}"
  }
}
EOF

log_info "Generating checksums..."
(
    cd "$BUNDLE_DIR"
    find . -type f ! -path "./checksums/*" -print0 | sort -z | xargs -0 sha256sum > checksums/SHA256SUMS
)

ARCHIVE_NAME="airgap-dev-offline-bundle.tar.gz"
log_info "Creating transfer archive offline/${ARCHIVE_NAME}..."
tar -C offline -czf "offline/${ARCHIVE_NAME}" bundle
( cd offline && sha256sum "${ARCHIVE_NAME}" > "${ARCHIVE_NAME}.sha256" )

log_ok "Offline bundle ready:"
log_ok "  Directory: ${BUNDLE_DIR}/"
log_ok "  Archive:   offline/${ARCHIVE_NAME}"
log_info "Transfer the archive (and its .sha256 file) to the air-gapped machine, then run scripts/import-offline.sh."
