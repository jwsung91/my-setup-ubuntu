#!/bin/bash
set -euo pipefail

RUN_RIPGREP=0
RUN_FD=0
RUN_FZF=0
RUN_BAT=0
RUN_JQ=0
RUN_TMUX=0
RUN_XCLIP=0
RUN_ZOXIDE=0
RUN_TLDR=0
RUN_LAZYGIT=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/proxy.sh"
load_proxy_settings

usage() {
    cat <<'EOF'
Usage:
  ./scripts/tools.sh                    Choose tools interactively
  ./scripts/tools.sh all                Install all tools
  ./scripts/tools.sh ripgrep fd jq      Install selected tools
EOF
}

select_tools_with_whiptail() {
    local selection
    local -a selected_items

    selection=$(
        whiptail \
            --title "Developer Tools" \
            --checklist "Select the CLI tools to install (Press <Space> to toggle, <Enter> to confirm)" \
            22 76 12 \
            "ripgrep" "Fast recursive search" ON \
            "fd" "Fast file finder" ON \
            "fzf" "Fuzzy finder" ON \
            "bat" "Cat with syntax highlighting" ON \
            "jq" "JSON processor" ON \
            "zoxide" "Smarter cd command" ON \
            "tldr" "Simplified man pages" ON \
            "lazygit" "TUI for Git" ON \
            "tmux" "Terminal multiplexer" OFF \
            "xclip" "Clipboard utility for X11" OFF \
            3>&1 1>&2 2>&3
    )
    local ret=$?
    if [[ $ret -ne 0 ]]; then
        log_warn "Selection cancelled."
        return 1
    fi

    selection="${selection//\"/}"
    read -r -a selected_items <<< "$selection"

    if [[ ${#selected_items[@]} -eq 0 ]]; then
        log_info "No tools selected. Skipping."
        return 0
    fi

    for item in "${selected_items[@]}"; do
        case "$item" in
            ripgrep) RUN_RIPGREP=1 ;;
            fd) RUN_FD=1 ;;
            fzf) RUN_FZF=1 ;;
            bat) RUN_BAT=1 ;;
            jq) RUN_JQ=1 ;;
            zoxide) RUN_ZOXIDE=1 ;;
            tldr) RUN_TLDR=1 ;;
            lazygit) RUN_LAZYGIT=1 ;;
            tmux) RUN_TMUX=1 ;;
            xclip) RUN_XCLIP=1 ;;
        esac
    done
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

configure_whiptail_colors

if [[ $# -eq 0 ]]; then
    if command -v whiptail >/dev/null 2>&1; then
        select_tools_with_whiptail || exit 0
    else
        RUN_RIPGREP=1
        RUN_FD=1
        RUN_FZF=1
        RUN_BAT=1
        RUN_JQ=1
        RUN_ZOXIDE=1
        RUN_TLDR=1
        RUN_LAZYGIT=1
    fi
else
    for item in "$@"; do
        case "$item" in
            all)
                RUN_RIPGREP=1
                RUN_FD=1
                RUN_FZF=1
                RUN_BAT=1
                RUN_JQ=1
                RUN_ZOXIDE=1
                RUN_TLDR=1
                RUN_LAZYGIT=1
                RUN_TMUX=1
                RUN_XCLIP=1
                ;;
            ripgrep) RUN_RIPGREP=1 ;;
            fd) RUN_FD=1 ;;
            fzf) RUN_FZF=1 ;;
            bat) RUN_BAT=1 ;;
            jq) RUN_JQ=1 ;;
            zoxide) RUN_ZOXIDE=1 ;;
            tldr) RUN_TLDR=1 ;;
            lazygit) RUN_LAZYGIT=1 ;;
            tmux) RUN_TMUX=1 ;;
            xclip) RUN_XCLIP=1 ;;
            *)
                log_error "Unknown tool target: $item"
                usage
                exit 1
                ;;
        esac
    done
fi

if [[ "$RUN_RIPGREP" -eq 0 && "$RUN_FD" -eq 0 && "$RUN_FZF" -eq 0 && "$RUN_BAT" -eq 0 && "$RUN_JQ" -eq 0 && \
      "$RUN_ZOXIDE" -eq 0 && "$RUN_TLDR" -eq 0 && "$RUN_LAZYGIT" -eq 0 && \
      "$RUN_TMUX" -eq 0 && "$RUN_XCLIP" -eq 0 ]]; then
    log_warn "No tools selected. Skipping."
    exit 0
fi

PACKAGES=()

# ⚡ Bolt optimization: Add early returns by checking if tool is installed to skip unnecessary processing
[[ "$RUN_RIPGREP" -eq 1 ]] && ! command -v rg >/dev/null 2>&1 && PACKAGES+=("ripgrep")
[[ "$RUN_FD" -eq 1 ]] && ! command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1 && PACKAGES+=("fd-find")
[[ "$RUN_FZF" -eq 1 ]] && ! command -v fzf >/dev/null 2>&1 && PACKAGES+=("fzf")
[[ "$RUN_BAT" -eq 1 ]] && ! command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1 && PACKAGES+=("bat")
[[ "$RUN_JQ" -eq 1 ]] && ! command -v jq >/dev/null 2>&1 && PACKAGES+=("jq")
[[ "$RUN_TLDR" -eq 1 ]] && ! command -v tldr >/dev/null 2>&1 && PACKAGES+=("tldr")
[[ "$RUN_TMUX" -eq 1 ]] && ! command -v tmux >/dev/null 2>&1 && PACKAGES+=("tmux")
[[ "$RUN_XCLIP" -eq 1 ]] && ! command -v xclip >/dev/null 2>&1 && PACKAGES+=("xclip")

if [[ ${#PACKAGES[@]} -gt 0 ]]; then
    log_section "Installing developer CLI tools (via apt)"
    apt_with_proxy update
    apt_with_proxy install -y "${PACKAGES[@]}"
else
    log_info "Selected apt-based tools are already installed."
fi

# Post-installation for apt packages
if [[ "$RUN_BAT" -eq 1 ]] && command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    log_ok "Created ~/.local/bin/bat -> batcat"
fi

if [[ "$RUN_FD" -eq 1 ]] && command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    log_ok "Created ~/.local/bin/fd -> fdfind"
fi

# Custom installations for zoxide and lazygit
if [[ "$RUN_ZOXIDE" -eq 1 ]] && ! command -v zoxide >/dev/null 2>&1; then
    log_section "Installing zoxide"
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
    log_ok "zoxide installed successfully"
fi

if [[ "$RUN_LAZYGIT" -eq 1 ]] && ! command -v lazygit >/dev/null 2>&1; then
    log_section "Installing lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    install lazygit "$HOME/.local/bin"
    rm lazygit lazygit.tar.gz
    log_ok "lazygit v$LAZYGIT_VERSION installed to ~/.local/bin"
fi

