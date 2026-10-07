#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

require_cmd docker
load_env

log_info "Starting airgap-dev (project: ${COMPOSE_PROJECT_NAME:-airgap-dev})..."
if ! docker image inspect airgap-dev:local >/dev/null 2>&1; then
    die "Required image is missing. Run scripts/prepare-online.sh (online) or scripts/import-offline.sh (air-gapped) first."
fi

compose_cmd up -d --remove-orphans

wait_for_health "$(container_name_for dev-box)" 120

echo
log_ok "code-server: http://localhost:${CODE_SERVER_PORT:-8080}"
log_ok "Run scripts/status.sh for a full health report."
