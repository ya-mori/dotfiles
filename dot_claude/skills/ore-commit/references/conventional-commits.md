# Conventional Commits - 詳細ガイド

このドキュメントでは、Conventional Commits 形式について詳しく説明します。

## 概要

Conventional Commits は、コミットメッセージに構造化された形式を提供する仕様です。人間が読みやすく、機械が解析しやすい形式になっています。

**公式サイト**: https://www.conventionalcommits.org/

## 基本形式

```
<type>(<scope>): <subject>
```

### 構成要素

- **type** (必須): 変更のカテゴリ
- **scope** (省略可): 影響範囲
- **subject** (必須): 変更の簡潔な説明

### 例

```
feat(auth): add user authentication
fix(api): fix response header issue
refactor(utils): organize common utility functions
```

---

## Type（変更のカテゴリ）

### 主要なタイプ

#### `feat` - 機能追加

新しい機能の追加を示します。

**使用例**:
```
feat(auth): add user authentication
feat(api): add new endpoint for user profile
feat(ui): add dark mode toggle
feat: add email notification system
```

**典型的な変更**:
- 新しい機能の実装
- 新しい API エンドポイントの追加
- 新しい UI コンポーネントの追加
- 新しいユーティリティ関数の追加

---

#### `fix` - バグ修正

バグや問題の修正を示します。

**使用例**:
```
fix(api): fix response header issue
fix(auth): fix token expiration handling
fix(ui): fix button alignment on mobile
fix: fix memory leak in background service
```

**典型的な変更**:
- バグの修正
- エラーハンドリングの改善
- パフォーマンス問題の修正
- セキュリティ脆弱性の修正

---

#### `refactor` - リファクタリング

動作を変えずに内部構造を改善する変更を示します。

**使用例**:
```
refactor(utils): organize common utility functions
refactor(auth): simplify token validation logic
refactor: extract common code into helper function
refactor(api): split large controller into modules
```

**典型的な変更**:
- コードの整理
- 関数の分割・統合
- 変数名の変更
- 重複コードの削除
- パフォーマンス改善（動作は変わらない）

**重要**: リファクタリングは動作を変えないことが前提です。動作が変わる場合は `feat` または `fix` を使用します。

---

#### `test` - テスト関連

テストの追加・修正を示します。

**使用例**:
```
test: add unit tests for authentication
test(api): add integration tests for user endpoint
test: update test fixtures
test(auth): fix flaky test in token validation
```

**典型的な変更**:
- 新しいテストの追加
- 既存テストの修正
- テストデータの更新
- テストカバレッジの向上

---

#### `docs` - ドキュメント更新

ドキュメントのみの変更を示します。

**使用例**:
```
docs: update API documentation
docs(readme): add installation instructions
docs: fix typo in contributing guide
docs(api): add examples for authentication endpoint
```

**典型的な変更**:
- README の更新
- API ドキュメントの更新
- コメントの追加・修正
- 使用例の追加

---

#### `style` - スタイル修正

コードの動作に影響しないフォーマット変更を示します。

**使用例**:
```
style: fix indentation in config file
style(api): format code with ruff
style: add missing semicolons
style: organize imports
```

**典型的な変更**:
- インデント修正
- 空白の調整
- セミコロンの追加・削除
- インポートの整理
- コードフォーマッターの適用

**重要**: ロジックや動作には影響しない変更のみです。

---

#### `chore` - その他の変更

ビルドプロセス、ツール設定、依存関係などの変更を示します。

**使用例**:
```
chore: update development environment config
chore(deps): update dependencies
chore: add pre-commit hooks
chore(ci): update GitHub Actions workflow
```

**典型的な変更**:
- 依存関係の更新
- ビルド設定の変更
- CI/CD の設定
- 開発ツールの設定
- `.gitignore` の更新

---

### その他のタイプ（プロジェクトによる）

プロジェクトによっては以下のタイプも使用されます：

#### `perf` - パフォーマンス改善

**使用例**:
```
perf(api): optimize database query
perf: reduce memory usage in image processing
```

#### `ci` - CI/CD 関連

