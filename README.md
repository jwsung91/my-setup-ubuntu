# My Ubuntu Setup Scripts

This repository contains automation scripts for quickly bootstrapping an Ubuntu Desktop 22.04 / 24.04 `amd64` environment. It covers system packages, shell setup, fonts, and developer tooling in one run.

## Project Structure

```text
.
├── setup.sh                # Main entry point for interactive or selective setup
├── scripts/                # Step-by-step setup scripts
│   ├── 01-system.sh        # System update and required package installation
│   ├── 02-shell.sh         # Zsh, Oh My Zsh, plugin, and theme installation
│   ├── 03-appearance.sh    # D2Coding font and colorls installation
│   ├── 04-stow.sh          # Dotfile symlink setup via GNU Stow
│   └── 05-applications.sh  # Selective VS Code and Chrome installation
└── dotfiles/               # Managed configuration files for Stow
    ├── zsh/                # Zsh configuration such as .zshrc
    ├── git/                # Git configuration such as .gitconfig
    └── vim/                # Vim configuration such as .vimrc
```

## Included Features

1. **System packages**: runs `apt update && apt upgrade` and installs required packages such as `curl`, `wget`, `git`, `stow`, and `build-essential`
2. **Applications**: lets you choose VS Code and Google Chrome individually
3. **Terminal setup**: installs Zsh, Oh My Zsh, the `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins, and the `powerlevel10k` theme
4. **CLI appearance**: installs the D2Coding font and `colorls`
5. **Dotfile management**: links files from `dotfiles/` into the home directory with GNU Stow

## Supported Environment

- Ubuntu Desktop `22.04` or `24.04`
- `amd64` (`x86_64`) architecture

ARM-based Ubuntu is not supported because the Chrome package used by the script is `amd64` only.

## Installation

Run one of the following commands from inside the `my-setup-ubuntu` repository:

```bash
# Start interactive step selection
./setup.sh

# Run the full setup
./setup.sh all

# Run only selected steps
./setup.sh system applications shell

# Run only the applications step and choose interactively
./scripts/05-applications.sh

# Install only VS Code
./scripts/05-applications.sh vscode
```

> Note: `sudo` privileges are required during execution. Each script uses `set -euo pipefail` and exits early on unsupported Ubuntu versions or architectures.

## Behavior

- `setup.sh` supports both interactive selection and explicit step arguments.
- Several steps are written to be re-runnable and will reuse already installed components when possible.
- Before applying `stow`, the script checks for conflicts. If files with the same target names already exist in your home directory, the process stops until you resolve them.
- When `chsh` changes the default shell to `zsh`, the change applies on the next login.

## Additional Configuration

- **Zsh settings**: add any extra environment variables you need in `dotfiles/zsh/.zshrc`.
- **Aliases**: when `colorls` is installed, the `ls`, `l`, `la`, and `ll` aliases are applied automatically.

## Restarting the Terminal

After setup completes, restart the terminal or run `source ~/.zshrc` to apply the shell changes.
