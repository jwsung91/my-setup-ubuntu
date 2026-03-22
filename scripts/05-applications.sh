#!/bin/bash
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
UBUNTU_VERSION="$(lsb_release -rs)"
TMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TMP_DIR"
}

trap cleanup EXIT

if [[ "$ARCH" != "amd64" ]]; then
    echo "This script supports Ubuntu Desktop amd64 only. Current architecture: $ARCH"
    exit 1
fi

if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    echo "Supported Ubuntu versions are 22.04 and 24.04. Current version: $UBUNTU_VERSION"
    exit 1
fi

echo "--- Installing application prerequisites ---"
sudo apt update
sudo apt install -y curl wget apt-transport-https gnupg ca-certificates

echo "--- Installing VS Code ---"
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
sudo chmod 0644 /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
sudo apt update
sudo apt install -y code

echo "--- Installing Google Chrome ---"
CHROME_DEB="$TMP_DIR/google-chrome-stable_current_amd64.deb"
wget -O "$CHROME_DEB" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y "$CHROME_DEB"
