#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROXY_DIR="$PROJECT_ROOT/proxy"
ACTIVE_PROXY_FILE="$PROJECT_ROOT/.proxy.env"

source "$SCRIPT_DIR/lib/ui.sh"

usage() {
    cat <<'EOF'
Usage:
  ./scripts/proxy.sh            Choose and activate a proxy profile
  ./scripts/proxy.sh auto       Use the current proxy file or auto-select one profile
  ./scripts/proxy.sh list       Show available proxy profiles
  ./scripts/proxy.sh use NAME   Activate proxy/NAME.env
  ./scripts/proxy.sh clear      Remove the active .proxy.env file
EOF
}

ensure_proxy_dir() {
    mkdir -p "$PROXY_DIR"
}

list_proxy_profiles() {
    find "$PROXY_DIR" -maxdepth 1 -type f -name '*.env' -printf '%f\n' 2>/dev/null | sort
}

print_profiles() {
    local found=0

    while IFS= read -r profile; do
        found=1
        printf '%s\n' "${profile%.env}"
    done < <(list_proxy_profiles)

    if [[ "$found" -eq 0 ]]; then
        log_warn "No proxy profiles found in $PROXY_DIR"
        log_info "Create one from .proxy.env.example and place it under proxy/."
        return 1
    fi
}

activate_profile() {
    local profile_name="$1"
    local profile_path="$PROXY_DIR/${profile_name}.env"

    if [[ ! -f "$profile_path" ]]; then
        log_error "Proxy profile not found: $profile_name"
        exit 1
    fi

    rm -f "$ACTIVE_PROXY_FILE"
    ln -s "$profile_path" "$ACTIVE_PROXY_FILE"
    log_ok "Activated proxy profile: $profile_name"
    log_info "Active file: $ACTIVE_PROXY_FILE -> $profile_path"
}

clear_active_proxy() {
    if [[ -e "$ACTIVE_PROXY_FILE" || -L "$ACTIVE_PROXY_FILE" ]]; then
        rm -f "$ACTIVE_PROXY_FILE"
        log_ok "Cleared active proxy file: $ACTIVE_PROXY_FILE"
    else
        log_warn "No active proxy file to clear."
    fi
}

auto_select_proxy() {
    local -a profiles=()
    mapfile -t profiles < <(list_proxy_profiles)

    if [[ -e "$ACTIVE_PROXY_FILE" || -L "$ACTIVE_PROXY_FILE" ]]; then
        log_info "Using existing proxy file: $ACTIVE_PROXY_FILE"
        return 0
    fi

    if [[ ${#profiles[@]} -eq 1 ]]; then
        activate_profile "${profiles[0]%.env}"
        return 0
    fi

    log_warn "Proxy auto-selection skipped."
    log_info "Reason: ${#profiles[@]} profile(s) found in $PROXY_DIR and no active .proxy.env file."
}

select_profile_with_whiptail() {
    local selection
    local -a profiles=()
    local -a menu_items=()

    mapfile -t profiles < <(list_proxy_profiles)

    if [[ ${#profiles[@]} -eq 0 ]]; then
        log_warn "No proxy profiles found in $PROXY_DIR"
        log_info "Create one from .proxy.env.example and place it under proxy/."
        return 1
    fi

    for profile in "${profiles[@]}"; do
        menu_items+=("${profile%.env}" "$PROXY_DIR/$profile")
    done

    selection=$(
        whiptail \
            --title "Proxy" \
            --menu "Select the proxy profile to activate (Press <Enter> to confirm)" \
            20 90 10 \
            "${menu_items[@]}" \
            3>&1 1>&2 2>&3
    )
    local ret=$?
    if [[ $ret -ne 0 ]]; then
        log_warn "Selection cancelled."
        return 1
    fi

    activate_profile "$selection"
}

prompt_for_proxy_profile() {
    local profile_name

    if ! print_profiles; then
        return 1
    fi
    printf 'Enter proxy profile name to activate: '
    read -r profile_name

    if [[ -z "$profile_name" ]]; then
        log_warn "No proxy profile selected. Skipping."
        return 1
    fi

    activate_profile "$profile_name"
}

ensure_proxy_dir
configure_whiptail_colors

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

case "${1:-interactive}" in
    interactive)
        if command -v whiptail >/dev/null 2>&1; then
            select_profile_with_whiptail || exit 0
        else
            prompt_for_proxy_profile || exit 0
        fi
        ;;
    auto)
        auto_select_proxy
        ;;
    list)
        print_profiles
        ;;
    use)
        if [[ $# -lt 2 ]]; then
            log_error "Missing proxy profile name."
            usage
            exit 1
        fi
        activate_profile "$2"
        ;;
    clear)
        clear_active_proxy
        ;;
    *)
        log_error "Unknown proxy command: $1"
        usage
        exit 1
        ;;
esac
