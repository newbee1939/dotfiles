alias dc='docker compose'
alias g='git'
alias tf='terraform'
alias s4='zellij --layout s4' # 画面を4分割
alias cc='claude'
alias ca='claude agents'
# モデル使い分け（既定は settings.json で sonnet。Opus は利用枠を速く消費）
alias cc-haiku='claude --model haiku'
alias cc-sonnet='claude --model sonnet'
alias cc-opus='claude --model opus'

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source <(fzf --zsh)
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"
# zsh-syntax-highlighting は ZLE ウィジェットをラップするため、必ず最後に source
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
