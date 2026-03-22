#!/bin/bash
set -euo pipefail

DEV_EMAIL="${GIT_AUTHOR_EMAIL:-${EMAIL:-}}"
DEV_NAME="${GIT_AUTHOR_NAME:-${NAME:-}}"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
RUN_GIT=0
RUN_SSH=0
RUN_GPG=0

usage() {
    cat <<'EOF'
Usage:
  ./scripts/dev-auth.sh              Choose auth steps interactively
  ./scripts/dev-auth.sh all          Run git, ssh, and gpg setup
  ./scripts/dev-auth.sh git ssh      Run only git and ssh setup
  ./scripts/dev-auth.sh gpg          Run only gpg setup
EOF
}

select_dev_auth_with_whiptail() {
    local selection
    local -a selected_items

    selection=$(
        whiptail \
            --title "Developer Auth" \
            --checklist "Select the auth steps to run" \
            16 72 6 \
            "git" "Git identity defaults" ON \
            "ssh" "SSH key bootstrap" ON \
            "gpg" "GnuPG bootstrap" OFF \
            3>&1 1>&2 2>&3
    ) || return 1

    selection="${selection//\"/}"
    read -r -a selected_items <<< "$selection"

    if [[ ${#selected_items[@]} -eq 0 ]]; then
        echo "No auth steps selected. Skipping."
        return 1
    fi

    for item in "${selected_items[@]}"; do
        case "$item" in
            git) RUN_GIT=1 ;;
            ssh) RUN_SSH=1 ;;
            gpg) RUN_GPG=1 ;;
        esac
    done
}

if [[ $# -gt 0 && ( "$1" == "--help" || "$1" == "-h" ) ]]; then
    usage
    exit 0
fi

if [[ $# -eq 0 ]]; then
    if command -v whiptail >/dev/null 2>&1; then
        select_dev_auth_with_whiptail || exit 0
    else
        RUN_GIT=1
        RUN_SSH=1
    fi
else
    for item in "$@"; do
        case "$item" in
            all)
                RUN_GIT=1
                RUN_SSH=1
                RUN_GPG=1
                ;;
            git)
                RUN_GIT=1
                ;;
            ssh)
                RUN_SSH=1
                ;;
            gpg)
                RUN_GPG=1
                ;;
            *)
                echo "Unknown auth step: $item"
                usage
                exit 1
                ;;
        esac
    done
fi

if [[ "$RUN_GIT" -eq 0 && "$RUN_SSH" -eq 0 && "$RUN_GPG" -eq 0 ]]; then
    echo "No auth steps selected. Skipping."
    exit 0
fi

if [[ "$RUN_SSH" -eq 1 || "$RUN_GPG" -eq 1 ]]; then
    echo "--- Installing developer authentication prerequisites ---"
    sudo apt install -y openssh-client
fi

setup_gpg() {
    echo "--- Preparing GnuPG directory ---"
    sudo apt install -y pinentry-gnome3 pinentry-curses
    mkdir -p "$HOME/.gnupg"
    chmod 700 "$HOME/.gnupg"

    if [[ -f "$HOME/.gnupg/gpg-agent.conf" ]]; then
        sed -i '/^pinentry-mode loopback$/d' "$HOME/.gnupg/gpg-agent.conf"
    fi

    if [[ ! -f "$HOME/.gnupg/gpg-agent.conf" ]] || ! grep -Fq 'allow-loopback-pinentry' "$HOME/.gnupg/gpg-agent.conf"; then
        {
            [[ -f "$HOME/.gnupg/gpg-agent.conf" ]] && cat "$HOME/.gnupg/gpg-agent.conf"
            echo "allow-loopback-pinentry"
            echo "default-cache-ttl 3600"
            echo "max-cache-ttl 86400"
        } | awk '!seen[$0]++' > "$HOME/.gnupg/gpg-agent.conf.tmp"
        install -m 600 "$HOME/.gnupg/gpg-agent.conf.tmp" "$HOME/.gnupg/gpg-agent.conf"
        rm -f "$HOME/.gnupg/gpg-agent.conf.tmp"
    fi

    if [[ ! -f "$HOME/.gnupg/gpg.conf" ]] || ! grep -Fq 'pinentry-mode loopback' "$HOME/.gnupg/gpg.conf"; then
        {
            [[ -f "$HOME/.gnupg/gpg.conf" ]] && cat "$HOME/.gnupg/gpg.conf"
            echo "use-agent"
            echo "pinentry-mode loopback"
        } | awk '!seen[$0]++' > "$HOME/.gnupg/gpg.conf.tmp"
        install -m 600 "$HOME/.gnupg/gpg.conf.tmp" "$HOME/.gnupg/gpg.conf"
        rm -f "$HOME/.gnupg/gpg.conf.tmp"
    fi

    gpgconf --kill gpg-agent >/dev/null 2>&1 || true
    gpgconf --launch gpg-agent
}

setup_ssh() {
    echo "--- Preparing SSH key ---"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    if [[ ! -f "$SSH_KEY_PATH" ]]; then
        if [[ -n "$DEV_EMAIL" ]]; then
            ssh-keygen -t ed25519 -C "$DEV_EMAIL" -f "$SSH_KEY_PATH" -N ""
        else
            echo "Skipping SSH key generation because no email was provided."
            echo "Set EMAIL or GIT_AUTHOR_EMAIL before running this step to generate a labeled key."
        fi
    else
        echo "SSH key already exists: $SSH_KEY_PATH"
    fi
}

setup_git() {
    echo "--- Preparing Git identity defaults ---"
    if [[ -n "$DEV_NAME" ]]; then
        git config --global user.name "$DEV_NAME"
    else
        echo "Skipping git user.name because no name was provided."
    fi

    if [[ -n "$DEV_EMAIL" ]]; then
        git config --global user.email "$DEV_EMAIL"
    else
        echo "Skipping git user.email because no email was provided."
    fi

    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.editor vim
}

if [[ "$RUN_GPG" -eq 1 ]]; then
    setup_gpg
fi

if [[ "$RUN_SSH" -eq 1 ]]; then
    setup_ssh
fi

if [[ "$RUN_GIT" -eq 1 ]]; then
    setup_git
fi

echo "--- Developer authentication bootstrap complete ---"
