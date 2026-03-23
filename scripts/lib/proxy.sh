#!/bin/bash

LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/ui.sh"

PROJECT_ROOT="$(cd "$LIB_DIR/../.." && pwd)"
PROXY_ENV_FILE="${MY_SETUP_PROXY_FILE:-$PROJECT_ROOT/.proxy.env}"

sync_proxy_environment() {
    if [[ -n "${HTTP_PROXY:-}" && -z "${http_proxy:-}" ]]; then
        export http_proxy="$HTTP_PROXY"
    elif [[ -n "${http_proxy:-}" && -z "${HTTP_PROXY:-}" ]]; then
        export HTTP_PROXY="$http_proxy"
    fi

    if [[ -n "${HTTPS_PROXY:-}" && -z "${https_proxy:-}" ]]; then
        export https_proxy="$HTTPS_PROXY"
    elif [[ -n "${https_proxy:-}" && -z "${HTTPS_PROXY:-}" ]]; then
        export HTTPS_PROXY="$https_proxy"
    fi

    if [[ -n "${NO_PROXY:-}" && -z "${no_proxy:-}" ]]; then
        export no_proxy="$NO_PROXY"
    elif [[ -n "${no_proxy:-}" && -z "${NO_PROXY:-}" ]]; then
        export NO_PROXY="$no_proxy"
    fi
}

load_proxy_settings() {
    if [[ -f "$PROXY_ENV_FILE" ]]; then
        set -a
        source "$PROXY_ENV_FILE"
        set +a
        log_info "Loaded proxy settings from $PROXY_ENV_FILE"
    fi

    sync_proxy_environment
}

proxy_sudo() {
    local -a env_args=()

    if [[ -n "${HTTP_PROXY:-}" ]]; then
        env_args+=("HTTP_PROXY=$HTTP_PROXY" "http_proxy=${http_proxy:-$HTTP_PROXY}")
    fi

    if [[ -n "${HTTPS_PROXY:-}" ]]; then
        env_args+=("HTTPS_PROXY=$HTTPS_PROXY" "https_proxy=${https_proxy:-$HTTPS_PROXY}")
    fi

    if [[ -n "${NO_PROXY:-}" ]]; then
        env_args+=("NO_PROXY=$NO_PROXY" "no_proxy=${no_proxy:-$NO_PROXY}")
    fi

    if [[ ${#env_args[@]} -gt 0 ]]; then
        sudo env "${env_args[@]}" "$@"
    else
        sudo "$@"
    fi
}

apt_with_proxy() {
    proxy_sudo apt "$@"
}

gem_with_proxy() {
    proxy_sudo gem "$@"
}
