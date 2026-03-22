#!/bin/bash
set -euo pipefail

REQUIRED_OK=0
REQUIRED_WARN=0
OPTIONAL_OK=0
OPTIONAL_WARN=0

check_required_shell() {
    local label="$1"
    local command_string="$2"

    if bash -lc "$command_string" >/dev/null 2>&1; then
        echo "[OK][required] $label"
        REQUIRED_OK=$((REQUIRED_OK + 1))
    else
        echo "[WARN][required] $label"
        REQUIRED_WARN=$((REQUIRED_WARN + 1))
    fi
}

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

check_required_local_bin_path() {
    local managed_zshrc="$HOME/.zshrc.my-setup-ubuntu"
    local user_zshrc="$HOME/.zshrc"
    local path_line='export PATH="$HOME/.local/bin:$PATH"'

    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]] \
        || { [[ -f "$managed_zshrc" ]] && grep -Fq "$path_line" "$managed_zshrc"; } \
        || { [[ -f "$user_zshrc" ]] && grep -Fq "$path_line" "$user_zshrc"; }; then
        echo "[OK][required] ~/.local/bin configured for PATH"
        REQUIRED_OK=$((REQUIRED_OK + 1))
    else
        echo "[WARN][required] ~/.local/bin configured for PATH"
        REQUIRED_WARN=$((REQUIRED_WARN + 1))
    fi
}

echo "--- Verifying installed tooling ---"
check_required "git available" git --version
check_required "zsh available" zsh --version
check_required "vim available" vim --version
check_required "ssh available" ssh -V
check_required_local_bin_path

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
check_optional "python3 available" python3 --version
check_optional "pipx available" pipx --version
check_optional "pyenv available" pyenv --version
check_optional "git user.name configured" git config --global user.name
check_optional "git user.email configured" git config --global user.email

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
