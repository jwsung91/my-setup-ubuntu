#!/bin/bash
set -euo pipefail

# Set the working directory to the absolute path of this script.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    cat <<'EOF'
Usage:
  ./setup.sh                Start interactive step selection
  ./setup.sh all            Run every setup step
  ./setup.sh system applications shell   Run only selected steps

Available steps:
  system        System update and required packages
  applications  VS Code and Chrome
  shell         Zsh, Oh My Zsh, plugins, and theme
  appearance   D2Coding font and colorls
  stow         Dotfile symlinks via GNU Stow
EOF
}

run_step() {
    local step="$1"

    case "$step" in
        system)
            ./scripts/01-system.sh
            ;;
        applications)
            ./scripts/05-applications.sh "$@"
            ;;
        shell)
            ./scripts/02-shell.sh
            ;;
        appearance)
            ./scripts/03-appearance.sh
            ;;
        stow)
            ./scripts/04-stow.sh
            ;;
        *)
            echo "Unknown step: $step"
            usage
            exit 1
            ;;
    esac
}

prompt_step() {
    local step="$1"
    local description="$2"
    local answer

    read -r -p "Run ${step} (${description})? [y/N] " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        run_step "$step"
    else
        echo "Skipping ${step}."
    fi
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

echo "Making all scripts executable..."
chmod +x scripts/*.sh

if [[ $# -eq 0 ]]; then
    echo "No steps were passed. Starting interactive selection."
    prompt_step "system" "system update and required packages"
    prompt_step "applications" "VS Code and Chrome"
    prompt_step "shell" "Zsh, Oh My Zsh, plugins, and theme"
    prompt_step "appearance" "D2Coding font and colorls"
    prompt_step "stow" "dotfile symlinks"
elif [[ "$1" == "all" ]]; then
    echo "Running all setup steps."
    run_step "system"
    run_step "applications" "all"
    run_step "shell"
    run_step "appearance"
    run_step "stow"
else
    echo "Running selected setup steps: $*"
    for step in "$@"; do
        run_step "$step"
    done
fi

echo "=========================================="
echo "Setup complete. Restart your terminal."
echo "=========================================="
