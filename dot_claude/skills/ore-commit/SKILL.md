---
name: ore-commit
description: |
  Create well-structured, logically cohesive commits using Conventional Commits.
  Use whenever the user mentions: "commit", "コミット", "make a commit", "create a commit",
  "コミット作成", "stage changes", "prepare commit", "review uncommitted changes", "git commit",
  "変更をコミット", "未コミット", or any task involving organizing unstaged changes into commits.
  This skill enforces quality checks (linting, typing, tests), groups related changes,
  and ensures commit messages follow best practices.
version: 1.0.0
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git stash:*), Bash(git restore:*), Bash(git branch:*), Bash(gh pr list:*), Bash(make:*), Bash(uv run:*), Bash(pytest:*), Bash(ruff:*), Bash(python:*), Bash(python3:*), Read(**), Edit(**), Glob(**), Grep(**), TaskCreate, TaskUpdate, TaskList
---

# Smart Commit

**スマートコミット実行スキル**

このスキルは、未コミットのファイルを分析し、論理的に関連する変更を適切な粒度でコミットします。品質チェック、変更のグループ化、Conventional Commits 形式でのメッセージ作成を自動化します。

## Overview

Smart Commit は、Git リポジトリの変更を論理的にグループ化し、高品質なコミットを作成するためのスキルです。以下の特徴があります：

- **品質優先**: コミット前に必ず lint、型チェック、テストを実行
- **論理的グループ化**: 機能追加、バグ修正、リファクタリングなど、変更を論理的に分類
- **Conventional Commits**: 標準的なコミットメッセージ形式に準拠
- **段階的実行**: タスクリストで進捗を明確化
- **Lefthook 対応**: プレコミットフックとの統合

## When to Use

このスキルは以下の場合に自動的に起動します：

- ユーザーが「commit」「コミット」と言及した時
- 「変更をコミットして」「未コミットを確認」などの指示
- 「create a commit」「make a commit」などの英語表現
- 「git commit」コマンドの実行を示唆する発言
- 複数の変更を整理してコミットしたい時

**明示的に起動する場合:**
```
/ore-commit
/ore-commit path/to/directory
```

## Quick Start Workflow

最も簡潔な使い方：

1. **起動**: `/ore-commit` または「コミット作成して」と指示
2. **待つ**: スキルが自動的に品質チェック、変更分析、グループ化を実行
3. **レビュー**: 提示されたコミット内容（メッセージ・ファイル一覧）を確認
4. **承認**: 問題なければ承認してコミット作成
5. **完了**: 必要に応じて `git push` で反映

詳細な手順を知りたい場合は、[references/workflow.md](references/workflow.md) を参照してください。

## The 8-Step Process

Smart Commit は以下の8ステップで実行されます：

### Step 0: 対象ディレクトリの取得

- `$ARGUMENTS` から対象パスを取得
- 引数がない場合はユーザーに確認
- デフォルトはカレントディレクトリ

### Step 0.5: ブランチ保護チェック（必須）

コミット前に現在のブランチを確認し、保護対象ブランチへのコミットを防ぎます。

```bash
git branch --show-current
```

**保護対象ブランチ（コミット禁止）**:
- `main` / `master`
- `develop`（完全一致）
- `develop` で始まるブランチ（例: `develop_hoge`, `develop-feature`, `develop/xxx`）

判定ロジック：
```bash
BRANCH=$(git branch --show-current)
if echo "$BRANCH" | grep -qE '^(main|master|develop)$|^develop[_/.-]'; then
  echo "⛔ コミット禁止ブランチです: $BRANCH"
  echo "作業ブランチに切り替えてから実行してください。"
  exit 1
fi
echo "✅ ブランチ確認OK: $BRANCH"
```

保護対象ブランチだった場合は**即座に中止**し、ユーザーに警告します。コミットは一切行いません。

### Step 0.7: PR ステータスチェック

現在のブランチに対する PR の状態を確認し、誤ったブランチへのコミットを防ぎます。

