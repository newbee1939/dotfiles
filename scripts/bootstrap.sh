#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BREWFILE_PATH="$REPO_ROOT/Brewfile"
ZSHRC_EXTRA_PATH="$REPO_ROOT/shell/.zshrc.extra.zsh"
STARSHIP_SOURCE_PATH="$REPO_ROOT/config/starship/starship.toml"
STARSHIP_TARGET_PATH="$HOME/.config/starship.toml"
ZELLIJ_SOURCE_PATH_S4="$REPO_ROOT/config/zellij/layouts/s4.kdl" # 画面を4分割
ZELLIJ_TARGET_PATH_S4="$HOME/.config/zellij/layouts/s4.kdl"
# Ghostty設定の追加
GHOSTTY_SOURCE_PATH="$REPO_ROOT/config/ghostty/config"
GHOSTTY_TARGET_PATH="$HOME/.config/ghostty/config"
# Claude Code 設定の追加
CLAUDE_CLAUDEMD_SOURCE_PATH="$REPO_ROOT/config/claude/CLAUDE.md"
CLAUDE_CLAUDEMD_TARGET_PATH="$HOME/.claude/CLAUDE.md"
CLAUDE_SETTINGS_SOURCE_PATH="$REPO_ROOT/config/claude/settings.json"
CLAUDE_SETTINGS_TARGET_PATH="$HOME/.claude/settings.json"
CLAUDE_STATUSLINE_SOURCE_PATH="$REPO_ROOT/config/claude/statusline-command.sh"
CLAUDE_STATUSLINE_TARGET_PATH="$HOME/.claude/statusline-command.sh"

ZSHRC_PATH="$HOME/.zshrc"
ZSHRC_MARKER="source \"$ZSHRC_EXTRA_PATH\""
GITCONFIG_TEMPLATE_PATH="$REPO_ROOT/config/git/.gitconfig.template"
GITCONFIG_PATH="$HOME/.gitconfig"
GITCONFIG_LOCAL_PATH="$HOME/.gitconfig.local"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Install it first: https://brew.sh/"
  exit 1
fi

if [ ! -f "$ZSHRC_EXTRA_PATH" ]; then
  echo "Missing file: $ZSHRC_EXTRA_PATH"
  exit 1
fi

echo "Updating Homebrew..."
brew update

echo "Installing packages from Brewfile..."
brew bundle --file="$BREWFILE_PATH"

# Claude Codeのインストール
# 参考: https://code.claude.com/docs/ja/quickstart#native-install-recommended
if ! command -v claude >/dev/null 2>&1; then
  echo "Installing Claude CLI..."
  curl -fsSL https://claude.ai/install.sh | bash
else
  echo "Claude Code is already installed."
fi

mkdir -p "$HOME/.config"

# Starship
if [ -e "$STARSHIP_TARGET_PATH" ] && [ ! -L "$STARSHIP_TARGET_PATH" ]; then
  backup_path="$STARSHIP_TARGET_PATH.bak.$(date +%Y%m%d%H%M%S)"
  mv "$STARSHIP_TARGET_PATH" "$backup_path"
  echo "Backed up existing starship config: $backup_path"
fi
rm -f "$STARSHIP_TARGET_PATH"
ln -s "$STARSHIP_SOURCE_PATH" "$STARSHIP_TARGET_PATH"
echo "Linked starship config: $STARSHIP_TARGET_PATH"

# Zellij
if [ -e "$ZELLIJ_TARGET_PATH_S4" ] && [ ! -L "$ZELLIJ_TARGET_PATH_S4" ]; then
  backup_path="$ZELLIJ_TARGET_PATH_S4.bak.$(date +%Y%m%d%H%M%S)"
  mv "$ZELLIJ_TARGET_PATH_S4" "$backup_path"
  echo "Backed up existing Zellij config: $backup_path"
fi
rm -f "$ZELLIJ_TARGET_PATH_S4"
mkdir -p "$(dirname "$ZELLIJ_TARGET_PATH_S4")"
ln -s "$ZELLIJ_SOURCE_PATH_S4" "$ZELLIJ_TARGET_PATH_S4"
echo "Linked Zellij config: $ZELLIJ_TARGET_PATH_S4"

# Ghostty
if [ -e "$GHOSTTY_TARGET_PATH" ] && [ ! -L "$GHOSTTY_TARGET_PATH" ]; then
  backup_path="$GHOSTTY_TARGET_PATH.bak.$(date +%Y%m%d%H%M%S)"
  mv "$GHOSTTY_TARGET_PATH" "$backup_path"
  echo "Backed up existing Ghostty config: $backup_path"
fi
rm -f "$GHOSTTY_TARGET_PATH"
mkdir -p "$(dirname "$GHOSTTY_TARGET_PATH")"
ln -s "$GHOSTTY_SOURCE_PATH" "$GHOSTTY_TARGET_PATH"
echo "Linked Ghostty config: $GHOSTTY_TARGET_PATH"

# Claude Code: CLAUDE.md
mkdir -p "$HOME/.claude"
if [ -e "$CLAUDE_CLAUDEMD_TARGET_PATH" ] && [ ! -L "$CLAUDE_CLAUDEMD_TARGET_PATH" ]; then
  backup_path="$CLAUDE_CLAUDEMD_TARGET_PATH.bak.$(date +%Y%m%d%H%M%S)"
  mv "$CLAUDE_CLAUDEMD_TARGET_PATH" "$backup_path"
  echo "Backed up existing Claude CLAUDE.md: $backup_path"
