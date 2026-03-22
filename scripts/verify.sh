#!/bin/bash
set -euo pipefail

REQUIRED_OK=0
REQUIRED_WARN=0
OPTIONAL_OK=0
OPTIONAL_WARN=0

check_required() {
    local label="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        echo "[OK][required] $label"
        REQUIRED_OK=$((REQUIRED_OK + 1))
    else
        echo "[WARN][required] $label"
        REQUIRED_WARN=$((REQUIRED_WARN + 1))
    fi
}

check_optional() {
    local label="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        echo "[OK][optional] $label"
        OPTIONAL_OK=$((OPTIONAL_OK + 1))
    else
        echo "[WARN][optional] $label"
        OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
    fi
}

echo "--- Verifying installed tooling ---"
check_required "git available" git --version
check_required "zsh available" zsh --version
check_required "vim available" vim --version
check_required "ssh available" ssh -V

check_optional "gpg available" gpg --version
check_optional "gpg-agent configuration valid" gpg-agent --gpgconf-test
check_optional "code available" code --version
check_optional "google-chrome available" google-chrome --version
check_optional "colorls available" colorls --version
check_optional "ripgrep available" rg --version
check_optional "fd available" fd --version
check_optional "fzf available" fzf --version
check_optional "bat available" bat --version
check_optional "jq available" jq --version
check_optional "tmux available" tmux -V
check_optional "xclip available" xclip -version

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    echo "[OK][optional] SSH public key present: $HOME/.ssh/id_ed25519.pub"
    OPTIONAL_OK=$((OPTIONAL_OK + 1))
else
    echo "[WARN][optional] SSH public key missing: $HOME/.ssh/id_ed25519.pub"
    OPTIONAL_WARN=$((OPTIONAL_WARN + 1))
fi

echo "--- Verification summary ---"
echo "Required passed: $REQUIRED_OK"
echo "Required warnings: $REQUIRED_WARN"
echo "Optional passed: $OPTIONAL_OK"
echo "Optional warnings: $OPTIONAL_WARN"

if [[ "$REQUIRED_WARN" -gt 0 ]]; then
    exit 1
fi