**① マージ済み PR チェック**
```bash
BRANCH=$(git branch --show-current)
gh pr list --head "$BRANCH" --state merged --json number,title,url
```

結果がある場合 → **即座に中止**：
```
⛔ このブランチの PR はマージ済みです。
   新しいブランチを作成して作業してください。
   例: git checkout -b feature/new-task
```

**② オープン PR チェック**
```bash
gh pr list --head "$BRANCH" --state open --json number,title,url
```

結果がある場合 → **ユーザーに確認**：
```
⚠️ このブランチには既に PR があります：
   #N - {title}
   {url}

   追加コミットしますか？（y/N）
```
- y → Step 1 へ継続
- N（デフォルト）→ 中止

---

### Step 1: 作業計画の作成

- TaskCreate で必要な作業をタスク化
- 品質チェック、コード整理、コミット準備の各ステップを明確化
- 進捗の可視化

### Step 2: 品質チェック（必須）

コミット前に以下を**この順序で**実行：

#### 2.1 フォーマット実行
```bash
uv run ruff format {対象パス}
# または
make format
```

#### 2.2 フォーマット検証
```bash
uv run ruff format --check {対象パス}
```
- すべてのファイルがフォーマット済みであることを確認
- エラーがある場合は再度フォーマットを実行

#### 2.3 リントチェック（自動修正付き）
```bash
uv run ruff check --fix {対象パス}
```
- 自動修正可能なエラー（未使用import、import順序など）を修正

#### 2.4 リントチェック（最終確認）【重要】
```bash
uv run ruff check {対象パス}
```
- **`--fix`なしで実行**してエラーを確実に検出
- 特にE501（行が長すぎる）エラーは自動修正できないため、この段階で検出される

#### 2.5 型チェック
```bash
uv run mypy {対象パス}
```

#### 2.6 テスト実行
```bash
pytest {対象パス}
```

プロジェクト固有のコマンド（Makefile、package.json 等）を確認して実行します。

**重要**: 品質チェックが失敗した場合、コミットは作成しません。エラーを修正してから再度実行します。

**E501エラーの扱い**:

E501エラー（行が長すぎる）が検出された場合：

1. エラー詳細をユーザーに通知：
   - ファイル名と行番号
   - 現在の文字数と制限値
   - 該当コード

2. 修正方法を提示：
   ```python
   # 悪い例（124文字）
   logger.info(f"long message with {var1} and {var2} and more")

   # 良い例（分割）
   logger.info(
       f"long message with {var1} "
       f"and {var2} and more"
   )
   ```

3. ユーザーが修正するまで待機

**自動修正の記録**: `ruff format`や`ruff check --fix`で自動修正があった場合、修正後に`git diff`で差分を取得し、Step 5のレビュー時に提示するために保持しておく。

### Step 3: 未コミット状況確認

```bash
git status {対象ディレクトリ}       # 変更されたファイルをリスト
git diff {対象ディレクトリ} --stat  # 変更の統計情報
git diff {対象ディレクトリ}         # 具体的な変更内容
```

変更内容を詳細に分析し、どのファイルが何のために変更されたかを理解します。

### Step 4: 変更内容のグループ化

変更を以下のカテゴリで論理的に分類：

- **機能追加** (feat): 新しい機能の追加
- **バグ修正** (fix): バグの修正
- **リファクタリング** (refactor): 動作を変えない内部改善
- **テスト** (test): テストの追加・修正
- **ドキュメント** (docs): ドキュメントの更新
- **スタイル修正** (style): フォーマット、空白等
- **その他** (chore): ビルド設定、依存関係等

関連するファイルをまとめてグループ化します。不要なデバッグコード・コメントがあれば削除します。

### Step 5: コミット内容のレビュー

**コミットを作成する前に、品質チェック結果とコミット内容をユーザーに提示してレビューを受けます：**

まず、現在のブランチと品質チェックの結果を表示：

- **現在のブランチ**: `{git branch --show-current の結果}`

- **実行したチェック**: format, lint, type check, test など
- **各チェックの結果**: ✅ Pass / ❌ Fail
- **実行コマンド**: 実際に実行したコマンド
- **サマリー**: すべてのチェックが通過したか

