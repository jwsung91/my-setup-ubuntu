# Ubuntu Bootstrap

This repository contains automation scripts for quickly bootstrapping an Ubuntu Desktop 22.04 / 24.04 `amd64` environment. It covers system packages, shell setup, fonts, and developer tooling in one run.

## Project Structure

```text
.
├── setup.sh                # Main entry point for interactive or selective setup
├── docs/                   # Extra reference docs
├── proxy/                  # Proxy profile files such as work.env
├── scripts/                # Step-by-step setup scripts
│   ├── applications.sh     # Selective VS Code and Chrome installation
│   ├── appearance.sh       # D2Coding font and colorls installation
│   ├── config.sh           # Managed dotfile content update and config merge
│   ├── dev-auth.sh         # Git, SSH, and GPG bootstrap
│   ├── editor.sh           # Vim and plugin bootstrap
│   ├── preflight.sh        # Prerequisite checks before setup
│   ├── python.sh           # Python, pyenv, and pipx bootstrap
│   ├── proxy.sh            # Proxy profile activation
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

1. **Preflight checks**: validates prerequisites before setup starts changing the system
2. **Proxy profiles**: activates one of several proxy profiles before network-heavy steps
3. **System packages**: runs `apt update && apt upgrade` and installs required packages such as `curl`, `wget`, `git`, and `build-essential`
4. **Applications**: lets you choose VS Code and Google Chrome individually
5. **Terminal setup**: installs Zsh, Oh My Zsh, the `zsh-autosuggestions` and `zsh-syntax-highlighting` plugins, and the `powerlevel10k` theme
6. **CLI appearance**: installs the D2Coding font and `colorls`
7. **Developer tools**: installs modern terminal tools such as `ripgrep`, `fd`, `fzf`, `bat`, `jq`, `zoxide`, `tldr`, `lazygit`, `eza`, `btop`, `lazydocker`, `dust`, and `yazi`
8. **Python bootstrap**: installs `python3`, `pipx`, `pyenv`, and optional pyenv-managed Python versions
9. **Editor bootstrap**: installs Vim, bootstraps Vundle, and runs a non-interactive Vim plugin sync
10. **Dotfile management**: backs up existing config files, installs managed config fragments, and adds include or source blocks without duplication
11. **Developer authentication**: prepares baseline Git identity settings and optional SSH or GPG bootstrap
12. **Verification**: checks required and optional tooling separately, prints a summary, and fails if required tools are missing
13. **Restore**: restores the latest backup for managed config targets when you need to roll back
14. **Shared terminal UI**: uses common `scripts/lib/ui.sh` helpers for whiptail styling and colored log output

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

# Recommended sequence for a fresh machine
./setup.sh run preflight
sudo -v
./setup.sh full
source ~/.zshrc
./setup.sh run verify

# Run only selected steps
./setup.sh run preflight proxy system applications shell appearance tools python editor dev-auth config verify

# Pass step-specific arguments with step:arg1,arg2
./setup.sh run proxy:use,work applications:all python:3.12.11 config:all verify

# Check whether the machine is ready before setup
./scripts/preflight.sh

# Choose and activate a proxy profile
./scripts/proxy.sh

# Install pyenv and pipx
./scripts/python.sh

# Install pyenv and set a specific Python version
./scripts/python.sh 3.12.11

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
- `./setup.sh run step:arg1,arg2 ...` passes arguments through to individual steps.
- `setup.sh` supports both interactive selection and explicit step arguments.
- Several steps are written to be re-runnable and will reuse already installed components when possible.
- The default full setup order is `preflight -> proxy -> system -> applications -> shell -> appearance -> tools -> python -> editor -> dev-auth -> config -> verify`.
- The default full setup runs `dev-auth` with `git` and `ssh`; GPG is optional and can be selected separately.
- The `preflight` step validates prerequisites such as Ubuntu version, architecture, required commands, and proxy/profile readiness without modifying the system.
- The `python` step installs `pyenv`, `pipx`, and Python build dependencies. If you pass a version, it also installs and sets that Python version globally.
- The `proxy` step activates one profile from `proxy/*.env` by linking it to `.proxy.env`.
- When `full` is used, the `proxy` step auto-selects only when there is already an active `.proxy.env` file or exactly one available profile.
- The `config` step can apply `zsh`, `git`, and `vim` targets independently.
- The `restore` step can restore the latest backup for `zsh`, `git`, and `vim` targets independently.
- The `verify` step separates required checks from optional checks and returns a non-zero exit code when required tooling is missing.
- CLI tool details are documented in [`docs/tools.md`](/home/rain/workspace/jwsung91/my-setup-ubuntu/docs/tools.md).
- Python setup details are documented in [`docs/python.md`](/home/rain/workspace/jwsung91/my-setup-ubuntu/docs/python.md).
- Proxy setup is optional and documented in [`docs/proxy.md`](/home/rain/workspace/jwsung91/my-setup-ubuntu/docs/proxy.md).
- For Zsh, Git, and Vim, the script keeps managed files such as `~/.zshrc.my-setup-ubuntu` and updates the main config files by appending include or source blocks only when those blocks are not already present.
- If an existing config file must be changed, the script creates a timestamped backup before writing the updated file.
- When `chsh` changes the default shell to `zsh`, the change applies on the next login.
- The `dev-auth` step uses `GIT_AUTHOR_NAME`, `GIT_AUTHOR_EMAIL`, `NAME`, or `EMAIL` if they are already set in the environment.
- After the `python` and `config` steps, run `source ~/.zshrc` or open a new terminal before re-running `verify` so `pyenv` is visible in the shell.

## Additional Configuration

- **Zsh settings**: add any extra environment variables you need in `dotfiles/zsh/.zshrc`.
- **Aliases**: several aliases are applied automatically for a modern terminal experience:
  - `ls`, `l`, `la`, `ll`: mapped to `eza` (or `colorls` if eza is missing) with icons and git support.
  - `cd`: mapped to `zoxide` (z) for smarter directory navigation.
  - `lg`: alias for `lazygit`.
  - `ldo`: alias for `lazydocker`.
  - `y`: alias for `yazi`.

## Restarting the Terminal

After setup completes, restart the terminal or run `source ~/.zshrc` to apply the shell changes.
