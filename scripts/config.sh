#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/../dotfiles"
BACKUP_PATH=""
RUN_ZSH=0
RUN_GIT=0
RUN_VIM=0

source "$SCRIPT_DIR/lib/ui.sh"

log_section "Applying managed dotfile content"

ZSH_SOURCE="$DOTFILES_DIR/zsh/.zshrc"
ZSH_MANAGED_TARGET="$HOME/.zshrc.my-setup-ubuntu"
ZSH_USER_TARGET="$HOME/.zshrc"
ZSH_MARKER_START="# >>> my-setup-ubuntu zshrc >>>"
ZSH_MARKER_END="# <<< my-setup-ubuntu zshrc <<<"

GIT_SOURCE="$DOTFILES_DIR/git/.gitconfig"
GIT_MANAGED_TARGET="$HOME/.gitconfig.my-setup-ubuntu"
GIT_USER_TARGET="$HOME/.gitconfig"
GIT_MARKER_START="# >>> my-setup-ubuntu gitconfig >>>"
GIT_MARKER_END="# <<< my-setup-ubuntu gitconfig <<<"

VIM_SOURCE="$DOTFILES_DIR/vim/.vimrc"
VIM_MANAGED_TARGET="$HOME/.vimrc.my-setup-ubuntu"
VIM_USER_TARGET="$HOME/.vimrc"
VIM_MARKER_START="\" >>> my-setup-ubuntu vimrc >>>"
VIM_MARKER_END="\" <<< my-setup-ubuntu vimrc <<<"

if [[ ! -d "$DOTFILES_DIR" ]]; then
    log_error "dotfiles directory not found: $DOTFILES_DIR"
    exit 1
fi

usage() {
    cat <<'EOF'
Usage:
  ./scripts/config.sh              Choose config targets interactively
  ./scripts/config.sh all          Apply zsh, git, and vim config
  ./scripts/config.sh zsh git      Apply only zsh and git config
  ./scripts/config.sh vim          Apply only vim config
EOF
}

select_config_with_whiptail() {
    local selection
    local -a selected_items

    selection=$(
        whiptail \
            --title "Config" \
            --checklist "Select the config targets to apply (Press <Space> to toggle, <Enter> to confirm)" \
            16 72 6 \
            "zsh" "Managed zsh config" ON \
            "git" "Managed git config" ON \
            "vim" "Managed vim config" ON \
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
        log_info "No config targets selected. Skipping."
        return 0
    fi

    for item in "${selected_items[@]}"; do
        case "$item" in
            zsh) RUN_ZSH=1 ;;
            git) RUN_GIT=1 ;;
            vim) RUN_VIM=1 ;;
        esac
    done
}

backup_file() {
    local file_path="$1"
    local backup_path

    backup_path="${file_path}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$file_path" "$backup_path"
    BACKUP_PATH="$backup_path"
    log_info "Backed up ${file_path} to ${backup_path}"
}

install_managed_file() {
    local source_path="$1"
    local target_path="$2"

    if [[ ! -f "$source_path" ]]; then
        log_error "Managed file source not found: $source_path"
        exit 1
    fi

    if [[ -e "$target_path" && ! -L "$target_path" ]] && cmp -s "$source_path" "$target_path"; then
        log_info "Managed file already up to date: $target_path"
        return
    fi

    if [[ -e "$target_path" || -L "$target_path" ]]; then
        backup_file "$target_path"
    fi

    install -m 0644 "$source_path" "$target_path"
    log_ok "Installed managed file: $target_path"
}

ensure_block_in_file() {
    local user_target="$1"
    local marker_start="$2"
    local marker_end="$3"
    local duplicate_probe="$4"
    local managed_line_1="$5"
    local managed_line_2="$6"
    local block
    local backup_path

    block="$(cat <<EOF
$marker_start
$managed_line_1
$managed_line_2
$marker_end
EOF
)"

    if [[ -L "$user_target" ]]; then
        backup_file "$user_target"
    fi

    if [[ -f "$user_target" ]]; then
        if grep -Fq "$marker_start" "$user_target"; then
            log_info "Managed block already exists in $user_target"
            return
        fi

        if grep -Fq "$duplicate_probe" "$user_target"; then
            log_info "Managed include/source line already exists in $user_target"
            return
        fi

        backup_file "$user_target"
        backup_path="$BACKUP_PATH"
        cp "$backup_path" "$user_target"
        printf "\n%s\n" "$block" >> "$user_target"
        log_ok "Appended managed block to $user_target"
        return
    fi

    printf "%s\n" "$block" > "$user_target"
    log_ok "Created $user_target with managed block"
}

apply_zsh_config() {
    install_managed_file "$ZSH_SOURCE" "$ZSH_MANAGED_TARGET"
    ensure_block_in_file \
        "$ZSH_USER_TARGET" \
        "$ZSH_MARKER_START" \
        "$ZSH_MARKER_END" \
        "source \"$ZSH_MANAGED_TARGET\"" \
        "if [ -f \"$ZSH_MANAGED_TARGET\" ]; then" \
        "    source \"$ZSH_MANAGED_TARGET\""$'\n''fi'
}

apply_git_config() {
    install_managed_file "$GIT_SOURCE" "$GIT_MANAGED_TARGET"
    ensure_block_in_file \
        "$GIT_USER_TARGET" \
        "$GIT_MARKER_START" \
        "$GIT_MARKER_END" \
        "path = $GIT_MANAGED_TARGET" \
        "[include]" \
        "    path = $GIT_MANAGED_TARGET"
}

apply_vim_config() {
    install_managed_file "$VIM_SOURCE" "$VIM_MANAGED_TARGET"
    ensure_block_in_file \
        "$VIM_USER_TARGET" \
        "$VIM_MARKER_START" \
        "$VIM_MARKER_END" \
        "source $VIM_MANAGED_TARGET" \
        "if filereadable(expand('$VIM_MANAGED_TARGET'))" \
        "    source $VIM_MANAGED_TARGET"$'\n''endif'
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

configure_whiptail_colors

if [[ $# -eq 0 ]]; then
    if command -v whiptail >/dev/null 2>&1; then
        select_config_with_whiptail || exit 0
    else
        RUN_ZSH=1
        RUN_GIT=1
        RUN_VIM=1
    fi
else
    for item in "$@"; do
        case "$item" in
            all)
                RUN_ZSH=1
                RUN_GIT=1
                RUN_VIM=1
                ;;
            zsh)
                RUN_ZSH=1
                ;;
            git)
                RUN_GIT=1
                ;;
            vim)
                RUN_VIM=1
                ;;
            *)
                log_error "Unknown config target: $item"
                usage
                exit 1
                ;;
        esac
    done
fi

if [[ "$RUN_ZSH" -eq 0 && "$RUN_GIT" -eq 0 && "$RUN_VIM" -eq 0 ]]; then
    log_warn "No config targets selected. Skipping."
    exit 0
fi

if [[ "$RUN_ZSH" -eq 1 ]]; then
    apply_zsh_config
fi

if [[ "$RUN_GIT" -eq 1 ]]; then
    apply_git_config
fi

if [[ "$RUN_VIM" -eq 1 ]]; then
    apply_vim_config
fi
