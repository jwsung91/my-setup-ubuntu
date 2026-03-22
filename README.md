# My Ubuntu Setup Scripts

This repository contains automation scripts for quickly bootstrapping an Ubuntu Desktop 22.04 / 24.04 `amd64` environment. It covers system packages, shell setup, fonts, and developer tooling in one run.

## Project Structure

```text
.
├── setup.sh                # Main entry point for interactive or selective setup
├── docs/                   # Extra reference docs
├── scripts/                # Step-by-step setup scripts
│   ├── applications.sh     # Selective VS Code and Chrome installation
│   ├── appearance.sh       # D2Coding font and colorls installation
│   ├── config.sh           # Managed dotfile content update and config merge
│   ├── dev-auth.sh         # Git, SSH, and GPG bootstrap
│   ├── editor.sh           # Vim and plugin bootstrap
│   ├── restore.sh          # Restore latest config backups
│   ├── shell.sh            # Zsh, Oh My Zsh, plugin, and theme installation
│   ├── system.sh           # System update and required package installation
│   ├── tools.sh            # Developer CLI tools
│   └── verify.sh           # Tooling verification
└── dotfiles/               # Managed configuration file templates
    ├── zsh/                # Zsh configuration such as .zshrc
    ├── git/                # Git configuration such as .gitconfig
    └── vim/                # Vim configuration such as .vimrc
```

## Included Features

1. **System packages**: runs `apt update && apt upgrade` and installs required packages such as `curl`, `wget`, `git`, and `build-essential`
2. **Applications**: lets you choose VS Code and Google Chrome individually
3. **Terminal setup**: installs Zsh, Oh My Zsh, the `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins, and the `powerlevel10k` theme
4. **CLI appearance**: installs the D2Coding font and `colorls`
5. **Developer tools**: installs common terminal tools such as `ripgrep`, `fd`, `fzf`, `bat`, and `jq`
6. **Editor bootstrap**: installs Vim, bootstraps Vundle, and runs a non-interactive Vim plugin sync
7. **Dotfile management**: backs up existing config files, installs managed config fragments, and adds include or source blocks without duplication
8. **Developer authentication**: prepares baseline Git identity settings and optional SSH or GPG bootstrap
9. **Verification**: checks required and optional tooling separately, prints a summary, and fails if required tools are missing
10. **Restore**: restores the latest backup for managed config targets when you need to roll back

## Supported Environment

- Ubuntu Desktop `22.04` or `24.04`
- `amd64` (`x86_64`) architecture

ARM-based Ubuntu is not supported because the Chrome package used by the script is `amd64` only.

## Installation

Run one of the following commands from inside the `my-setup-ubuntu` repository:

```bash
# Start interactive step selection
./setup.sh

# Start interactive step selection explicitly
./setup.sh select

# Run the full setup in order
./setup.sh full

# Run only selected steps
./setup.sh run system applications shell appearance tools editor dev-auth config verify

# Run only the applications step and choose interactively
./scripts/applications.sh

# Install only VS Code
./scripts/applications.sh vscode
```

> Note: `sudo` privileges are required during execution. Each script uses `set -euo pipefail` and exits early on unsupported Ubuntu versions or architectures.

## Behavior

- `./setup.sh select` lets you choose steps one by one.
- `./setup.sh full` runs the full setup in the default order.
- `./setup.sh run ...` runs only the steps you specify.
- `setup.sh` supports both interactive selection and explicit step arguments.
- Several steps are written to be re-runnable and will reuse already installed components when possible.
- The default full setup order is `system -> applications -> shell -> appearance -> tools -> editor -> dev-auth -> config -> verify`.
- The default full setup runs `dev-auth` with `git` and `ssh`; GPG is optional and can be selected separately.
- The `config` step can apply `zsh`, `git`, and `vim` targets independently.
- The `restore` step can restore the latest backup for `zsh`, `git`, and `vim` targets independently.
- The `verify` step separates required checks from optional checks and returns a non-zero exit code when required tooling is missing.
- CLI tool details are documented in [`docs/tools.md`](/home/rain/workspace/jwsung91/my-setup-ubuntu/docs/tools.md).
- For Zsh, Git, and Vim, the script keeps managed files such as `~/.zshrc.my-setup-ubuntu` and updates the main config files by appending include or source blocks only when those blocks are not already present.
- If an existing config file must be changed, the script creates a timestamped backup before writing the updated file.
- When `chsh` changes the default shell to `zsh`, the change applies on the next login.
- The `dev-auth` step uses `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `NAME`, or `EMAIL` if they are already set in the environment.

## Additional Configuration

- **Zsh settings**: add any extra environment variables you need in `dotfiles/zsh/.zshrc`.
- **Aliases**: when `colorls` is installed, the `ls`, `l`, `la`, and `ll` aliases are applied automatically.

## Restarting the Terminal

After setup completes, restart the terminal or run `source ~/.zshrc` to apply the shell changes.
