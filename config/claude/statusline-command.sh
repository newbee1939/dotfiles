#!/usr/bin/env bash
# Claude Code statusLine command
# 3-line layout:
#   Line 1: 📂 ~/git/github.com/org/repo
#   Line 2: 🐙 repo-name │ 🌿 main
#   Line 3: ⏱ 5h: 42% │ 7d: 18% │ 💪 claude-sonnet-4-6

input=$(cat)

cwd=$(echo "$input"      | jq -r '.workspace.current_dir // .cwd // empty')
model_id=$(echo "$input" | jq -r '.model.id // empty')
five_h=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage // empty')
seven_d=$(echo "$input"  | jq -r '.rate_limits.seven_day.used_percentage // empty')

# ── helpers ──────────────────────────────────────────────────────────────────

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/~}"

# Git info (skip optional locks to avoid stale-lock delays)
git_root=$(git -C "$cwd" --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
branch=""
repo_name=""
if [ -n "$git_root" ]; then
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
  repo_name=$(basename "$git_root")
fi

# Rate limit formatting helper: colorize red if >= 80%
# Usage: format_rate <int_value> <label>  → echoes colored string
format_rate() {
  local val_int="$1"
  local label="$2"
  if [ "$val_int" -ge 80 ]; then
    printf '\033[1;31m%s: %d%%\033[0m' "$label" "$val_int"
  else
    printf '\033[1;37m%s: %d%%\033[0m' "$label" "$val_int"
  fi
}

# ── line 1: directory ─────────────────────────────────────────────────────────
line1=""
[ -n "$short_cwd" ] && line1="$(printf '📂 \033[1;34m%s\033[0m' "$short_cwd")"

# ── line 2: repo │ branch ─────────────────────────────────────────────────────
line2=""
if [ -n "$repo_name" ]; then
  repo_part="$(printf '🐙 \033[1;36m%s\033[0m' "$repo_name")"
  if [ -n "$branch" ]; then
    branch_part="$(printf '🌿 \033[1;32m%s\033[0m' "$branch")"
    line2="${repo_part} $(printf '\033[0;37m│\033[0m') ${branch_part}"
  else
    line2="$repo_part"
  fi
fi

# ── line 3: rate limits │ model ───────────────────────────────────────────────
line3=""
rate_part=""

five_h_int=""
seven_d_int=""
[ -n "$five_h" ]  && five_h_int=$(printf '%.0f' "$five_h")
[ -n "$seven_d" ] && seven_d_int=$(printf '%.0f' "$seven_d")

if [ -n "$five_h_int" ] || [ -n "$seven_d_int" ]; then
  rate_segments=""
  [ -n "$five_h_int" ]  && rate_segments="${rate_segments}$(format_rate "$five_h_int" "5h")"
  if [ -n "$five_h_int" ] && [ -n "$seven_d_int" ]; then
    rate_segments="${rate_segments} $(printf '\033[0;37m│\033[0m') "
  fi
  [ -n "$seven_d_int" ] && rate_segments="${rate_segments}$(format_rate "$seven_d_int" "7d")"
  rate_part="$(printf '⏱ %b' "$rate_segments")"
fi

model_part=""
[ -n "$model_id" ] && model_part="$(printf '💪 \033[1;35m%s\033[0m' "$model_id")"

if [ -n "$rate_part" ] && [ -n "$model_part" ]; then
  line3="${rate_part} $(printf '\033[0;37m│\033[0m') ${model_part}"
elif [ -n "$rate_part" ]; then
  line3="$rate_part"
elif [ -n "$model_part" ]; then
  line3="$model_part"
fi

# ── output (print only non-empty lines) ───────────────────────────────────────
out=""
[ -n "$line1" ] && out="${out}${line1}\n"
[ -n "$line2" ] && out="${out}${line2}\n"
[ -n "$line3" ] && out="${out}${line3}"

printf '%b' "$out"
