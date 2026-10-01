#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

require_cmd docker
load_env

log_info "Building dev image (Go ${GO_VERSION}, .NET ${DOTNET_VERSION}, Zarf ${ZARF_VERSION})..."
compose_cmd build --pull dev

log_info "Building code-server image (code-server ${CODE_SERVER_VERSION})..."
compose_cmd build --pull code-server

log_ok "Online preparation complete."
log_info "Next: scripts/export-offline.sh to build the transferable bundle."