fi
rm -f "$CLAUDE_CLAUDEMD_TARGET_PATH"
ln -s "$CLAUDE_CLAUDEMD_SOURCE_PATH" "$CLAUDE_CLAUDEMD_TARGET_PATH"
echo "Linked Claude CLAUDE.md: $CLAUDE_CLAUDEMD_TARGET_PATH"

# Claude Code: settings.json
if [ -e "$CLAUDE_SETTINGS_TARGET_PATH" ] && [ ! -L "$CLAUDE_SETTINGS_TARGET_PATH" ]; then
  backup_path="$CLAUDE_SETTINGS_TARGET_PATH.bak.$(date +%Y%m%d%H%M%S)"
  mv "$CLAUDE_SETTINGS_TARGET_PATH" "$backup_path"
  echo "Backed up existing Claude settings.json: $backup_path"
fi
rm -f "$CLAUDE_SETTINGS_TARGET_PATH"
ln -s "$CLAUDE_SETTINGS_SOURCE_PATH" "$CLAUDE_SETTINGS_TARGET_PATH"
echo "Linked Claude settings.json: $CLAUDE_SETTINGS_TARGET_PATH"

# Claude Code: statusLine スクリプト
# 表示内容は Claude Code 上で `/statusline` を再実行すると調整できる。
# symlink が外れて実体ファイルに戻ったら、bootstrap.sh の再実行で貼り直される。
if [ -e "$CLAUDE_STATUSLINE_TARGET_PATH" ] && [ ! -L "$CLAUDE_STATUSLINE_TARGET_PATH" ]; then
  backup_path="$CLAUDE_STATUSLINE_TARGET_PATH.bak.$(date +%Y%m%d%H%M%S)"
  mv "$CLAUDE_STATUSLINE_TARGET_PATH" "$backup_path"
  echo "Backed up existing Claude statusline-command.sh: $backup_path"
fi
rm -f "$CLAUDE_STATUSLINE_TARGET_PATH"
ln -s "$CLAUDE_STATUSLINE_SOURCE_PATH" "$CLAUDE_STATUSLINE_TARGET_PATH"
echo "Linked Claude statusline-command.sh: $CLAUDE_STATUSLINE_TARGET_PATH"

touch "$ZSHRC_PATH"
if ! grep -F "$ZSHRC_MARKER" "$ZSHRC_PATH" >/dev/null 2>&1; then
  {
    echo ""
    echo "# dotfiles"
    echo "$ZSHRC_MARKER"
  } >>"$ZSHRC_PATH"
  echo "Updated $ZSHRC_PATH"
else
  echo "$ZSHRC_PATH already includes dotfiles config"
fi

cp "$GITCONFIG_TEMPLATE_PATH" "$GITCONFIG_PATH"
if [ ! -f "$GITCONFIG_LOCAL_PATH" ]; then
  echo "Creating $GITCONFIG_LOCAL_PATH"
  read -r -p "Git user.name: " git_user_name
  read -r -p "Git user.email: " git_user_email
  {
    echo "[user]"
    echo "  name = $git_user_name"
    echo "  email = $git_user_email"
  } >"$GITCONFIG_LOCAL_PATH"
  echo "Created $GITCONFIG_LOCAL_PATH"
fi

# デジタルデトックス: /etc/hosts に集中を妨げるサイトを追記してブロック
# 使い方: BLOCKED_SITES を編集して bootstrap.sh を再実行すれば反映される
HOSTS_FILE="/etc/hosts"
DETOX_BEGIN="# BEGIN DETOX"
DETOX_END="# END DETOX"
BLOCKED_SITES=(
  twitter.com www.twitter.com
  x.com www.x.com
  youtube.com www.youtube.com m.youtube.com youtu.be
  instagram.com www.instagram.com
  facebook.com www.facebook.com m.facebook.com
  reddit.com www.reddit.com old.reddit.com
  tiktok.com www.tiktok.com
  girlschannel.net www.girlschannel.net
  yahoo.co.jp www.yahoo.co.jp news.yahoo.co.jp
  twitch.tv www.twitch.tv
  pinterest.com www.pinterest.com
  nicovideo.jp www.nicovideo.jp
  togetter.com www.togetter.com
  5ch.net www.5ch.net 2ch.sc www.2ch.sc
  abema.tv www.abema.tv
  smartnews.com www.smartnews.com
  b.hatena.ne.jp
)

echo "Updating detox block in /etc/hosts (sudo required)..."
if grep -q "$DETOX_BEGIN" "$HOSTS_FILE" 2>/dev/null; then
  sudo sed -i '' "/$DETOX_BEGIN/,/$DETOX_END/d" "$HOSTS_FILE"
fi
{
  echo ""
  echo "$DETOX_BEGIN"
  for site in "${BLOCKED_SITES[@]}"; do
    echo "0.0.0.0 $site"
  done
  echo "$DETOX_END"
} | sudo tee -a "$HOSTS_FILE" >/dev/null
echo "Detox block updated"

echo "Bootstrap completed."
