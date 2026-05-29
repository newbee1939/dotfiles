---
name: create-pr（PR 作成）
description: 現在のブランチにたまった変更を Pull Request にまとめて出すフェーズで使う。初回はドラフトで作成し URL を提示する。
---

# Create PR（PR 作成）

`gh` を使って PR を作成する。以下の運用ルールに従う。

## 手順
1. 現在のブランチと main の差分を確認する（`git log main..HEAD`, `git diff main...HEAD`）。
2. 未 push のコミットがあれば push する（`git push -u origin <branch>`）。
3. **初回は必ずドラフトで作成する**（`gh pr create --draft`）。
   - タイトル: 変更の要点（日本語）
   - 本文: 背景 / 変更内容 / 動作確認 / 影響範囲 / 後でやること を簡潔に
4. 作成後、**PR の URL をユーザーに提示**する。ユーザーが画面で確認してから自分で Ready にする。**Claude が勝手に Ready にしない。**
5. 実装を修正したら、**PR の description も必ず最新化する**（`gh pr edit`）。

## 注意
- 承認が 0 件の PR はマージしない。
- main を最新にしてから差分を作る（`git fetch origin main`）。
