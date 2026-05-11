# dotfiles

Mac 開発環境をコードで管理し、再現可能にするための `dotfiles` です。

## 運用ルール

- 各アプリや設定は直接編集せず、このリポジトリの対応ファイルを編集して反映する
- 変更は Git で履歴化し、別端末でも同じ手順で復元する

## セットアップ

### 1) リポジトリを配置

```bash
git clone <your-repo-url> ~/work/dotfiles
cd ~/work/dotfiles
```

### 2) Homebrew を導入（未導入時）

### 3) 自動セットアップ

```bash
./scripts/bootstrap.sh
```

### 4) VSCode/Cursor 拡張を適用

```bash
while read -r extension; do code --install-extension "$extension"; done < config/vscode/extensions.list
while read -r extension; do code-insiders --install-extension "$extension"; done < config/vscode/extensions.list
while read -r extension; do cursor --install-extension "$extension"; done < config/vscode/extensions.list
```

### 5) VSCode/Cursor 設定を反映

`config/vscode/settings.json` を各 User Settings に手動でコピーします。

- VSCode: `~/Library/Application Support/Code/User/settings.json`
- VSCode Insiders: `~/Library/Application Support/Code - Insiders/User/settings.json`
- Cursor: `~/Library/Application Support/Cursor/User/settings.json`

## 手動設定（未自動化）

- `gh auth login` と SSH 鍵の生成/登録

## 操作 Tips

- **Claude Code のレスポンスをコピーしたい**: Zellij のスクロールモード (`Ctrl + S` で出入り) を使うと、入力欄に影響を与えず過去の出力を選択・コピーできる。

## 並行作業 (git worktree)

同じリポジトリで複数のブランチ作業を並行させたいときは `git worktree` を使う。`.git` を共有しつつ別ディレクトリに独立した作業ツリーを作る Git 標準機能で、複数の Claude Code セッションを互いに干渉させずに走らせられる。

### 例: `feature/add-aerospace` を並行ブランチで作業する

`~/work/dotfiles` がメインの作業ツリーだとする。

```bash
# メインの作業ツリーで実行
git worktree add ../dotfiles-add-aerospace -b feature/add-aerospace

# 作成された作業ツリーに移動して Claude Code 起動
cd ../dotfiles-add-aerospace
claude
```

これで `~/work/dotfiles-add-aerospace` に `feature/add-aerospace` ブランチがチェックアウトされた独立ディレクトリができる。メインの `~/work/dotfiles` は `main` のまま触れる。

ポイント:

- `../` は「親ディレクトリ」を指すパス記法。作業ツリーは**リポジトリの外**に置くのが定石（中に置くと Git が混乱しやすい）。親ディレクトリ直下が最もシンプル。
- ディレクトリ名 (`dotfiles-add-aerospace`) はブランチ名 (`feature/add-aerospace`) の `feature/` を省いてハイフン区切りにしている。**ブランチ名のスラッシュをそのままディレクトリ名にすると中間ディレクトリが作られて扱いにくい**ため。
- `-b` は「新しいブランチを切ってチェックアウトする」オプション。既存ブランチを使う場合は `-b` を外す。

### よく使うコマンド

| 用途 | コマンド |
|---|---|
| 一覧表示 | `git worktree list` |
| 作業ツリーを削除（ブランチは残る） | `git worktree remove ../dotfiles-add-aerospace` |
| ブランチも削除 | `git branch -D feature/add-aerospace` |

Zellij で新しいペインを開き、`cd` してから `claude` を起動すれば、ペインごとに別ブランチのセッションを並行で走らせられる。
