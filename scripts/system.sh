#!/bin/bash
set -euo pipefail

ARCH="$(dpkg --print-architecture)"
UBUNTU_VERSION="$(lsb_release -rs)"

if [[ "$ARCH" != "amd64" ]]; then
    echo "This script supports Ubuntu Desktop amd64 only. Current architecture: $ARCH"
    exit 1
fi

if [[ "$UBUNTU_VERSION" != "22.04" && "$UBUNTU_VERSION" != "24.04" ]]; then
    echo "Supported Ubuntu versions are 22.04 and 24.04. Current version: $UBUNTU_VERSION"
    exit 1
fi

echo "--- Updating the system and installing required packages ---"
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget git build-essential apt-transport-https gnupg ca-certificates lsb-release
