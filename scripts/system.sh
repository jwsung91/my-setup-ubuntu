#!/bin/bash
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
UBUNTU_VERSION="$(lsb_release -rs)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
load_proxy_settings

if [[ "$ARCH" != "amd64" ]]; then
    log_error "This script supports Ubuntu Desktop amd64 only. Current architecture: $ARCH"
    exit 1
fi

if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    log_error "Supported Ubuntu versions are 22.04 and 24.04. Current version: $UBUNTU_VERSION"
    exit 1
fi

log_section "Updating the system and installing required packages"
apt_with_proxy update
apt_with_proxy upgrade -y
apt_with_proxy install -y curl wget git build-essential apt-transport-https gnupg ca-certificates lsb-release
