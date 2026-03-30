#!/bin/bash
set -euo pipefail

RUN_ZSH=0
RUN_GIT=0
RUN_VIM=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/ui.sh"

ZSH_USER_TARGET="$HOME/.zshrc"
ZSH_MANAGED_TARGET="$HOME/.zshrc.my-setup-ubuntu"

GIT_USER_TARGET="$HOME/.gitconfig"
GIT_MANAGED_TARGET="$HOME/.gitconfig.my-setup-ubuntu"

VIM_USER_TARGET="$HOME/.vimrc"
VIM_MANAGED_TARGET="$HOME/.vimrc.my-setup-ubuntu"

usage() {
    cat <<'EOF'
Usage:
  ./scripts/restore.sh              Choose restore targets interactively
  ./scripts/restore.sh all          Restore zsh, git, and vim backups
  ./scripts/restore.sh zsh git      Restore only zsh and git backups
  ./scripts/restore.sh vim          Restore only vim backups
EOF
}

select_restore_with_whiptail() {
    local selection
    local -a selected_items

    selection=$(
        whiptail \
            --title "Restore" \
            --checklist "Select the config targets to restore (Press <Space> to toggle, <Enter> to confirm)" \
            16 72 6 \
            "zsh" "Restore ~/.zshrc backups" OFF \
            "git" "Restore ~/.gitconfig backups" OFF \
            "vim" "Restore ~/.vimrc backups" OFF \
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
        log_info "No restore targets selected. Skipping."
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

latest_backup_for() {
    local target="$1"
    ls -1t "${target}.bak."* 2>/dev/null | head -n 1
}

select_backup_for_target() {
    local target="$1"
    local title="$2"
    local selection
    local -a backups
    local -a menu_items

    mapfile -t backups < <(ls -1t "${target}.bak."* 2>/dev/null)
    if [[ ${#backups[@]} -eq 0 ]]; then
        printf '\n'
        return 0
    fi

    for backup in "${backups[@]}"; do
        menu_items+=("$backup" "")
    done

    if command -v whiptail >/dev/null 2>&1; then
        selection=$(
            whiptail \
                --title "$title" \
                --menu "Select the backup to restore (Press <Enter> to confirm)" \
                20 90 10 \
                "${menu_items[@]}" \
                3>&1 1>&2 2>&3
        )
        local ret=$?
        if [[ $ret -ne 0 ]]; then
            log_warn "Selection cancelled."
            return 1
        fi
        printf '%s\n' "$selection"
        return 0
    fi

    printf '%s\n' "${backups[0]}"
}

restore_latest_backup() {
    local target="$1"
    local title="$2"
    local backup_path

    if ! backup_path="$(select_backup_for_target "$target" "$title")"; then
        log_warn "Restore cancelled for $target"
        return
    fi

    if [[ -z "${backup_path:-}" ]]; then
        backup_path="$(latest_backup_for "$target")"
    fi

    if [[ -z "${backup_path:-}" ]]; then
        log_warn "No backup found for $target"
        return
    fi

    cp "$backup_path" "$target"
    log_ok "Restored $target from $backup_path"
}

restore_zsh() {
    log_section "Restoring zsh backups"
    restore_latest_backup "$ZSH_USER_TARGET" "Restore ~/.zshrc"
    restore_latest_backup "$ZSH_MANAGED_TARGET" "Restore ~/.zshrc.my-setup-ubuntu"
}

restore_git() {
    log_section "Restoring git backups"
    restore_latest_backup "$GIT_USER_TARGET" "Restore ~/.gitconfig"
    restore_latest_backup "$GIT_MANAGED_TARGET" "Restore ~/.gitconfig.my-setup-ubuntu"
}

restore_vim() {
    log_section "Restoring vim backups"
    restore_latest_backup "$VIM_USER_TARGET" "Restore ~/.vimrc"
    restore_latest_backup "$VIM_MANAGED_TARGET" "Restore ~/.vimrc.my-setup-ubuntu"
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

configure_whiptail_colors

if [[ $# -eq 0 ]]; then
    if command -v whiptail >/dev/null 2>&1; then
        select_restore_with_whiptail || exit 0
    else
        log_warn "No restore targets selected. Skipping."
        exit 0
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
                log_error "Unknown restore target: $item"
                usage
                exit 1
                ;;
        esac
    done
fi

if [[ "$RUN_ZSH" -eq 0 && "$RUN_GIT" -eq 0 && "$RUN_VIM" -eq 0 ]]; then
    log_warn "No restore targets selected. Skipping."
    exit 0
fi

if [[ "$RUN_ZSH" -eq 1 ]]; then
    restore_zsh
fi

if [[ "$RUN_GIT" -eq 1 ]]; then
    restore_git
fi

if [[ "$RUN_VIM" -eq 1 ]]; then
    restore_vim
fi
