# Python Setup

The `python` step bootstraps a Python development environment around `pyenv`.

## What It Installs

- Ubuntu packages for building Python versions with `pyenv`
- `python3`, `python3-pip`, `python3-venv`
- `pipx`
- `pyenv`

## Usage

```bash
# Install pyenv and Python tooling only
./scripts/python.sh

# Install pyenv and also install a specific Python version
./scripts/python.sh 3.12.11
```

## Shell Integration

The managed [`dotfiles/zsh/.zshrc`](/home/rain/workspace/jwsung91/my-setup-ubuntu/dotfiles/zsh/.zshrc) file initializes `pyenv` only when it is installed:

```bash
export PYENV_ROOT="$HOME/.pyenv"
if [ -x "$PYENV_ROOT/bin/pyenv" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - zsh)"
fi
```

Apply the updated shell config with the `config` step, then restart the shell or run:

```bash
source ~/.zshrc
```

If you run `verify` immediately after setup without reloading the shell, `pyenv` may still appear missing in the current session. Reload the shell first, then run:

```bash
./setup.sh run verify
```
