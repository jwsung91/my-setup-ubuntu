#!/bin/bash
set -euo pipefail

VIM_BUNDLE_DIR="$HOME/.vim/bundle"
TEMP_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

install_vim() {
    echo "--- Installing Vim ---"
    sudo apt install -y vim
}

install_plugin() {
    local repo_url="$1"
    local plugin_dir="$2"

    if [[ ! -d "$plugin_dir" ]]; then
        git clone "$repo_url" "$plugin_dir"
    else
        echo "Plugin already installed: $plugin_dir"
    fi
}

install_vundle() {
    echo "--- Installing Vim plugin manager ---"
    mkdir -p "$VIM_BUNDLE_DIR"
    install_plugin "https://github.com/VundleVim/Vundle.vim.git" "$VIM_BUNDLE_DIR/Vundle.vim"
}

sync_vim_plugins() {
    local bootstrap_vimrc
    bootstrap_vimrc="$TEMP_DIR/vundle-bootstrap.vim"

    echo "--- Syncing Vim plugins with Vundle ---"
    cat > "$bootstrap_vimrc" <<'EOF'
set nocompatible
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'VundleVim/Vundle.vim'
Plugin 'tpope/vim-fugitive'
Plugin 'preservim/nerdtree'
Plugin 'preservim/nerdcommenter'
Plugin 'Raimondi/delimitMate'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'joshdick/onedark.vim'
call vundle#end()
EOF

    vim -Nu "$bootstrap_vimrc" -n -es +PluginInstall +qall
}

install_vim
install_vundle
sync_vim_plugins
