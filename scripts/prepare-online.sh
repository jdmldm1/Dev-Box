#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

require_cmd docker
load_env

log_info "Building image (Go ${GO_VERSION}, .NET ${DOTNET_VERSION}, Zarf ${ZARF_VERSION}, code-server ${CODE_SERVER_VERSION})..."
compose_cmd build --pull dev-box

log_ok "Online preparation complete."
log_info "Next: scripts/export-offline.sh to build the transferable bundle."
