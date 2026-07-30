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
   - 本文は次を軸にする。**目安は 15 行以内**（変更が大きいときは超えてよい）:
     ```
     ## 背景
     <何が困っていて、なぜやるのか 1〜2 文>

     ## やったこと
     <変更の要点 3〜5 個の箇条書き>

     ## 確認したこと
     <実際に動かして確かめた内容>

     ## あとでやること
     <今回スコープ外にしたこと / フォローが要ること。無ければ節ごと省く>

     ## 関連
     <Linear チケットの URL / 関連 PR・Issue>
     ```
   - 影響範囲など、レビュアーが判断に迷う点があるときだけ足す。**枠を埋めるために書かない**
   - Linear と紐づけるには、本文に `Fixes ENG-123`（チケット ID か URL）を書くか、タイトル / ブランチ名に ID を含める（[参考](https://linear.app/docs/github)）
4. 作成後、**PR の URL をユーザーに提示**する。ユーザーが画面で確認してから自分で Ready にする。**Claude が勝手に Ready にしない。**
5. 実装を修正したら、**PR の description も必ず最新化する**（`gh pr edit`）。

## 注意
- 承認が 0 件の PR はマージしない。
- main を最新にしてから差分を作る（`git fetch origin main`）。
