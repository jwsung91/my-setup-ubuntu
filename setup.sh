#!/bin/bash
set -euo pipefail

# Set the working directory to the absolute path of this script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
RAN_ANY_STEP=0

source "$SCRIPT_DIR/scripts/lib/ui.sh"

usage() {
    cat <<'EOF'
Usage:
  ./setup.sh                Start interactive step selection
  ./setup.sh select         Start interactive step selection
  ./setup.sh full           Run every setup step in order
  ./setup.sh all            Run every setup step in order
  ./setup.sh run proxy system applications shell   Run only selected steps
  ./setup.sh run python:3.12.11 config:all verify  Run steps with step-specific args

Available steps:
  preflight     Check prerequisites before making changes
  proxy         Activate a proxy profile for networked steps
  system        System update and required packages
  applications  VS Code and Chrome
  shell         Zsh, Oh My Zsh, plugins, and theme
  appearance    D2Coding font and colorls
  tools         Developer CLI tools
  python        Python via pyenv and pipx bootstrap
  editor        Vim and plugin bootstrap
  dev-auth      Git, SSH, and GPG bootstrap
  config        Managed dotfile content update
  restore       Restore latest config backups
  verify        Tooling verification
EOF
}

run_step() {
    local step="$1"
    shift || true

    case "$step" in
        proxy)
            ./scripts/proxy.sh "$@"
            ;;
        preflight)
            ./scripts/preflight.sh
            ;;
        system)
            ./scripts/system.sh
            ;;
        applications)
            ./scripts/applications.sh "$@"
            ;;
        shell)
            ./scripts/shell.sh
            ;;
        appearance)
            ./scripts/appearance.sh
            ;;
        tools)
            ./scripts/tools.sh "$@"
            ;;
        python)
            ./scripts/python.sh "$@"
            ;;
        editor)
            ./scripts/editor.sh
            ;;
        dev-auth)
            ./scripts/dev-auth.sh "$@"
            ;;
        config)
            ./scripts/config.sh "$@"
            ;;
        restore)
            ./scripts/restore.sh "$@"
            ;;
        verify)
            ./scripts/verify.sh
            ;;
        *)
            log_error "Unknown step: $step"
            usage
            exit 1
            ;;
    esac
}

step_counts_as_setup() {
    local step="$1"
    shift || true

    case "$step" in
        system|applications|shell|appearance|tools|editor|dev-auth|config|restore)
            return 0
            ;;
        proxy)
            case "${1:-interactive}" in
                list|--help|-h)
                    return 1
                    ;;
                *)
                    return 0
                    ;;
            esac
            ;;
        python)
            case "${1:-}" in
                --help|-h)
                    return 1
                    ;;
                *)
                    return 0
                    ;;
            esac
            ;;
        verify|preflight)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

run_step_spec() {
    local spec="$1"
    local step="${spec%%:*}"
    local args_string=""
    local -a step_args=()

    if [[ "$spec" == *:* ]]; then
        args_string="${spec#*:}"
        IFS=',' read -r -a step_args <<< "$args_string"
    fi

    if step_counts_as_setup "$step" "${step_args[@]}"; then
        RAN_ANY_STEP=1
    fi

    run_step "$step" "${step_args[@]}"
}

prompt_step() {
    local step="$1"
    local description="$2"
    local answer

    read -r -p "Run ${step} (${description})? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        run_step_spec "$step"
    else
        log_warn "Skipping ${step}."
    fi
}

select_steps_with_whiptail() {
    local selection
    local -a selected_steps

    selection=$(
        whiptail \
            --title "Ubuntu Bootstrap" \
            --checklist "Select the steps to run (Press <Space> to toggle, <Enter> to confirm)" \
            20 90 12 \
            "preflight" "Check prerequisites before changes" OFF \
            "proxy" "Activate a proxy profile" OFF \
            "system" "System update and required packages" OFF \
            "applications" "VS Code and Chrome" OFF \
            "shell" "Zsh, Oh My Zsh, plugins, and theme" OFF \
            "appearance" "D2Coding font and colorls" OFF \
            "tools" "Developer CLI tools" OFF \
            "python" "Python via pyenv and pipx bootstrap" OFF \
            "editor" "Vim and plugin bootstrap" OFF \
            "dev-auth" "Git, SSH, and GPG bootstrap" OFF \
            "config" "Managed dotfile content update" OFF \
            "restore" "Restore latest config backups" OFF \
            "verify" "Tooling verification" OFF \
            3>&1 1>&2 2>&3
    ) || return 1

    selection="${selection//\"/}"
    read -r -a selected_steps <<< "$selection"

    if [[ ${#selected_steps[@]} -eq 0 ]]; then
        log_warn "No steps selected. Exiting."
        return 1
    fi

    log_info "Running selected setup steps: ${selected_steps[*]}"
    for step in "${selected_steps[@]}"; do
        run_step_spec "$step"
    done
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

configure_whiptail_colors

log_section "Preparing setup scripts"
chmod +x scripts/*.sh

if [[ $# -eq 0 || "$1" == "select" ]]; then
    log_info "No steps were passed. Starting interactive selection."
    if command -v whiptail >/dev/null 2>&1; then
        if ! select_steps_with_whiptail; then
            log_warn "Selection cancelled."
            exit 0
        fi
    else
        prompt_step "preflight" "check prerequisites before changes"
        prompt_step "proxy" "activate a proxy profile"
        prompt_step "system" "system update and required packages"
        prompt_step "applications" "VS Code and Chrome"
        prompt_step "shell" "Zsh, Oh My Zsh, plugins, and theme"
        prompt_step "appearance" "D2Coding font and colorls"
        prompt_step "tools" "developer CLI tools"
        prompt_step "python" "Python via pyenv and pipx bootstrap"
        prompt_step "editor" "Vim and plugin bootstrap"
        prompt_step "dev-auth" "Git, SSH, and GPG bootstrap"
        prompt_step "config" "managed dotfile content update"
        prompt_step "restore" "restore latest config backups"
        prompt_step "verify" "tooling verification"
    fi
elif [[ "$1" == "all" || "$1" == "full" ]]; then
    log_info "Running all setup steps."
    run_step_spec "preflight"
    run_step_spec "proxy:auto"
    run_step_spec "system"
    run_step_spec "applications:all"
    run_step_spec "shell"
    run_step_spec "appearance"
    run_step_spec "tools"
    run_step_spec "python"
    run_step_spec "editor"
    run_step_spec "dev-auth:git,ssh"
    run_step_spec "config:all"
    run_step_spec "verify"
elif [[ "$1" == "run" ]]; then
    shift
    if [[ $# -eq 0 ]]; then
        log_error "No steps were provided for run."
        usage
        exit 1
    fi

    log_info "Running selected setup steps: $*"
    for step in "$@"; do
        run_step_spec "$step"
    done
else
    log_info "Running selected setup steps: $*"
    for step in "$@"; do
        run_step_spec "$step"
    done
fi

if [[ "$RAN_ANY_STEP" -eq 1 ]]; then
    log_section "Setup complete"
    log_ok "Restart your terminal."
fi
