# リポジトリ共通の足場（コピペ用）

新しいリポジトリの**最初の PR で全部入れる**。既存リポジトリにも同じものを当てる。「後で」は入らない。
ここに無いものを足したくなったら、まず本ファイルに足す。

## 1. GitHub 側の設定（ファイルでは入らない）

```bash
OWNER=<owner>; REPO=<repo>

# 現状確認
gh api repos/$OWNER/$REPO --jq '.security_and_analysis'
gh api repos/$OWNER/$REPO/actions/permissions/workflow

# シークレット検出・プッシュ保護・Dependabot の自動セキュリティ修正
gh api -X PATCH repos/$OWNER/$REPO --input - <<'JSON'
{"security_and_analysis":{
  "secret_scanning":{"status":"enabled"},
  "secret_scanning_push_protection":{"status":"enabled"},
  "dependabot_security_updates":{"status":"enabled"}}}
JSON

# ワークフローの既定トークンを読み取りのみに
gh api -X PUT repos/$OWNER/$REPO/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
```

- **push protection** は鍵を含む push をその場で拒否する。パブリックは無料、プライベートは有料なので後述の gitleaks で代替する。
- **dependabot_security_updates** は脆弱性アラートへの修正 PR。**既定 off。** §2 の定期更新とは別物で、こちらは緊急パッチ用。
- **default_workflow_permissions=read** — `write` のままだと全ワークフローが最初から書き込み権限を持つ。必要なジョブでだけ `permissions:` で足す。

**ブランチ保護（ruleset）**: main への直接 push を防ぎ、PR を経由させる。

```bash
gh api -X POST repos/$OWNER/$REPO/rulesets --input - <<'JSON'
{"name":"main","target":"branch","enforcement":"active",
 "conditions":{"ref_name":{"include":["~DEFAULT_BRANCH"],"exclude":[]}},
 "rules":[{"type":"deletion"},{"type":"non_fast_forward"},
          {"type":"pull_request","parameters":{
            "required_approving_review_count":0,
            "dismiss_stale_reviews_on_push":false,
            "require_code_owner_review":false,
            "require_last_push_approval":false,
            "required_review_thread_resolution":false}}]}
JSON
```

`deletion` / `non_fast_forward` はブランチ削除と force push の禁止で、**取り返しがつかなくなるのはこの 2 つ**。承認者が自分しかいないので `required_approving_review_count` は 0 —— **PR を経由させること自体**が目的。CI 必須にするなら `required_status_checks` を足す。bot が main に直接コミットする設計なら、その bot だけ `bypass_actors` で通す。

## 2. `.github/dependabot.yml`

```yaml
version: 2

# PR が毎週バラバラに飛んでくると読まなくなる。月 1 回・1 本にまとめる。
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: monthly
    # 公開直後のバージョンは踏まない。汚染されたリリースは数時間〜1 日で消される。
    # security updates に cooldown はかからないので緊急パッチは待たされない。
    cooldown:
      default-days: 7
    groups:
      npm:
        patterns: ["*"]
    open-pull-requests-limit: 1
    commit-message:
      prefix: chore
    labels: [dependencies]

  # Action をハッシュ固定すると、これが無い限り永久に古いままになる。
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: monthly
    groups:
      actions:
        patterns: ["*"]
    open-pull-requests-limit: 1
    commit-message:
      prefix: ci
    labels: [ci]
```

- **`github-actions` の ecosystem を忘れない。** ハッシュ固定とセットで使う。片方だけだと「安全に古い」状態になる。
- 使っている ecosystem は全部書く（`gomod` / `cargo` / `pip` / `terraform` / `docker`）。monorepo は `directory` を分ける。

## 3. `.npmrc`（Node の場合）

```
# 依存の install スクリプトを勝手に走らせない（allowScripts に無ければエラー）
strict-allow-scripts=true

# 公開から 7 日経っていないバージョンは入れない（npm 11.10.0 以降）
min-release-age=7
```

install 時に任意コードが走るのが汚染パッケージの侵入口。落ちたら**中身を読んでから** `npm approve-scripts <pkg>` / `npm deny-scripts <pkg>` で明示する（判断が `package.json` に残る）。CI は `npm ci --ignore-scripts`。
pnpm は `minimumReleaseAge`、yarn は `npmMinimalAgeGate`、bun は `minimumReleaseAge` が同等。

## 4. `.github/workflows/ci.yml`

```yaml
name: CI

on:
  pull_request:
    paths-ignore: ['*.md']
  push:
    branches: [main]
    paths-ignore: ['*.md']

# 続けて push したら古い実行を打ち切る
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 10   # 暴走したジョブを課金ごと止める
    steps:
      # Action はタグでなくコミットハッシュで固定する。タグは書き換え可能なので、
      # リポジトリが乗っ取られると v7 が別のコミットを指しうる。
      # 末尾のコメントがバージョンの目印で、Dependabot はこれを見て更新 PR を出す。
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # 言語バージョンは .tool-versions が唯一の真実。mise（ローカル）と
      # setup-*（CI）の両方が同じファイルを読む。
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

**シークレット検出**（プライベートリポジトリ、または二重化したいとき）— **AI は平気で鍵をベタ書きする**ので機械で止める:

```yaml
  secrets:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0   # 過去のコミットに埋まった鍵も拾う
      - uses: gitleaks/gitleaks-action@<commit-hash> # vX.Y.Z
```

## 5. `.tool-versions`

```
node 25.6.0
```

**唯一の真実。** ローカルは mise、CI は `setup-*` の `*-version-file` が同じファイルを読む。
`.nvmrc` は使わない（mise が既定で読まず、ローカルと CI がズレる）。

## 6. `AGENTS.md` と `CLAUDE.md`

`AGENTS.md` に開発ルールを書き、`CLAUDE.md` は `@AGENTS.md` の 1 行だけにする。AGENTS.md は Codex / Cursor / Copilot なども直接読む共通規格で、Claude Code は CLAUDE.md しか読まないので import で橋渡しする。**二重管理しない。**

書くのは**推測できないこと**だけ — ビルド / テスト / デプロイのコマンド、既定と違うコード規約、ブランチと PR の作法、環境の癖。
**コードを読めば分かることは書かない。** 長いほど守られなくなるので、1 行ごとに「消したら Claude は間違えるか?」を自問する。

## 7. その他のファイル

| ファイル | 目的 |
|---|---|
| `.gitignore` | `.env` を**必ず**含める |
| `.env.example` | 環境変数の一覧。値は入れない |
| `.github/pull_request_template.md` | セルフレビュー観点を毎回思い出す |
| `LICENSE` | 公開するなら必須。無いと全権利留保扱いで誰も使えない |
| `README.md` | 1 行説明 + セットアップ + CONCEPT.md へのリンク |
