#!/usr/bin/env bash
# Claude Code statusLine command
# 3-line layout:
#   Line 1: 📂 ~/git/github.com/org/repo
#   Line 2: 🐙 repo-name │ 🌿 main
#   Line 3: ⏱ 5h: 42% (6/2 18:30) │ 7d: 18% (6/12 9:00) │ ctx: 72% │ 🤖 claude-sonnet-4-6

input=$(cat)

cwd=$(echo "$input"              | jq -r '.workspace.current_dir // .cwd // empty')
model_id=$(echo "$input"         | jq -r '.model.id // empty')
five_h=$(echo "$input"           | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_h_reset=$(echo "$input"     | jq -r '.rate_limits.five_hour.resets_at // empty')
seven_d=$(echo "$input"          | jq -r '.rate_limits.seven_day.used_percentage // empty')
seven_d_reset=$(echo "$input"    | jq -r '.rate_limits.seven_day.resets_at // empty')
ctx_remaining=$(echo "$input"    | jq -r '.context_window.remaining_percentage // empty')

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

# Convert Unix epoch to an absolute JST datetime string (BSD/macOS date)
# Output example: "6/12 9:00"
format_reset_time() {
  local epoch="$1"
  [ -z "$epoch" ] && return
  TZ=Asia/Tokyo date -r "$epoch" '+%-m/%-d %-H:%M' 2>/dev/null
}

# Rate limit formatting helper: colorize red if >= 80%
# Usage: format_rate <int_value> <label> [reset_epoch]  → echoes colored string
format_rate() {
  local val_int="$1"
  local label="$2"
  local reset_epoch="$3"
  local reset_str=""
  [ -n "$reset_epoch" ] && reset_str=$(format_reset_time "$reset_epoch")

  local pct_str="${label}: ${val_int}%"
  [ -n "$reset_str" ] && pct_str="${pct_str} (${reset_str})"

  if [ "$val_int" -ge 80 ]; then
    printf '\033[1;31m%s\033[0m' "$pct_str"
  else
    printf '\033[1;37m%s\033[0m' "$pct_str"
  fi
}

# Context remaining formatting helper: yellow < 50%, red < 20%
format_ctx() {
  local val_int="$1"
  if [ "$val_int" -lt 20 ]; then
    printf '\033[1;31mctx: %d%%\033[0m' "$val_int"
  elif [ "$val_int" -lt 50 ]; then
    printf '\033[1;33mctx: %d%%\033[0m' "$val_int"
  else
    printf '\033[1;37mctx: %d%%\033[0m' "$val_int"
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
  [ -n "$five_h_int" ]  && rate_segments="${rate_segments}$(format_rate "$five_h_int" "5h" "$five_h_reset")"
  if [ -n "$five_h_int" ] && [ -n "$seven_d_int" ]; then
    rate_segments="${rate_segments} $(printf '\033[0;37m│\033[0m') "
  fi
  [ -n "$seven_d_int" ] && rate_segments="${rate_segments}$(format_rate "$seven_d_int" "7d" "$seven_d_reset")"
  rate_part="$(printf '⏱ %b' "$rate_segments")"
fi

ctx_part=""
ctx_remaining_int=""
[ -n "$ctx_remaining" ] && ctx_remaining_int=$(printf '%.0f' "$ctx_remaining")
[ -n "$ctx_remaining_int" ] && ctx_part="$(format_ctx "$ctx_remaining_int")"

model_part=""
[ -n "$model_id" ] && model_part="$(printf '🤖 \033[1;35m%s\033[0m' "$model_id")"

sep="$(printf ' \033[0;37m│\033[0m ')"
line3=""
for seg in "$rate_part" "$ctx_part" "$model_part"; do
  [ -z "$seg" ] && continue
  [ -z "$line3" ] && line3="$seg" || line3="${line3}${sep}${seg}"
done

# ── output (print only non-empty lines) ───────────────────────────────────────
out=""
[ -n "$line1" ] && out="${out}${line1}\n"
[ -n "$line2" ] && out="${out}${line2}\n"
[ -n "$line3" ] && out="${out}${line3}"

printf '%b' "$out"