**E501エラーが検出された場合**:
- ファイル名、行番号、文字数を通知
- 行を分割する修正例を提示
- ユーザーが修正するまで待機し、コミットは作成しない

自動修正があった場合は、その差分も表示：

- **自動修正の内容**（ruff format 等による変更があった場合のみ）:
  - 修正されたファイル一覧
  - `git diff` による具体的な変更内容

ユーザーが自動修正内容に問題がないことを確認してから次に進む。

次に、各グループについて以下を表示：

- **コミットメッセージ（案）**: `feat(auth): add user authentication`
- **含まれるファイル一覧**:
  - `src/auth/login.py`
  - `src/auth/token.py`
  - `src/auth/utils.py`
- **変更の概要**: 追加・修正・削除された行数や主な変更点

ユーザーが内容を確認し、承認したらコミットを作成します。修正が必要な場合は、コミットメッセージやファイル選択を調整してから再度レビューします。

### Step 6: 適切な粒度でコミット

ユーザーの承認を得た後、各グループごとに独立したコミットを作成：

```bash
git add <関連ファイル>
git commit -m "<type>(<scope>): <subject>"
```

**原則**:
- 1コミット = 1つの論理的変更
- コミットメッセージは**必ず1行かつ英語**
- Conventional Commits 形式に準拠

### Step 7: 品質確保

- **Lefthook確認**: プレコミットフックが正常に実行されることを確認
- **コミットメッセージ検証**: メッセージ形式が正しいことを確認
- **最終確認**: `git status` でクリーンな状態を確認

### Step 8: プロジェクトメモリ更新検討

作業中に発見した技術的課題・解決方法を CLAUDE.md に追加検討：

- 新しいエラーパターン
- ライブラリ使用方法
- 設定の注意点
- 将来の開発効率化につながる知見

**詳細は [references/workflow.md](references/workflow.md) を参照してください。**

## Commit Message Format

Conventional Commits 形式を使用します：

```
<type>(<scope>): <subject>
```

### 主要なタイプ

| Type | 説明 | 例 |
|------|------|-----|
| `feat` | 新機能の追加 | `feat(auth): add user authentication` |
| `fix` | バグ修正 | `fix(api): fix response header issue` |
| `refactor` | リファクタリング | `refactor(utils): organize common utility functions` |
| `test` | テストの追加・修正 | `test: add unit tests for authentication` |
| `docs` | ドキュメント更新 | `docs: update API documentation` |
| `style` | フォーマット・空白等 | `style: fix indentation in config file` |
| `chore` | ビルド設定・依存関係等 | `chore: update development environment config` |

### ルール

- **1行のみ**: 説明は1行で完結させる
- **英語**: コミットメッセージは必ず英語で記述
- **現在形**: 動詞は現在形を使用（"add" not "added"）
- **小文字**: subject は小文字で始める
- **ピリオド不要**: 末尾にピリオドを付けない
- **簡潔に**: 50文字以内を目安にする

**詳細は [references/conventional-commits.md](references/conventional-commits.md) を参照してください。**

## Critical Requirements

このスキルを使用する際の必須要件：

### 1. 品質チェックの実行

**絶対にスキップしないこと**:
- Linter/Formatter の実行
- 型チェックの実行（該当する場合）
- テストの実行

品質チェックが失敗した場合は、エラーを修正してから再度実行します。

### 2. コミットメッセージの形式

- Conventional Commits 形式に厳密に従う
- 必ず1行かつ英語で記述
- type と subject を明確に記述

### 3. 論理的グループ化

- 関連する変更をまとめる
- 無関係な変更を同じコミットに含めない
- 1コミット = 1つの論理的変更

### 4. Lefthook との統合

- プレコミットフックが設定されている場合、正常に実行されることを確認
- フックが失敗した場合、原因を調査して修正
- `--no-verify` でスキップしない

### 5. パス指定

- 特殊文字が含まれる場合は適切にエスケープ
- 対象ディレクトリを明確に指定
- サブディレクトリ単位でのコミットもサポート

