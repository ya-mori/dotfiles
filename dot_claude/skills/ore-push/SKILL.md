---
name: ore-push
description: |
  commit済みの変更をremoteリポジトリにpushしてPRを作成する。
  /ore-push または「pushして」「PRを作って」「プッシュして」「プルリクを作って」「PR作成」
  と言われたら必ずこのスキルを使う。
  コミット済みの変更をリモートへ送る作業が必要な時は常にこのスキルを起動すること。
version: 1.3.0
allowed-tools: Bash(git branch:*), Bash(git log:*), Bash(git remote:*), Bash(git push:*), Bash(gh pr create:*), Bash(gh pr list:*), Bash(gh pr edit:*), Bash(gh pr view:*), Bash(gh repo view:*), Bash(ls .github:*), Bash(find .github:*), Bash(git diff:*), Bash(git merge-base:*), Bash(git rev-parse:*), Bash(rm -f .ai_workspace/claude/tmp/:*), Read(**), Write(**), TaskCreate, TaskUpdate, TaskList
---

# スマートプッシュ実行

commit済みの変更をremoteリポジトリにpushし、PRを作成します。
**重要**: PR本文はコミット履歴・差分を分析して自動生成し、ユーザーの承認を得てから作成します。

## 実行手順

### フェーズ1: 状況確認

0. **タスクリストの作成**
   - 作業開始時に `{yyyymmdd}-{word}` 形式（例: `20260310-push`）のタスクディレクトリを決定する
   - このディレクトリパスはフェーズ4でも使用するため変数として保持する
   - TaskCreate で以下のタスクを作成して作業を可視化する:
     ```
     - [ ] フェーズ1: 状況確認（ブランチ・差分・テンプレート）
     - [ ] フェーズ2: PR草稿の自動生成
     - [ ] フェーズ3: ユーザー承認
     - [ ] フェーズ4: Push & PR作成/更新
     ```

1. **現在のブランチ確認**
   - `git branch --show-current` で現在のブランチ名を取得
   - main/master/デフォルトブランチへの直接pushは中止してユーザーに警告する

1.5. **既存 PR チェック（重複 PR 防止）**

   ```bash
   BRANCH=$(git branch --show-current)
   gh pr list --head "$BRANCH" --state all --json number,title,state,url
   ```

   既存 PR がある場合 → **即座に中止**：
   ```
   ⛔ このブランチには既に PR が存在します：
      #N - {title} [{state}]
      {url}

      1ブランチ = 1PR の原則により新しい PR は作成できません。
      既存 PR を更新するか、新しいブランチを作成してください。
   ```

   PR がない場合 → Step 2 へ継続

2. **デフォルトブランチとリモートを確認**
   ```bash
   gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'
   git remote -v
   ```

3. **ブランチの変更内容を分析**
   - デフォルトブランチとの分岐点を特定:
     ```bash
     git merge-base HEAD {デフォルトブランチ名}
     ```
   - 分岐後の全コミットを取得:
     ```bash
     git log {merge-base}..HEAD --oneline
     ```
   - 変更の概要を取得:
     ```bash
     git diff {merge-base}..HEAD --stat
     git diff {merge-base}..HEAD | head -300
     ```

4. **PRテンプレートの確認**（以下の優先順で検索）
   1. `.github/pull_request_template.md`
   2. `.github/PULL_REQUEST_TEMPLATE.md`
   3. `.github/PULL_REQUEST_TEMPLATE/` 内の `*.md` ファイル
   4. `docs/pull_request_template.md`
   5. `PULL_REQUEST_TEMPLATE.md`（ルート）

   フェーズ1完了時に TaskUpdate でタスクを completed にする。

### フェーズ2: PR草稿の自動生成

分析した情報をもとに、**PR タイトルと本文を自動生成**します。

**PR タイトルの生成方針**:
- コミットが1件 → そのコミットメッセージから生成
- コミットが複数件 → 変更の主旨を要約して生成
- 形式: `{type}: {summary in English}`（例: `feat: add user authentication`）
- **言語ルール**: PR タイトルは必ず英語で記述する（smart-commit のコミットメッセージと統一）

**PR 本文の生成方針**:

テンプレートが存在する場合:
- テンプレートの各セクションをコミット・差分情報をもとに埋める
- 埋められないセクションはそのまま残す（ユーザーが後で編集できるように）
- テンプレートに「変更の背景・理由」「デプロイ手順」に相当するセクションが存在しない場合は、本文末尾に補完して追加する

テンプレートが存在しない場合:
- 以下の構造で本文を生成する:

```markdown
## 概要

{変更の目的と背景を1〜3文で説明}

## 変更内容

{変更した主な内容をリスト形式で箇条書き}

## 変更の背景・理由

{なぜこの変更が必要だったか（課題・要求・バグ・改善要求等）を記述}

## デプロイ手順

{デプロイ時に必要な手順・注意事項をリスト形式で記述}
- 特別な手順がない場合は「通常デプロイのみ」と記載

## 確認事項

- [ ] {動作確認内容}
- [ ] テストの追加・更新
```

