#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/lib.sh

require_cmd docker
load_env

echo "=== Containers ==="
compose_cmd ps

echo
echo "=== Ports ==="
echo "code-server: http://localhost:${CODE_SERVER_PORT:-8080}"

echo
echo "=== code-server ==="
if curl -fsS -m 5 "http://localhost:${CODE_SERVER_PORT:-8080}/healthz" >/dev/null 2>&1; then
    log_ok "code-server is responding."
else
    log_warn "code-server is not responding on http://localhost:${CODE_SERVER_PORT:-8080}"
fi
