# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"
export PYENV_ROOT="$HOME/.pyenv"

if [ -x "$PYENV_ROOT/bin/pyenv" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - zsh)"
fi

if [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
    ZSH_THEME="powerlevel10k/powerlevel10k"
else
    ZSH_THEME="robbyrussell"
fi

if [ -d "$ZSH" ] && [ -f "$ZSH/oh-my-zsh.sh" ]; then
    plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
    source "$ZSH/oh-my-zsh.sh"
else
    plugins=()
fi

if [ -n "${TTY:-}" ] || [ -t 0 ]; then
    export GPG_TTY="$(tty)"
fi

# Gemini API key example
# export GEMINI_API_KEY="put_your_key_here"

# Colorls Alias
if [ -x "$(command -v colorls)" ]; then
    alias ls='colorls'
    alias l='colorls -l'
    alias la='colorls -a'
    alias ll='colorls -la'
fi

# Zoxide initialization
if [ -x "$(command -v zoxide)" ]; then
    eval "$(zoxide init zsh)"
    alias cd="z"
fi

# Lazygit alias
if [ -x "$(command -v lazygit)" ]; then
    alias lg='lazygit'
fi

# Lazydocker alias
if [ -x "$(command -v lazydocker)" ]; then
    alias ldo='lazydocker'
fi

# Eza alias (modern ls)
if [ -x "$(command -v eza)" ]; then
    alias ls='eza --icons --group-directories-first'
    alias l='eza -lbF --icons --group-directories-first'
    alias ll='eza -lbGF --icons --group-directories-first'
    alias llm='eza -lbGd --icons --group-directories-first --sort=modified'
    alias la='eza -lbhHigUmuSa --icons --group-directories-first'
    alias lx='eza -lbhHigUmuSa@ --icons --group-directories-first'
    alias lt='eza --tree --icons --group-directories-first'
    alias tree='eza --tree --icons --group-directories-first'
fi

# Yazi alias
if [ -x "$(command -v yazi)" ]; then
    alias y='yazi'
fi
