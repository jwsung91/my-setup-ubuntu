# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh

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
