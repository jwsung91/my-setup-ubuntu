#!/bin/bash
set -euo pipefail

install_zsh() {
    echo "--- Installing Zsh and setting it as the default shell ---"
    sudo apt install -y zsh

    local zsh_path
    local current_shell
    zsh_path="$(command -v zsh)"
    current_shell="$(getent passwd "$USER" | cut -d: -f7)"

    if [[ "$current_shell" != "$zsh_path" ]]; then
        chsh -s "$zsh_path"
        echo "Default shell changed to zsh. It will apply on the next login."
    else
        echo "Default shell is already set to zsh."
    fi
}

install_oh_my_zsh() {
    echo "--- Installing Oh My Zsh ---"
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        echo "Oh My Zsh is already installed."
    fi
}

install_plugins() {
    echo "--- Installing Zsh plugins ---"
    local zsh_custom
    zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ ! -d "${zsh_custom}/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "${zsh_custom}/plugins/zsh-autosuggestions"
    else
        echo "zsh-autosuggestions is already installed."
    fi

    if [[ ! -d "${zsh_custom}/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${zsh_custom}/plugins/zsh-syntax-highlighting"
    else
        echo "zsh-syntax-highlighting is already installed."
    fi
}

install_theme() {
    echo "--- Installing Zsh theme ---"
    local zsh_custom
    zsh_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [[ ! -d "${zsh_custom}/themes/powerlevel10k" ]]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${zsh_custom}/themes/powerlevel10k"
    else
        echo "powerlevel10k is already installed."
    fi
}

install_zsh
install_oh_my_zsh
install_plugins
install_theme