## Key Tools Used

このスキルで使用する主要ツール：

### Git コマンド

- `git status`: 変更されたファイルの確認
- `git diff`: 変更内容の詳細確認
- `git add`: ステージング
- `git commit`: コミット作成

### 品質チェックツール

- `make lint`, `make test`: プロジェクト固有のコマンド
- `uv run ruff format`: Python フォーマッター
- `uv run ruff check`: Python リンター
- `pytest`: Python テストフレームワーク

### タスク管理

- `TaskCreate`: タスクの作成
- `TaskUpdate`: タスクの更新
- `TaskList`: タスクの一覧表示

## Error Handling

### 品質チェック失敗時

1. エラーメッセージを確認
2. 該当ファイルを修正
3. 再度品質チェックを実行
4. パスするまで繰り返す

### コミット失敗時

1. エラーメッセージを確認（lefthook、pre-commit 等）
2. 問題を修正
3. 新しいコミットを作成（`--amend` は使用しない）

### 変更が多すぎる場合

1. 論理的なグループに分割
2. 各グループを個別にコミット
3. 必要に応じて複数回実行

## Examples

### 単一機能の追加

```bash
# ユーザー: "認証機能を追加したのでコミットして"
# → スキルが自動実行:

✅ 品質チェック完了
✅ 変更内容を分析
✅ コミット作成: feat(auth): add user authentication
```

### 複数の変更の整理

```bash
# ユーザー: "複数の修正をしたのでコミットして"
# → スキルが自動実行:

✅ 品質チェック完了
✅ 変更内容を分析してグループ化
✅ コミット1: feat(api): add new endpoint for user profile
✅ コミット2: fix(auth): fix token expiration handling
✅ コミット3: refactor(utils): simplify date formatting logic
✅ コミット4: test: add tests for new API endpoint
```

### サブディレクトリのみコミット

```bash
# ユーザー: "/ore-commit src/auth"
# → 指定ディレクトリのみを対象に実行
```

## Best Practices

### Do's ✅

- 品質チェックを必ず実行
- 変更を論理的にグループ化
- Conventional Commits 形式を厳守
- コミットメッセージを簡潔に保つ
- Lefthook が正常に動作することを確認
- 作業中に得た知見を CLAUDE.md に記録

### Don'ts ❌

- 品質チェックをスキップしない
- 無関係な変更を同じコミットに含めない
- コミットメッセージを日本語で書かない
- 複数行のコミットメッセージを作成しない
- `--no-verify` でフックをスキップしない
- デバッグコードをコミットしない

## Advanced Usage

### 特定のファイルのみコミット

対象ディレクトリを指定して実行：

```
/ore-commit src/components/Button.tsx
```

### 品質チェックのカスタマイズ

プロジェクトの Makefile や設定ファイルを確認して、適切なコマンドを実行します：

- `make lint`: Lint実行
- `make test`: テスト実行
- `make format`: フォーマット実行

### 複数の論理的変更

複数の独立した変更がある場合、それぞれを個別のコミットとして作成します。

## Troubleshooting

### 品質チェックが失敗する

- エラーメッセージを確認
- 該当ファイルを修正
- 再度チェックを実行

### Lefthook が失敗する

- `.lefthook.yml` の設定を確認
- エラーの原因を調査
- 問題を修正してから再度コミット

### 変更が認識されない

- `git status` で状態を確認
- ファイルが `.gitignore` に含まれていないか確認
- 対象ディレクトリのパスが正しいか確認

## References

詳細な情報は以下を参照してください：

- **[Workflow](references/workflow.md)**: 7ステップの詳細ワークフロー
- **[Conventional Commits](references/conventional-commits.md)**: コミットメッセージ形式の詳細ガイド

## Notes

- このスキルは Git リポジトリ内でのみ動作します
- 品質チェックツールがインストールされていることを前提とします
- Lefthook の設定がある場合、自動的に統合されます
- タスクリストで進捗を可視化します

---

**動作を開始します...**
