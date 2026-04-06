#!/bin/bash
set -euo pipefail

# --- Configuration & Setup ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
load_proxy_settings

# Track which tools to install
declare -A RUN_TOOLS
ALL_TOOLS=(
    "ripgrep" "fd" "fzf" "zoxide" "yazi"        # Search & Navigation
    "bat" "eza" "dust" "jq" "tldr"              # Modern CLI Enhancements
    "lazygit" "lazydocker" "btop"               # Development TUIs
    "tmux" "xclip"                              # System Utilities
)

for tool in "${ALL_TOOLS[@]}"; do RUN_TOOLS[$tool]=0; done

usage() {
    cat <<EOF
Usage:
  $(basename "$0")                    Choose tools interactively
  $(basename "$0") all                Install all available tools
  $(basename "$0") [tool1] [tool2]...  Install specific tools (e.g., ripgrep fd)

Available tools: ${ALL_TOOLS[*]}
EOF
}

# --- Individual Installation Functions ---

APT_UPDATED=0

install_apt_packages() {
    local -a packages=("$@")
    if [[ ${#packages[@]} -gt 0 ]]; then
        log_section "Installing apt packages: ${packages[*]}"
        # ⚡ Bolt optimization: Run apt update only once
        if [[ "$APT_UPDATED" -eq 0 ]]; then
            apt_with_proxy update
            APT_UPDATED=1
        fi
        apt_with_proxy install -y "${packages[@]}"
    fi
}

install_ripgrep() {
    if ! command -v rg >/dev/null 2>&1; then
        install_apt_packages "ripgrep"
    fi
}

install_fd() {
    if ! command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
        install_apt_packages "fd-find"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        log_ok "Created ~/.local/bin/fd -> fdfind"
    fi
}

install_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then
        install_apt_packages "fzf"
    fi
}

install_bat() {
    if ! command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
        install_apt_packages "bat"
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        log_ok "Created ~/.local/bin/bat -> batcat"
    fi
}

install_jq() {
    if ! command -v jq >/dev/null 2>&1; then
        install_apt_packages "jq"
    fi
}

install_tldr() {
    if ! command -v tldr >/dev/null 2>&1; then
        install_apt_packages "tldr"
    fi
}

install_btop() {
    if ! command -v btop >/dev/null 2>&1; then
        install_apt_packages "btop"
    fi
}

install_tmux() {
    if ! command -v tmux >/dev/null 2>&1; then
        install_apt_packages "tmux"
    fi
}

install_xclip() {
    if ! command -v xclip >/dev/null 2>&1; then
        install_apt_packages "xclip"
    fi
}

install_zoxide() {
    if ! command -v zoxide >/dev/null 2>&1; then
        log_section "Installing zoxide"
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
        log_ok "zoxide installed"
    fi
}

install_lazygit() {
    if ! command -v lazygit >/dev/null 2>&1; then
        log_section "Installing lazygit"
        local version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${version}_Linux_x86_64.tar.gz"
        tar xf lazygit.tar.gz lazygit
        install lazygit "$HOME/.local/bin"
        rm lazygit lazygit.tar.gz
        log_ok "lazygit v$version installed to ~/.local/bin"
    fi
}

install_lazydocker() {
    if ! command -v lazydocker >/dev/null 2>&1; then
        log_section "Installing lazydocker"
        local version=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${version}_Linux_x86_64.tar.gz"
        tar xf lazydocker.tar.gz lazydocker
        install lazydocker "$HOME/.local/bin"
        rm lazydocker lazydocker.tar.gz
        log_ok "lazydocker v$version installed to ~/.local/bin"
    fi
}

install_eza() {
    if ! command -v eza >/dev/null 2>&1; then
        log_section "Installing eza"
        sudo apt-get update && sudo apt-get install -y gpg wget
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update
        sudo apt-get install -y eza
        log_ok "eza installed"
    fi
}

install_dust() {
    if ! command -v dust >/dev/null 2>&1; then
        log_section "Installing dust"
        local version=$(curl -s "https://api.github.com/repos/bootandy/dust/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo dust.tar.gz "https://github.com/bootandy/dust/releases/latest/download/dust-v${version}-x86_64-unknown-linux-gnu.tar.gz"
        tar xf dust.tar.gz --strip-components=1
        install dust "$HOME/.local/bin"
        rm dust dust.tar.gz
        log_ok "dust v$version installed to ~/.local/bin"
    fi
}

install_yazi() {
    if ! command -v yazi >/dev/null 2>&1; then
        log_section "Installing yazi"
        local version=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo yazi.zip "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip"
        unzip -q yazi.zip
        cd yazi-x86_64-unknown-linux-musl
        install yazi ya "$HOME/.local/bin"
        cd ..
        rm -rf yazi.zip yazi-x86_64-unknown-linux-musl
        log_ok "yazi v$version installed to ~/.local/bin"
    fi
}

# --- Main Logic ---

select_tools_interactive() {
    local selection
    
    # 1. Clear input buffer and reset terminal
    if [[ -t 0 ]]; then
        stty sane
        # Flush any pending input
        read -t 0.1 -n 10000 || true
    fi

    # 2. Use 0 0 0 for auto-sizing whiptail
    selection=$(whiptail --title "Developer Tools" --checklist \
        "Select CLI tools to install (Press <Space> to toggle, <Enter> to confirm)" 0 0 0 \
        "ripgrep" "[Search] Fast recursive text search (rg)" ON \
        "fd" "[Search] Fast file finder (fd-find)" ON \
        "fzf" "[Search] Fuzzy finder for shell" ON \
        "zoxide" "[Search] Smarter cd command" ON \
        "yazi" "[Search] Terminal file manager" ON \
        "bat" "[Modern] Cat with syntax highlighting" ON \
        "eza" "[Modern] Modern ls replacement" ON \
        "dust" "[Modern] Intuitive disk usage (du)" ON \
        "jq" "[Modern] JSON processor" ON \
        "tldr" "[Modern] Simplified man pages" ON \
        "lazygit" "[TUI] Simple TUI for git" ON \
        "lazydocker" "[TUI] Simple TUI for docker" ON \
        "btop" "[TUI] Modern resource monitor" ON \
        "tmux" "[Util] Terminal multiplexer" OFF \
        "xclip" "[Util] Clipboard utility for X11" OFF \
        3>&1 1>&2 2>&3)

    local exit_status=$?
    if [[ $exit_status -ne 0 ]]; then
        if [[ $exit_status -eq 1 ]]; then
            log_info "Selection cancelled by user."
            return 1
        else
            log_warn "whiptail failed with status $exit_status. Falling back to default."
            # Fallback: Install recommended tools
            for tool in "${ALL_TOOLS[@]}"; do
                [[ "$tool" != "tmux" && "$tool" != "xclip" ]] && RUN_TOOLS[$tool]=1
            done
            return 0
        fi
    fi

    # 3. Process results
    if [[ -n "$selection" ]]; then
        eval "local selected_items=($selection)"
        for tool in "${selected_items[@]}"; do
            tool=$(echo "$tool" | xargs)
            if [[ -n "${tool}" && "${RUN_TOOLS[$tool]:-}" != "" ]]; then
                RUN_TOOLS[$tool]=1
            fi
        done
    else
        log_info "No tools selected."
    fi
    return 0
}

if [[ $# -eq 0 ]]; then
    configure_whiptail_colors
    select_tools_interactive || exit 0
elif [[ "$1" == "all" ]]; then
    for tool in "${ALL_TOOLS[@]}"; do RUN_TOOLS[$tool]=1; done
else
    for arg in "$@"; do
        if [[ -n "${RUN_TOOLS[$arg]:-}" ]]; then
            RUN_TOOLS[$arg]=1
        else
            log_error "Unknown tool: $arg"
            usage; exit 1
        fi
    done
fi

# Execute installations
mkdir -p "$HOME/.local/bin"

for tool in "${ALL_TOOLS[@]}"; do
    if [[ "${RUN_TOOLS[$tool]}" -eq 1 ]]; then
        "install_$tool"
    fi
done

log_section "Installation complete!"
log_info "Make sure ~/.local/bin is in your PATH."
log_info "Run 'source ~/.zshrc' to apply new aliases."
