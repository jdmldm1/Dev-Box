#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${HOME}/.local/share/code-server/User"
mkdir -p "${HOME}/workspace"

# code-server is a full shell with passwordless sudo, so a placeholder or trivial password is
# effectively an open door for anything that can reach the port. Warn rather than refuse so
# existing deployments keep starting.
case "${PASSWORD:-}" in
    password | changeme* | CHANGE_ME* | admin | 12345678)
        echo "WARNING: code-server is using a placeholder/weak password. Set a strong CODE_SERVER_PASSWORD." >&2
        ;;
esac

exec code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth password \
    --extensions-dir /opt/code-server/extensions \
    --user-data-dir "${HOME}/.local/share/code-server" \
    "${HOME}/workspace"
