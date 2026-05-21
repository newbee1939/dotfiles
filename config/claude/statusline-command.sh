#!/usr/bin/env bash
# Claude Code statusLine command
# Mirrors key Starship prompt info: dir + git branch + model

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

parts=()

# Directory
[ -n "$short_cwd" ] && parts+=("$(printf '\033[1;34m%s\033[0m' "$short_cwd")")

# Git branch (with Starship-like seedling symbol)
[ -n "$branch" ] && parts+=("$(printf '\033[1;33m🌱 %s\033[0m' "$branch")")

# Model
[ -n "$model" ] && parts+=("$(printf '\033[0;36m%s\033[0m' "$model")")

# Context remaining
if [ -n "$remaining" ]; then
  remaining_int=$(printf '%.0f' "$remaining")
  if [ "$remaining_int" -le 20 ]; then
    parts+=("$(printf '\033[1;31mctx:%s%%\033[0m' "$remaining_int")")
  else
    parts+=("$(printf '\033[0;37mctx:%s%%\033[0m' "$remaining_int")")
  fi
fi

# Join with separator
printf '%s' "$(IFS=' | '; echo "${parts[*]}")"
