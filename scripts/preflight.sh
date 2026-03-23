#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROXY_DIR="$PROJECT_ROOT/proxy"
ACTIVE_PROXY_FILE="$PROJECT_ROOT/.proxy.env"
ARCH="$(dpkg --print-architecture)"
UBUNTU_VERSION="$(lsb_release -rs)"

REQUIRED_OK=0
REQUIRED_WARN=0
OPTIONAL_OK=0
OPTIONAL_WARN=0
WARN_HOME_WRITABLE=0
WARN_SUDO_AUTH=0
WARN_ACTIVE_PROXY=0
WARN_PROXY_PROFILES=0
WARN_SINGLE_PROXY_PROFILE=0
WARN_SUPPORTED_ARCH=0
WARN_SUPPORTED_UBUNTU=0
WARN_SCRIPTS_DIR=0
WARN_DOTFILES_DIR=0

check_required_command() {
    local label="$1"
    local command_name="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        log_status "OK" "required" "$label"
        REQUIRED_OK=$((REQUIRED_OK + 1))
    else
        log_status "WARN" "required" "$label"
        REQUIRED_WARN=$((REQUIRED_WARN + 1))
    fi
}

check_required_test() {
    local label="$1"
    shift

    if "$@"; then
        log_status "OK" "required" "$label"
        REQUIRED_OK=$((REQUIRED_OK + 1))
    else
        log_status "WARN" "required" "$label"
        REQUIRED_WARN=$((REQUIRED_WARN + 1))
    fi
}

check_optional_test() {
    local label="$1"
    shift

    if "$@"; then
        log_status "OK" "optional" "$label"
        OPTIONAL_OK=$((OPTIONAL_OK + 1))
    else
        log_status "WARN" "optional" "$label"
        OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
    fi
}

check_shell() {
    local label="$1"
    local command_string="$2"
    local level="$3"

    if bash -lc "$command_string" >/dev/null 2>&1; then
        log_status "OK" "$level" "$label"
        if [[ "$level" == "required" ]]; then
            REQUIRED_OK=$((REQUIRED_OK + 1))
        else
            OPTIONAL_OK=$((OPTIONAL_OK + 1))
        fi
    else
        log_status "WARN" "$level" "$label"
        if [[ "$level" == "required" ]]; then
            REQUIRED_WARN=$((REQUIRED_WARN + 1))
        else
            OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
        fi
    fi
}

has_supported_arch() {
    [[ "$ARCH" == "amd64" ]]
}

has_supported_ubuntu() {
    [[ "$UBUNTU_VERSION" == "22.04" || "$UBUNTU_VERSION" == "24.04" ]]
}

can_run_sudo_non_interactive() {
    sudo -n true >/dev/null 2>&1
}

has_proxy_profiles() {
    find "$PROXY_DIR" -maxdepth 1 -type f -name '*.env' | grep -q .
}

has_single_proxy_profile() {
    local count
    count="$(find "$PROXY_DIR" -maxdepth 1 -type f -name '*.env' | wc -l)"
    [[ "$count" -eq 1 ]]
}

has_active_proxy_file() {
    [[ -e "$ACTIVE_PROXY_FILE" || -L "$ACTIVE_PROXY_FILE" ]]
}

