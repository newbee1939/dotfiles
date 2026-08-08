#!/usr/bin/env bash
# 英語漬け用の Claude Code hook。イベント名で処理を振り分ける。
#   UserPromptSubmit: プロンプトに日本語が混ざっていたら弾く (逃げ道: 先頭に "ja:")
#   Stop:             Claude の返信を英語で読み上げる (リスニング)
set -uo pipefail

input=$(cat)

case "$(jq -r '.hook_event_name' <<<"$input")" in
UserPromptSubmit)
  jq -e '.prompt | startswith("ja:")' <<<"$input" >/dev/null && exit 0
  if jq -e '.prompt | test("[\\p{Hiragana}\\p{Katakana}]")' <<<"$input" >/dev/null; then
    # exit 2 の stderr は Claude ではなくユーザーへのフィードバックとして表示される
    echo 'Write your prompt in English. Prefix it with "ja:" if you really need Japanese.' >&2
    exit 2
  fi
  ;;
Stop)
  # コードブロックを落として先頭 300 文字だけ読み上げる (全文だと長すぎる)
  jq -r '.last_assistant_message // ""' <<<"$input" |
    awk '/^```/ { fence = !fence; next } !fence' |
    tr -d '`*#' |
    head -c 300 |
    say -v Samantha -r 190
  ;;
esac

exit 0
