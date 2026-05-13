alias dc='docker compose'
alias g='git'
alias tf='terraform'
alias s4='zellij --layout s4' # 画面を4分割
alias cc='claude'
alias ca='claude agents'

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
# zsh-syntax-highlighting は ZLE ウィジェットをラップするため、必ず最後に source
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
