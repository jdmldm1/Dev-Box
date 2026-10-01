#!/usr/bin/env bash
set -euo pipefail

mkdir -p "${HOME}/workspace"

exec "$@"
