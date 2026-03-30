#!/bin/bash
set -euo pipefail

VIM_BUNDLE_DIR="$HOME/.vim/bundle"
TEMP_DIR="$(mktemp -d)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
load_proxy_settings

cleanup() {
    rm -rf "$TEMP_DIR"
}

trap cleanup EXIT

install_vim() {
    log_section "Installing Vim"
    # ⚡ Bolt optimization: Add early return to skip unnecessary apt processing
    if command -v vim >/dev/null 2>&1; then
        log_info "Vim is already installed."
        return 0
    fi
    apt_with_proxy install -y vim
}

install_plugin() {
    local repo_url="$1"
    local plugin_dir="$2"

    if [[ ! -d "$plugin_dir" ]]; then
        # ⚡ Bolt optimization: Shallow clone to save time/bandwidth
        git clone --depth=1 "$repo_url" "$plugin_dir"
    else
        log_info "Plugin already installed: $plugin_dir"
    fi
}

install_vundle() {
    log_section "Installing Vim plugin manager"
    mkdir -p "$VIM_BUNDLE_DIR"
    install_plugin "https://github.com/VundleVim/Vundle.vim.git" "$VIM_BUNDLE_DIR/Vundle.vim"
}

sync_vim_plugins() {
    local bootstrap_vimrc
    bootstrap_vimrc="$TEMP_DIR/vundle-bootstrap.vim"

    log_section "Syncing Vim plugins with Vundle"
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
