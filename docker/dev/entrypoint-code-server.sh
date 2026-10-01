#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${HOME}/.local/share/code-server/User"
mkdir -p "${HOME}/workspace"

exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    --extensions-dir /opt/code-server/extensions \
    --user-data-dir "${HOME}/.local/share/code-server" \
    "${HOME}/workspace"
