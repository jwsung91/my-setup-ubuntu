#!/bin/bash
set -euo pipefail

FONT_DIR="$HOME/.local/share/fonts"
TEMP_DIR="$(mktemp -d)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
load_proxy_settings

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

log_section "Installing the D2Coding font"
mkdir -p "$FONT_DIR"

# ⚡ Bolt optimization: Add early returns to skip unnecessary apt processing
PACKAGES=()
if ! fc-list | grep -qi "D2Coding"; then
    PACKAGES+=("unzip")
fi
if ! command -v colorls >/dev/null 2>&1; then
    PACKAGES+=("ruby-full")
fi

if [[ ${#PACKAGES[@]} -gt 0 ]]; then
    apt_with_proxy install -y "${PACKAGES[@]}"
fi

if ! fc-list | grep -qi "D2Coding"; then
    cd "$TEMP_DIR"
    wget https://github.com/naver/d2codingfont/releases/download/VER1.3.2/D2Coding-Ver1.3.2-20180524.zip
    unzip D2Coding-Ver1.3.2-20180524.zip
    cp D2Coding/*.ttf "$FONT_DIR/"
    fc-cache -f
else
    log_info "D2Coding font is already installed."
fi

log_section "Installing colorls (Ruby gem)"
if ! command -v colorls >/dev/null 2>&1; then
    # ⚡ Bolt optimization: Skip slow doc generation
    gem_with_proxy install colorls -N
else
    log_info "colorls is already installed."
fi
