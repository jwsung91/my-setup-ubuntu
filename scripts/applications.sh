#!/bin/bash
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
UBUNTU_VERSION="$(lsb_release -rs)"
TMP_DIR="$(mktemp -d)"
INSTALL_VSCODE=0
INSTALL_CHROME=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
load_proxy_settings

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

usage() {
    cat <<'EOF'
Usage:
  ./scripts/applications.sh           Choose applications interactively
  ./scripts/applications.sh all       Install every application
  ./scripts/applications.sh vscode    Install VS Code only
  ./scripts/applications.sh chrome    Install Google Chrome only
  ./scripts/applications.sh vscode chrome
EOF
}

if [[ "$ARCH" != "amd64" ]]; then
    log_error "This script supports Ubuntu Desktop amd64 only. Current architecture: $ARCH"
    exit 1
fi

if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    log_error "Supported Ubuntu versions are 22.04 and 24.04. Current version: $UBUNTU_VERSION"
    exit 1
fi

prompt_application() {
    local name="$1"
    local answer

    if [[ ! -t 0 ]]; then
        log_warn "Non-interactive environment detected. Skipping ${name}."
        return 1
    fi

    log_ask "Install ${UI_BOLD}${name}${UI_RESET}? [y/N] "
    read -r answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

select_applications_with_whiptail() {
    local selection
    local -a selected_apps

    selection=$(
        whiptail \
            --title "Applications" \
            --checklist "Select the applications to install (Press <Space> to toggle, <Enter> to confirm)" \
            15 70 5 \
            "vscode" "Visual Studio Code" OFF \
            "chrome" "Google Chrome" OFF \
            3>&1 1>&2 2>&3
    )
    local ret=$?
    if [[ $ret -ne 0 ]]; then
        log_warn "Selection cancelled."
        return 1
    fi

    selection="${selection//\"/}"
    read -r -a selected_apps <<< "$selection"

    if [[ ${#selected_apps[@]} -eq 0 ]]; then
        log_info "No applications selected. Skipping."
        return 0
    fi

    for app in "${selected_apps[@]}"; do
        case "$app" in
            vscode)
                INSTALL_VSCODE=1
                ;;
            chrome)
                INSTALL_CHROME=1
                ;;
        esac
    done
}

install_prerequisites() {
    log_section "Installing application prerequisites"
    apt_with_proxy update
    apt_with_proxy install -y curl wget apt-transport-https gnupg ca-certificates
}

install_vscode() {
    log_section "Installing VS Code"

    sudo install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
    sudo chmod 0644 /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    apt_with_proxy update
    apt_with_proxy install -y code
}

install_chrome() {
    log_section "Installing Google Chrome"

    CHROME_DEB="$TMP_DIR/google-chrome-stable_current_amd64.deb"
    wget -O "$CHROME_DEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    apt_with_proxy install -y "$CHROME_DEB"
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

configure_whiptail_colors

if [[ $# -eq 0 ]]; then
    if command -v whiptail >/dev/null 2>&1; then
        select_applications_with_whiptail || exit 0
    else
        prompt_application "VS Code" && INSTALL_VSCODE=1
        prompt_application "Google Chrome" && INSTALL_CHROME=1
    fi
else
    for app in "$@"; do
        case "$app" in
            all)
                INSTALL_VSCODE=1
                INSTALL_CHROME=1
                ;;
            vscode)
                INSTALL_VSCODE=1
                ;;
            chrome)
                INSTALL_CHROME=1
                ;;
            *)
                log_error "Unknown application: $app"
                usage
                exit 1
                ;;
        esac
    done
fi

# ⚡ Bolt optimization: Add early returns by checking if apps are installed to skip unnecessary processing
if [[ "$INSTALL_VSCODE" -eq 1 ]] && command -v code >/dev/null 2>&1; then
    log_info "VS Code is already installed."
    INSTALL_VSCODE=0
fi

if [[ "$INSTALL_CHROME" -eq 1 ]] && { command -v google-chrome-stable >/dev/null 2>&1 || command -v google-chrome >/dev/null 2>&1; }; then
    log_info "Google Chrome is already installed."
    INSTALL_CHROME=0
fi

if [[ "$INSTALL_VSCODE" -eq 0 && "$INSTALL_CHROME" -eq 0 ]]; then
    log_warn "No applications selected. Skipping."
    exit 0
fi

install_prerequisites

if [[ "$INSTALL_VSCODE" -eq 1 ]]; then
    install_vscode
fi

if [[ "$INSTALL_CHROME" -eq 1 ]]; then
    install_chrome
fi
