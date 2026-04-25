#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BREWFILE_PATH="$REPO_ROOT/Brewfile"
ZSHRC_EXTRA_PATH="$REPO_ROOT/shell/.zshrc.extra.zsh"
STARSHIP_SOURCE_PATH="$REPO_ROOT/config/starship/starship.toml"
STARSHIP_TARGET_PATH="$HOME/.config/starship.toml"
ZSHRC_PATH="$HOME/.zshrc"
ZSHRC_MARKER='source "$HOME/work/dotfiles/shell/.zshrc.extra.zsh"'
GITCONFIG_TEMPLATE_PATH="$REPO_ROOT/config/git/.gitconfig.template"
GITCONFIG_PATH="$HOME/.gitconfig"
GITCONFIG_LOCAL_PATH="$HOME/.gitconfig.local"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Install it first: https://brew.sh/"
  exit 1
fi

echo "Installing packages from Brewfile..."
brew bundle --file="$BREWFILE_PATH"

mkdir -p "$HOME/.config"

rm -f "$STARSHIP_TARGET_PATH"
ln -s "$STARSHIP_SOURCE_PATH" "$STARSHIP_TARGET_PATH"
echo "Linked starship config: $STARSHIP_TARGET_PATH"

touch "$ZSHRC_PATH"
if ! rg -F "$ZSHRC_MARKER" "$ZSHRC_PATH" >/dev/null 2>&1; then
  {
    echo ""
    echo "# dotfiles"
    echo "$ZSHRC_MARKER"
  } >>"$ZSHRC_PATH"
  echo "Updated $ZSHRC_PATH"
else
  echo "$ZSHRC_PATH already includes dotfiles config"
fi

chmod +x "$REPO_ROOT/scripts/install-vscode-extensions.sh"

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

echo "Bootstrap completed."