**使用例**:
```
ci: add automated testing workflow
ci: update deployment pipeline
```

#### `build` - ビルドシステム

**使用例**:
```
build: update webpack configuration
build: optimize production build
```

#### `revert` - コミットの取り消し

**使用例**:
```
revert: revert "feat(auth): add user authentication"
```

---

## Scope（影響範囲）

Scope はコミットが影響する範囲を示します。省略可能ですが、指定することで変更箇所が明確になります。

### 一般的な Scope の例

- **機能・モジュール名**:
  ```
  feat(auth): add user authentication
  fix(api): fix response header issue
  refactor(utils): organize common utility functions
  ```

- **コンポーネント名**:
  ```
  feat(button): add loading state
  fix(modal): fix overlay z-index
  ```

- **レイヤー名**:
  ```
  feat(backend): add new API endpoint
  fix(frontend): fix rendering issue
  ```

- **ファイル名・ディレクトリ名**:
  ```
  docs(readme): update installation instructions
  chore(ci): update GitHub Actions
  ```

### Scope の命名規則

- **小文字を使用**: `auth` (○), `Auth` (×)
- **簡潔に**: `authentication` より `auth`
- **一貫性**: プロジェクト内で統一された命名を使用

### Scope を省略する場合

以下の場合は Scope を省略できます：

- **プロジェクト全体に影響する変更**:
  ```
  chore: update dependencies
  docs: update contributing guide
  ```

- **特定のモジュールに限定されない変更**:
  ```
  style: format all files with ruff
  test: add end-to-end tests
  ```

---

## Subject（変更の説明）

Subject は変更内容の簡潔な説明です。

### ルール

1. **現在形の動詞で始める**
   - ○ `add user authentication`
   - × `added user authentication`
   - × `adding user authentication`

2. **小文字で始める**
   - ○ `add user authentication`
   - × `Add user authentication`

3. **末尾にピリオドを付けない**
   - ○ `add user authentication`
   - × `add user authentication.`

4. **簡潔に（50文字以内を目安）**
   - ○ `add user authentication`
   - × `add a new user authentication system with JWT tokens and refresh token support`

5. **命令形を使用**
   - "If applied, this commit will **<subject>**" の形で読めるように
   - 例: "If applied, this commit will **add user authentication**"

### 良い Subject の例

```
add user authentication
fix response header issue
organize common utility functions
update API documentation
format code with ruff
update development environment config
```

### 悪い Subject の例

```
Added user authentication          # 過去形 (×)
Add User Authentication            # 大文字で始まる (×)
add user authentication.           # 末尾にピリオド (×)
authentication                     # 動詞がない (×)
add a new user authentication system with JWT tokens  # 長すぎる (×)
```

---

## 実例集

### 機能追加の例

```
feat(auth): add user authentication
feat(auth): add password reset functionality
feat(api): add new endpoint for user profile
feat(ui): add dark mode toggle
feat(notification): add email notification system
feat(search): add full-text search capability
```

### バグ修正の例

```
fix(api): fix response header issue
fix(auth): fix token expiration handling
fix(ui): fix button alignment on mobile
fix(db): fix connection pool leak
fix(validation): fix email validation regex
fix: fix memory leak in background service
```

### リファクタリングの例

```
refactor(utils): organize common utility functions
refactor(auth): simplify token validation logic
refactor: extract common code into helper function
refactor(api): split large controller into modules
refactor(db): use repository pattern
refactor: remove deprecated code
```

### テスト追加の例

```
test: add unit tests for authentication
test(api): add integration tests for user endpoint
test: update test fixtures
test(auth): fix flaky test in token validation
test: increase test coverage for utils
test(e2e): add end-to-end tests for checkout flow
```

### ドキュメント更新の例

```
docs: update API documentation
docs(readme): add installation instructions
docs: fix typo in contributing guide
docs(api): add examples for authentication endpoint
docs: update changelog for version 1.2.0
docs(architecture): add system architecture diagram
```

### スタイル修正の例

```
style: fix indentation in config file
style(api): format code with ruff
style: organize imports
style: remove trailing whitespace
style: apply prettier formatting
```