**各セクションの記述ガイド**:
- **変更の背景・理由**: コミットメッセージ・PRタイトル・差分から「なぜ変更が必要だったか」を推論して記述する。バグ修正なら発生していた問題、機能追加なら解決したい課題、リファクタなら改善の動機を明記する
- **デプロイ手順**: DBマイグレーション・設定変更・環境変数追加・キャッシュクリアなど、デプロイ時に影響しそうな変更がある場合はリストアップする。特別な手順がない場合でも「通常デプロイのみ」と明記して省略しない

フェーズ2完了時に TaskUpdate でタスクを completed にする。

### フェーズ3: ユーザー承認

生成したPR草稿をユーザーに提示し、**必ず承認を得てから次のフェーズに進む**。

以下の形式でユーザーに表示する（コードブロックではなく通常テキストで表示してMarkdownをレンダリングさせる）:

---
PR草稿を生成しました。内容を確認してください。

**マージ:** {現在のブランチ名} → {デフォルトブランチ名}

**タイトル:** {生成したタイトル}

**本文:**

{生成した本文（Markdownとしてそのまま出力）}

---

**既存PRがない場合の選択肢**:
1. 承認する（Open PR として作成）
2. 承認する（Draft PR として作成）
3. 修正内容を伝える → 草稿を修正して再提示
4. キャンセル → 中止

**既存PRがある場合の選択肢**:
1. 承認する（Open のまま更新）
2. 承認する（Draft に変更して更新）
3. 修正内容を伝える → 草稿を修正して再提示
4. キャンセル → 中止

ユーザーから修正依頼があった場合は草稿を修正して再提示する。承認されるまでPR作成・更新は行わない。

### フェーズ4: Push & PR作成/更新

ユーザーが承認したら実行する。

1. **Push実行**
   - upstream 設定の有無を確認:
     ```bash
     git rev-parse --abbrev-ref @{u} 2>/dev/null
     ```
   - upstream 未設定（初回）: `git push -u origin {ブランチ名}`
   - upstream 設定済み: `git push origin {ブランチ名}`
   - エラー時は適切に対処・報告

2. **既存PR確認・更新判断**
   - `gh pr list --head {ブランチ名} --json number,url,title,body` で既存PRを確認
   - **既存PRがある場合（PR更新）**:
     - PR本文を一時ファイルに書き出す:
       ```
       # Write ツールで以下パスに PR 本文を作成:
       .ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/pr_body.md
       ```
     - タイトルと本文を更新:
       ```bash
       gh pr edit {number} \
         --title "{承認済みタイトル}" \
         --body-file .ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/pr_body.md
       ```
     - ドラフトに変更する場合は追加で:
       ```bash
       gh pr edit {number} --draft
       ```
     - 一時ファイルを削除:
       ```bash
       rm -f .ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/pr_body.md
       ```
     - PR URLを取得して表示:
       ```bash
       gh pr view {number} --json url --jq '.url'
       ```
   - **既存PRがない場合（PR新規作成）**:
     - PR本文を一時ファイルに書き出す:
       ```
       # Write ツールで以下パスに PR 本文を作成:
       .ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/pr_body.md
       ```
     - 通常PRの場合:
       ```bash
       gh pr create \
         --title "{承認済みタイトル}" \
         --body-file .ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/pr_body.md \
         --base {デフォルトブランチ名}
       ```
     - ドラフトPRの場合:
       ```bash
       gh pr create \
         --title "{承認済みタイトル}" \
         --body-file .ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/pr_body.md \
         --base {デフォルトブランチ名} \
         --draft
       ```
     - PR作成後、一時ファイルを削除:
       ```bash
       rm -f .ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/pr_body.md
       ```
     - PR URLを取得:
       ```bash
       gh pr view --head {ブランチ名} --json url --jq '.url'
       ```

   フェーズ4完了時に TaskUpdate で全タスクを completed にする。

3. **完了メッセージの表示**
   - 以下の形式で完了を通知する（URLはクリッカブルリンクとして表示）:

   ---
   PR の作成/更新が完了しました。

   **マージ:** {現在のブランチ名} → {デフォルトブランチ名}

   **PR リンク:** {PR URL}

   ---

## 注意事項

- **デフォルトブランチへの直接pushは行わない** — 検出した場合は即座に中止
- ユーザーが承認する前にPRを作成・更新しない
- GitHub CLI（gh）がない場合はPR作成をスキップし、pushのみ実行
- 複数のPRテンプレートがある場合は最初に見つかったものを使用
- PR本文の一時ファイルは必ず `.ai_workspace/claude/tmp/{yyyymmdd-HHMMSS}/` 以下に作成し、`tasks/` や `~/` には作成しない

**動作を開始します...**
