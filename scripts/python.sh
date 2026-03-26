#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
PYENV_VERSION_TO_INSTALL="${1:-}"

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
load_proxy_settings

install_python_prerequisites() {
    log_section "Installing Python build prerequisites"
    apt_with_proxy install -y \
        make build-essential libssl-dev zlib1g-dev libbz2-dev \
        libreadline-dev libsqlite3-dev curl git libncursesw5-dev xz-utils \
        tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev \
        python3 python3-pip python3-venv pipx
}

install_pyenv() {
    log_section "Installing pyenv"

    if [[ ! -d "$PYENV_ROOT" ]]; then
        # ⚡ Bolt optimization: Shallow clone to save time/bandwidth
        git clone --depth=1 https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
    else
        log_info "pyenv is already installed."
    fi
}

install_python_version() {
    local version="$1"
    local pyenv_bin="$PYENV_ROOT/bin/pyenv"

    if [[ -z "$version" ]]; then
        return 0
    fi

    if [[ ! -x "$pyenv_bin" ]]; then
        log_error "pyenv binary not found: $pyenv_bin"
        exit 1
    fi

    log_section "Installing Python ${version} with pyenv"
    export PYENV_ROOT
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$("$pyenv_bin" init - bash)"
    "$pyenv_bin" install --skip-existing "$version"
    "$pyenv_bin" global "$version"
    log_ok "Set pyenv global Python to ${version}"
}

ensure_pipx_path() {
    log_section "Ensuring pipx path"
    python3 -m pipx ensurepath >/dev/null 2>&1 || true
}

usage() {
    cat <<'EOF'
Usage:
  ./scripts/python.sh               Install pyenv, pipx, and Python prerequisites
  ./scripts/python.sh 3.12.11       Also install and set a pyenv Python version
EOF
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

install_python_prerequisites
install_pyenv
install_python_version "$PYENV_VERSION_TO_INSTALL"
ensure_pipx_path