### その他の例

```
chore: update development environment config
chore(deps): update dependencies
chore: add pre-commit hooks
chore(ci): update GitHub Actions workflow
chore: update .gitignore
chore(release): bump version to 1.2.0
```

---

## 複数の変更がある場合

### 原則: 1コミット = 1つの論理的変更

関連する変更は1つのコミットにまとめ、無関係な変更は別のコミットに分割します。

### 例: 機能追加とテスト

**良い例（分割）**:
```
commit 1: feat(auth): add user authentication
commit 2: test(auth): add unit tests for authentication
```

これにより、機能追加とテスト追加を独立してレビューできます。

**悪い例（混在）**:
```
commit 1: feat(auth): add user authentication and tests
```

機能とテストを同じコミットに含めると、レビューや履歴追跡が困難になります。

### 例: バグ修正とリファクタリング

**良い例（分割）**:
```
commit 1: fix(api): fix response header issue
commit 2: refactor(api): simplify response handling logic
```

**悪い例（混在）**:
```
commit 1: fix and refactor API response handling
```

### 例: 複数の独立した機能

**良い例（分割）**:
```
commit 1: feat(auth): add user authentication
commit 2: feat(api): add new endpoint for user profile
commit 3: feat(ui): add dark mode toggle
```

**悪い例（混在）**:
```
commit 1: feat: add multiple features
```

---

## ベストプラクティス

### 1. 意味のある単位でコミット

- 機能ごと、バグ修正ごとに独立したコミットを作成
- コミット単位でレビューできるようにする

### 2. コミットメッセージで「なぜ」を説明

Subject で「何を」を説明し、必要に応じてボディで「なぜ」を説明します（Smart Commit では通常1行のみですが、必要に応じて詳細を追加できます）。

**例**:
```
fix(auth): fix token expiration handling

Tokens were expiring 1 hour earlier than expected due to
timezone offset not being considered. Updated to use UTC
consistently.
```

### 3. 一貫性を保つ

- プロジェクト内で同じ type を使用
- Scope の命名を統一
- チーム内で規約を共有

### 4. コミット前に確認

- Conventional Commits 形式に準拠しているか
- 1行で記述されているか
- 英語で記述されているか
- タイポがないか

### 5. レビュアーを意識

- レビュアーが理解しやすいメッセージを書く
- 変更の意図が明確に伝わるようにする

---

## Conventional Commits のメリット

### 1. 自動化しやすい

- セマンティックバージョニングの自動生成
- チェンジログの自動生成
- CI/CD での自動化

### 2. 履歴が読みやすい

- `git log` でタイプごとにフィルタリング可能
- 変更の種類が一目でわかる

### 3. レビューしやすい

- 変更の目的が明確
- 影響範囲が把握しやすい

### 4. 標準化

- プロジェクト間で一貫した形式
- オンボーディングが容易

---

## ツールとの連携

### Commitlint

コミットメッセージの形式を検証：

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
```

### Lefthook

プレコミットフックでコミットメッセージを検証：

```yaml
# lefthook.yml
commit-msg:
  commands:
    commitlint:
      run: npx commitlint --edit
```

### Semantic Release

Conventional Commits からバージョン番号を自動生成：

```bash
npm install --save-dev semantic-release
```

---

## まとめ

Conventional Commits は、コミットメッセージに構造と一貫性をもたらします。以下のポイントを押さえることで、高品質なコミット履歴を維持できます：

- **形式**: `<type>(<scope>): <subject>`
- **type**: feat, fix, refactor, test, docs, style, chore
- **subject**: 現在形の動詞、小文字で始める、ピリオドなし、50文字以内
- **1コミット = 1つの論理的変更**

Smart Commit スキルは、これらのルールを自動的に適用し、高品質なコミットを作成します。

---

**関連ドキュメント**:
- [Workflow](workflow.md): 7ステップの詳細ワークフロー
- [SKILL.md](../SKILL.md): スキルの概要
- [公式仕様](https://www.conventionalcommits.org/): Conventional Commits 公式サイト
