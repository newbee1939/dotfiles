# リポジトリの足場

新規リポジトリに入れる最小セット。**これ以外は必要になってから足す。**

## 1. `.gitignore` に `.env`
鍵が 1 度でも push されたら履歴から消えない。**唯一、取り返しがつかない。**

## 2. シークレット検出とプッシュ保護

```bash
gh api -X PATCH repos/<owner>/<repo> --input - <<'JSON'
{"security_and_analysis":{
  "secret_scanning":{"status":"enabled"},
  "secret_scanning_push_protection":{"status":"enabled"},
  "dependabot_security_updates":{"status":"enabled"}}}
JSON
```

push protection は鍵を含む push をその場で拒否する。**AI は平気で鍵をベタ書きする**ので人間のレビューに頼らない。
`dependabot_security_updates` は脆弱性への修正 PR で**既定 off**。パブリックリポジトリは全部無料。

## 3. `.tool-versions`

```
node 25.6.0
```

**唯一の真実。** ローカルは mise、CI は `setup-*` の `*-version-file` が同じファイルを読む。
`.nvmrc` は使わない（mise が既定で読まず、ローカルと CI がズレる）。

## 4. CI（lint / test / build）
**検証ループの土台**。これが無いと Claude は「done に見えたら止まる」。

```yaml
name: CI
on:
  pull_request:
  push:
    branches: [main]

concurrency:                      # 続けて push したら古い実行を打ち切る
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read                  # 書き込みが要るジョブでだけ足す

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 10           # 暴走したジョブを課金ごと止める
    steps:
      # Action はタグでなくコミットハッシュで固定する（タグは書き換え可能）。
      # 末尾のコメントを見て Dependabot が更新 PR を出す。
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0
        with:
          node-version-file: .tool-versions
          cache: npm
      - run: npm ci --ignore-scripts
      - run: npm run lint
      - run: npm test
      - run: npm run build
```

ハッシュは `gh api repos/actions/checkout/commits/v7.0.1 --jq .sha` で引ける。

## 5. `AGENTS.md` と `CLAUDE.md`
`AGENTS.md` に開発ルールを書き、`CLAUDE.md` は `@AGENTS.md` の 1 行だけにする。AGENTS.md は Codex / Cursor / Copilot なども読む共通規格で、Claude Code は CLAUDE.md しか読まない。**二重管理しない。**

書くのは**推測できないこと**だけ — ビルド / テスト / デプロイのコマンド、既定と違う規約、環境の癖。
**コードを読めば分かることは書かない。** 長いほど守られなくなる。

## 6. `.github/dependabot.yml`
**パッケージを使うなら必ず入れる。** 無いと依存は放置され、脆弱性の通知だけが溜まる。

```yaml
version: 2
updates:
  - package-ecosystem: npm        # gomod / cargo / pip / terraform / docker
    directory: /
    schedule:
      interval: weekly            # グルーピングしているので届くのは週 1 本
    cooldown:
      default-days: 7             # 汚染されたリリースは数時間〜1 日で消される。
                                  # security updates に cooldown はかからない
    groups:
      npm:
        patterns: ["*"]           # 1 本の PR にまとめる
    open-pull-requests-limit: 1

  # ハッシュ固定した Action は、これが無いと永久に古いままになる
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
    groups:
      actions:
        patterns: ["*"]
    open-pull-requests-limit: 1
```

## 7. `.npmrc`（npm を使うなら）

```
strict-allow-scripts=true   # 未承認の install スクリプトを実行させない
min-release-age=7           # 公開から 7 日未満のバージョンは入れない
```

install 時に任意コードが走るのが汚染パッケージの侵入口。落ちたら**中身を読んでから** `npm approve-scripts <pkg>` で明示する。
