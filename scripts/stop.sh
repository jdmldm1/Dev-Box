#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

require_cmd docker
load_env

if [[ "${1:-}" == "--remove-volumes" ]]; then
    log_warn "Stopping and REMOVING volumes (code-server data will be lost)..."
    read -r -p "Type 'yes' to confirm: " confirm
    [[ "$confirm" == "yes" ]] || die "Aborted."
    compose_cmd down --volumes
else
    log_info "Stopping airgap-dev (volumes preserved)..."
    compose_cmd down
fi

log_ok "Stopped."
