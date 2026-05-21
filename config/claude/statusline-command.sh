#!/usr/bin/env bash
# Claude Code statusLine command
# 3-line layout:
#   Line 1: 📂 ~/git/github.com/org/repo
#   Line 2: 🐙 repo-name │ 🌿 main
#   Line 3: 🧠 ████████░░░░░░░ 53% │ 💪 claude-sonnet-4-6

input=$(cat)

cwd=$(echo "$input"      | jq -r '.workspace.current_dir // .cwd // empty')
model_id=$(echo "$input" | jq -r '.model.id // empty')
used=$(echo "$input"     | jq -r '.context_window.used_percentage // empty')

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

# Context progress bar (16 blocks wide)
bar=""
used_int=""
if [ -n "$used" ]; then
  used_int=$(printf '%.0f' "$used")
  filled=$(( used_int * 16 / 100 ))
  empty=$(( 16 - filled ))
  for (( i=0; i<filled; i++ )); do bar="${bar}█"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done
fi

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

# ── line 3: context bar │ model ───────────────────────────────────────────────
line3=""
ctx_part=""
if [ -n "$bar" ] && [ -n "$used_int" ]; then
  if [ "$used_int" -ge 80 ]; then
    ctx_part="$(printf '🧠 \033[1;31m%s %d%%\033[0m' "$bar" "$used_int")"
  else
    ctx_part="$(printf '🧠 \033[0;37m%s\033[0m \033[1;37m%d%%\033[0m' "$bar" "$used_int")"
  fi
fi

model_part=""
[ -n "$model_id" ] && model_part="$(printf '💪 \033[1;35m%s\033[0m' "$model_id")"

if [ -n "$ctx_part" ] && [ -n "$model_part" ]; then
  line3="${ctx_part} $(printf '\033[0;37m│\033[0m') ${model_part}"
elif [ -n "$ctx_part" ]; then
  line3="$ctx_part"
elif [ -n "$model_part" ]; then
  line3="$model_part"
fi

# ── output (print only non-empty lines) ───────────────────────────────────────
out=""
[ -n "$line1" ] && out="${out}${line1}\n"
[ -n "$line2" ] && out="${out}${line2}\n"
[ -n "$line3" ] && out="${out}${line3}"

printf '%b' "$out"
