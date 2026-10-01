#!/usr/bin/env bash

export MSYS_NO_PATHCONV=1

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ -t 1 ]]; then
    C_RESET=$'\033[0m'
    C_INFO=$'\033[36m'
    C_WARN=$'\033[33m'
    C_ERR=$'\033[31m'
    C_OK=$'\033[32m'
else
    C_RESET=""
    C_INFO=""
    C_WARN=""
    C_ERR=""
    C_OK=""
fi

log_info()  { printf '%s[INFO]%s  %s\n'  "$C_INFO" "$C_RESET" "$*"; }
log_warn()  { printf '%s[WARN]%s  %s\n'  "$C_WARN" "$C_RESET" "$*" >&2; }
log_error() { printf '%s[ERROR]%s %s\n' "$C_ERR"  "$C_RESET" "$*" >&2; }
log_ok()    { printf '%s[ OK ]%s  %s\n'  "$C_OK"   "$C_RESET" "$*"; }
die()       { log_error "$*"; exit 1; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command '$1' not found on PATH."
}

ensure_env_file() {
    if [[ ! -f "${REPO_ROOT}/.env" ]]; then
        if [[ ! -f "${REPO_ROOT}/.env.example" ]]; then
            die ".env.example is missing; cannot bootstrap .env."
        fi
        log_warn ".env not found - creating it from .env.example with default values."
        log_warn "Edit .env (at least CODE_SERVER_PASSWORD) before exposing this beyond localhost."
        cp "${REPO_ROOT}/.env.example" "${REPO_ROOT}/.env"
    fi
}

load_env() {
    ensure_env_file
    set -a
    source "${REPO_ROOT}/.env"
    set +a
}

container_name_for() {
    case "$1" in
        dev)         echo "airgap-dev-dev" ;;
        code-server) echo "airgap-dev-code-server" ;;
        *)           echo "$1" ;;
    esac
}

compose_cmd() {
    docker compose -f compose.yml "$@"
}

wait_for_health() {
    local name="$1" timeout="${2:-180}" waited=0
    log_info "Waiting for ${name} to become healthy (timeout ${timeout}s)..."
    while (( waited < timeout )); do
        local status
        status="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "${name}" 2>/dev/null || echo "missing")"
        case "$status" in
            healthy)        log_ok "${name} is healthy."; return 0 ;;
            no-healthcheck) log_ok "${name} is running (no healthcheck defined)."; return 0 ;;
            unhealthy)      log_warn "${name} reported unhealthy, still waiting..." ;;
            missing)        log_warn "${name} container not found yet..." ;;
        esac
        sleep 3
        waited=$((waited + 3))
    done
    log_error "${name} did not become healthy within ${timeout}s."
    return 1
}
