#!/usr/bin/env bash
set -euo pipefail

echo "=== Mac Cleanup ==="
echo "Disk before: $(df -h / | awk 'NR==2 {print $4}') free"

echo ""
echo "[Homebrew]"
brew cleanup --prune=all
brew autoremove

echo ""
echo "[Logs]"
rm -rf ~/Library/Logs/*

echo ""
echo "[npm / pip / uv]"
command -v npm  &>/dev/null && npm cache clean --force
command -v pip3 &>/dev/null && pip3 cache purge
command -v uv   &>/dev/null && uv cache clean

echo ""
echo "[Trash]"
osascript -e 'tell application "Finder" to empty trash'

echo ""
echo "Disk after: $(df -h / | awk 'NR==2 {print $4}') free"
echo "=== Done ==="
