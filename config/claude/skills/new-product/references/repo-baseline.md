# リポジトリ共通の足場（コピペ用）

新しいリポジトリを作ったら**最初の PR で全部入れる**。既存リポジトリにも同じものを適用する。
「後で入れる」と絶対に入らない。ここに無いものを足したくなったら、まず本ファイルに足してから使う。

## 0. まず確認する（GitHub 側の設定）

リポジトリ内のファイルでは設定できず、**API か Settings 画面でしか入らない**もの。新規作成のたびに走らせる。

```bash
OWNER=<owner>; REPO=<repo>

# 現状確認
gh api repos/$OWNER/$REPO --jq '.security_and_analysis'
gh api repos/$OWNER/$REPO/actions/permissions/workflow

# シークレット検出とプッシュ保護、Dependabot の自動セキュリティ修正を有効化
gh api -X PATCH repos/$OWNER/$REPO --input - <<'JSON'
{"security_and_analysis":{
  "secret_scanning":{"status":"enabled"},
  "secret_scanning_push_protection":{"status":"enabled"},
  "dependabot_security_updates":{"status":"enabled"}}}
JSON

# ワークフローの既定トークンを読み取りのみにし、Actions に PR 承認をさせない
gh api -X PUT repos/$OWNER/$REPO/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=false
```

- **secret scanning / push protection**: パブリックリポジトリは無料。push protection は**鍵を含む push をその場で拒否する**ので、事故ってから気づく代わりに事故らせない。プライベートリポジトリは有料プランが要るので、代わりに CI の gitleaks で担保する。
- **dependabot_security_updates**: 脆弱性アラートに対して修正 PR を自動で出す設定。**既定は off。** 後述の `dependabot.yml`（定期更新）とは別物で、こちらは緊急パッチ用。
- **default_workflow_permissions=read**: ワークフローの `GITHUB_TOKEN` の既定権限。`write` のままだと全ワークフローが最初から書き込み権限を持つ。書き込みが要るジョブだけ `permissions:` で明示的に足す。

## 1. `.github/dependabot.yml`

```yaml
version: 2

# 個人開発なので、PR が毎週バラバラに飛んでくると読まなくなる。
# 月 1 回・1 本にまとめて、まとめて見る。
updates:
  - package-ecosystem: npm
    directory: /
    schedule:
      interval: monthly
    # 公開直後のバージョンは踏まない。汚染されたリリースはたいてい数時間〜1 日で
    # レジストリから消えるので、待つだけで大半を避けられる。
    # security updates には cooldown がかからないので、緊急パッチは待たされない。
    cooldown:
      default-days: 7
    groups:
      npm:
        patterns: ["*"]
    open-pull-requests-limit: 1
    commit-message:
      prefix: chore
    labels: [dependencies]

  # Action をコミットハッシュで固定すると、これが無い限り永久に古いままになる。
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

- **`github-actions` の ecosystem を忘れない。** ハッシュ固定と Dependabot は必ずセットで使う。片方だけだと「安全に古い」状態になる。
- monorepo なら `directory` をパッケージごとに増やす。
- ecosystem は言語ごとに変える（`gomod` / `cargo` / `pip` / `terraform` / `docker`）。**使っているものは全部書く。**

## 2. `.npmrc`（Node の場合）

```
# 依存の install スクリプトを勝手に走らせない。
# package.json の allowScripts に無いものは警告ではなくエラーにする。
strict-allow-scripts=true

# 公開から 7 日経っていないバージョンは入れない（npm 11.10.0 以降）
min-release-age=7
```

- npm の install 時に任意コードが走るのが、汚染パッケージの典型的な侵入口。落ちたら**スクリプトの中身を読んでから** `npm approve-scripts <pkg>` / `npm deny-scripts <pkg>` で明示する。判断が `package.json` に残る。
- pnpm は `minimumReleaseAge`、yarn は `npmMinimalAgeGate`、bun は `minimumReleaseAge` が対応する設定。
- CI では `npm ci --ignore-scripts` を基本にする。

## 3. `.github/workflows/ci.yml`

```yaml
name: CI

on:
  pull_request:
    paths-ignore: ['*.md']
  push:
    branches: [main]
    paths-ignore: ['*.md']

# 同じブランチに続けて push したら、古い実行は打ち切る（無駄な課金と待ち時間を減らす）
concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

# 既定は読み取りだけ。書き込みが要るジョブでだけ足す
permissions:
  contents: read

jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 10   # 暴走したジョブを課金ごと止める
    steps:
      # Action はタグではなくコミットハッシュで固定する。
      # タグは書き換え可能なので、リポジトリが乗っ取られると v7 が別のコミットを指しうる。
      # 末尾のコメントがバージョンの目印で、Dependabot はこれを見て更新 PR を出す。
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1

      # 言語のバージョンは .tool-versions が唯一の真実。
      # mise（ローカル）と setup-*（CI）の両方がこのファイルをそのまま読む。
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

## 4. シークレット検出（プライベートリポジトリ、または二重化したいとき）

```yaml
  secrets:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
        with:
          fetch-depth: 0   # 履歴全体を見る（過去のコミットに埋まった鍵を拾う）
      - uses: gitleaks/gitleaks-action@<commit-hash> # vX.Y.Z
```

**AI は平気で鍵をベタ書きする。** 人間のレビューだけに頼らず、機械で止める。

## 5. `.tool-versions`

```
node 25.6.0
```

**唯一の真実。** ローカルは mise、CI は `setup-*` の `*-version-file` が同じファイルを読む。
`.nvmrc` は使わない（mise は既定で読まないため、ローカルと CI がズレる）。

## 6. `AGENTS.md` と `CLAUDE.md`

`AGENTS.md` に開発ルールを書き、`CLAUDE.md` は次の 1 行だけにする:

```markdown
@AGENTS.md
```

AGENTS.md は Codex / Cursor / Copilot / Gemini CLI などが直接読む共通規格。Claude Code は CLAUDE.md しか読まないので、import で橋渡しする。**二重管理しない。**

AGENTS.md に書くこと（**Claude がコードを読めば分かることは書かない**）:
- 推測できないコマンド（ビルド・テスト・デプロイ）
- 既定と違うコード規約
- ブランチ / PR / コミットメッセージの作法
- 環境の癖（必要な環境変数、ハマりどころ）

長いほど守られなくなる。1 行ごとに「これを消したら Claude は間違えるか?」を自問し、否なら消す。

## 7. その他のファイル

| ファイル | 目的 |
|---|---|
| `.github/pull_request_template.md` | セルフレビュー観点を毎回思い出すため |
| `.gitignore` | `.env` を**必ず**含める |
| `.env.example` | 必要な環境変数の一覧。値は入れない |
| `LICENSE` | 公開するなら必須。無いと「全権利留保」扱いで誰も使えない |
| `README.md` | 1 行説明 + セットアップ + CONCEPT.md へのリンク |

## 8. ブランチ保護（ruleset）

main への直接 push を防ぎ、PR を経由させる。

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

- `deletion` / `non_fast_forward` = ブランチの削除と force push を禁止。**取り返しがつかなくなるのはこの 2 つ。**
- 個人開発では承認者が自分しかいないので `required_approving_review_count` は 0。**PR を経由させること自体**が目的（差分を必ず一度目で見る）。
- CI の成功を必須にするなら `required_status_checks` ルールを足す。チェック名はワークフローの job 名と一致させる。
- bot が main に直接コミットする設計（日次バッチなど）を採るなら、その bot だけ `bypass_actors` で通す。
