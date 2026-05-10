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