print_recommendations() {
    local printed=0

    log_section "Recommended next actions"

    if [[ "$WARN_SUPPORTED_ARCH" -eq 1 ]]; then
        log_warn "Use an amd64 Ubuntu machine. The current setup does not support this architecture."
        printed=1
    fi

    if [[ "$WARN_SUPPORTED_UBUNTU" -eq 1 ]]; then
        log_warn "Use Ubuntu Desktop 22.04 or 24.04 before running the full setup."
        printed=1
    fi

    if [[ "$WARN_SCRIPTS_DIR" -eq 1 || "$WARN_DOTFILES_DIR" -eq 1 ]]; then
        log_warn "Run the setup from the repository root and make sure the checkout is complete."
        printed=1
    fi

    if [[ "$WARN_SUDO_AUTH" -eq 1 ]]; then
        log_warn "Run \`sudo -v\` once before \`./setup.sh full\` to avoid repeated password prompts."
        printed=1
    fi

    if [[ "$WARN_PROXY_PROFILES" -eq 1 ]]; then
        log_warn "If your network needs a proxy, create a profile under \`proxy/*.env\` from \`.proxy.env.example\`."
        printed=1
    fi

    if [[ "$WARN_ACTIVE_PROXY" -eq 1 && "$WARN_PROXY_PROFILES" -eq 0 ]]; then
        log_warn "Activate a proxy before networked steps with \`./scripts/proxy.sh\` or \`./setup.sh run proxy\`."
        printed=1
    fi

    if [[ "$WARN_SINGLE_PROXY_PROFILE" -eq 1 && "$WARN_PROXY_PROFILES" -eq 0 && "$WARN_ACTIVE_PROXY" -eq 1 ]]; then
        log_warn "If you want \`full\` to auto-pick a proxy, keep exactly one profile or pre-activate one."
        printed=1
    fi

    if [[ "$WARN_HOME_WRITABLE" -eq 1 ]]; then
        log_warn "Ensure your home directory is writable before applying config or restore steps."
        printed=1
    fi

    if [[ "$printed" -eq 0 ]]; then
        log_ok "No blocking issues detected. You can continue with \`./setup.sh full\`."
    fi
}

source "$SCRIPT_DIR/lib/ui.sh"

log_section "Running preflight checks"
check_required_command "sudo available" sudo
check_required_command "git available" git
check_required_command "curl available" curl
check_required_command "wget available" wget
check_required_command "lsb_release available" lsb_release
check_required_command "dpkg available" dpkg
check_required_command "whiptail available or fallback possible" bash
check_required_test "supported architecture (amd64)" has_supported_arch
[[ "$ARCH" == "amd64" ]] || WARN_SUPPORTED_ARCH=1
check_required_test "supported Ubuntu version (22.04 or 24.04)" has_supported_ubuntu
[[ "$UBUNTU_VERSION" == "22.04" || "$UBUNTU_VERSION" == "24.04" ]] || WARN_SUPPORTED_UBUNTU=1
check_required_test "scripts directory present" test -d "$PROJECT_ROOT/scripts"
[[ -d "$PROJECT_ROOT/scripts" ]] || WARN_SCRIPTS_DIR=1
check_required_test "dotfiles directory present" test -d "$PROJECT_ROOT/dotfiles"
[[ -d "$PROJECT_ROOT/dotfiles" ]] || WARN_DOTFILES_DIR=1
check_shell "home directory appears writable" "test -w \"\$HOME\"" "optional"
if ! bash -lc "test -w \"\$HOME\"" >/dev/null 2>&1; then
    WARN_HOME_WRITABLE=1
fi

check_optional_test "sudo is already authenticated" can_run_sudo_non_interactive
can_run_sudo_non_interactive || WARN_SUDO_AUTH=1
check_optional_test "proxy directory present" test -d "$PROXY_DIR"
check_optional_test "active proxy file present" has_active_proxy_file
has_active_proxy_file || WARN_ACTIVE_PROXY=1
check_optional_test "proxy profiles available" has_proxy_profiles
has_proxy_profiles || WARN_PROXY_PROFILES=1
check_optional_test "exactly one proxy profile available" has_single_proxy_profile
has_single_proxy_profile || WARN_SINGLE_PROXY_PROFILE=1
check_optional_test "zsh managed config exists" test -f "$PROJECT_ROOT/dotfiles/zsh/.zshrc"
check_optional_test "git managed config exists" test -f "$PROJECT_ROOT/dotfiles/git/.gitconfig"
check_optional_test "vim managed config exists" test -f "$PROJECT_ROOT/dotfiles/vim/.vimrc"

log_section "Preflight summary"
log_info "Required passed: $REQUIRED_OK"
log_info "Required warnings: $REQUIRED_WARN"
log_info "Optional passed: $OPTIONAL_OK"
log_info "Optional warnings: $OPTIONAL_WARN"
print_recommendations

if [[ "$REQUIRED_WARN" -gt 0 ]]; then
    exit 1
fi
