#!/bin/bash
set -euo pipefail

RUN_RIPGREP=0
RUN_FD=0
RUN_FZF=0
RUN_BAT=0
RUN_JQ=0
RUN_TMUX=0
RUN_XCLIP=0
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
            20 76 10 \
            "ripgrep" "Fast recursive search" ON \
            "fd" "Fast file finder" ON \
            "fzf" "Fuzzy finder" ON \
            "bat" "Cat with syntax highlighting" ON \
            "jq" "JSON processor" ON \
            "tmux" "Terminal multiplexer" OFF \
            "xclip" "Clipboard utility for X11" OFF \
            3>&1 1>&2 2>&3
    ) || return 1

    selection="${selection//\"/}"
    read -r -a selected_items <<< "$selection"

    if [[ ${#selected_items[@]} -eq 0 ]]; then
        log_warn "No tools selected. Skipping."
        return 1
    fi

    for item in "${selected_items[@]}"; do
        case "$item" in
            ripgrep) RUN_RIPGREP=1 ;;
            fd) RUN_FD=1 ;;
            fzf) RUN_FZF=1 ;;
            bat) RUN_BAT=1 ;;
            jq) RUN_JQ=1 ;;
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
                RUN_TMUX=1
                RUN_XCLIP=1
                ;;
            ripgrep)
                RUN_RIPGREP=1
                ;;
            fd)
                RUN_FD=1
                ;;
            fzf)
                RUN_FZF=1
                ;;
            bat)
                RUN_BAT=1
                ;;
            jq)
                RUN_JQ=1
                ;;
            tmux)
                RUN_TMUX=1
                ;;
            xclip)
                RUN_XCLIP=1
                ;;
            *)
                log_error "Unknown tool target: $item"
                usage
                exit 1
                ;;
        esac
    done
fi

if [[ "$RUN_RIPGREP" -eq 0 && "$RUN_FD" -eq 0 && "$RUN_FZF" -eq 0 && "$RUN_BAT" -eq 0 && "$RUN_JQ" -eq 0 && "$RUN_TMUX" -eq 0 && "$RUN_XCLIP" -eq 0 ]]; then
    log_warn "No tools selected. Skipping."
    exit 0
fi

PACKAGES=()

[[ "$RUN_RIPGREP" -eq 1 ]] && PACKAGES+=("ripgrep")
[[ "$RUN_FD" -eq 1 ]] && PACKAGES+=("fd-find")
[[ "$RUN_FZF" -eq 1 ]] && PACKAGES+=("fzf")
[[ "$RUN_BAT" -eq 1 ]] && PACKAGES+=("bat")
[[ "$RUN_JQ" -eq 1 ]] && PACKAGES+=("jq")
[[ "$RUN_TMUX" -eq 1 ]] && PACKAGES+=("tmux")
[[ "$RUN_XCLIP" -eq 1 ]] && PACKAGES+=("xclip")

log_section "Installing developer CLI tools"
apt_with_proxy update
apt_with_proxy install -y "${PACKAGES[@]}"

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
