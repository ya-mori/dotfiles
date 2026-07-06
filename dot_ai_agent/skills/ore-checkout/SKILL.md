---
name: ore-checkout
description: |
  最新の develop ブランチから新しい作業ブランチを作成してチェックアウトするスキル。
  現在の未コミット変更（git diff / git status）を分析して、作業内容にふさわしいブランチ名候補を
  自動生成し、ユーザーが番号で選べるように提示する。未コミット変更の stash/pop も自動処理する。

  以下のいずれかでトリガーすること:
  - /ore-checkout
  - 「チェックアウトして」「新しいブランチに切り替えて」「ブランチを作って」
  - 「develop から切って」「新ブランチを作成して」「ore-checkout」
  - 新しい作業を始めるときにブランチを切りたいと明示した場合
version: 1.0.0
allowed-tools: Bash(git fetch/checkout/stash/status/diff/log/branch/rev-parse), TaskCreate, TaskUpdate
---

# ore-checkout — スマートブランチ作成スキル

最新の develop ブランチをベースに、現在の作業内容から適切な名前の新ブランチを作成する。

---

## Phase 1: 現状確認

以下を並列で取得する:

```bash
git status --short
git diff HEAD
git branch --show-current
git rev-parse --verify origin/develop 2>/dev/null && echo "OK" || echo "NOT_FOUND"
```

確認事項:
- 未コミット変更の有無と内容
- 現在のブランチ名
- `origin/develop` が存在するか

---

## Phase 2: 最新 develop を取得

```bash
git fetch origin develop
```

失敗した場合（オフライン等）:
- ローカルの `develop` ブランチが存在するか確認
- 存在すれば「ローカルの develop を使います」と伝えて続行
- どちらも存在しない場合はエラーメッセージを表示して中断

---

## Phase 3: ブランチ名候補を生成

### 命名ルール

| 項目 | 内容 |
|------|------|
| 形式 | `{type}/{kebab-case-description}` |
| type | `feat` / `fix` / `refactor` / `chore` / `docs` / `test` |
| 文字種 | 英数字・ハイフン・スラッシュのみ |
| 長さ | 全体で 50 文字以内 |

**type の選び方:**
- 新機能追加 → `feat`
- バグ修正 → `fix`
- リファクタリング → `refactor`
- テスト追加・修正 → `test`
- ドキュメント → `docs`
- ビルド・設定・依存関係 → `chore`

### 候補生成のアプローチ

1. **変更がある場合**: `git diff HEAD` と `git status` の内容から変更の意図を読み取り、候補を生成
2. **変更がない場合**: ユーザーが指示の中に目的を書いていればそれを使う。なければ後述のフォールバックへ
3. **ユーザーが目的を明示した場合**: その説明を最優先してブランチ名を生成

候補は必ず **3 つ** 生成する。同じ意図を異なる粒度・表現で表す。

---

## Phase 4: ユーザー確認（必須）

以下の形式で提示する:

```
ブランチ名の候補です:

1. feat/add-user-authentication
2. feat/implement-jwt-login
3. feat/user-auth-flow
4. 自由入力

番号で選択してください（4 を選んだ場合はブランチ名を入力してください）:
```

- ユーザーが承認するまで次のフェーズには進まない
- 4 を選んだ場合はブランチ名の入力を促す
- 入力されたブランチ名が命名ルールを満たさない場合は警告して修正を促す

---

## Phase 5: ブランチ作成・チェックアウト

### 未コミット変更がある場合

```bash
git stash push -m "ore-checkout: 作業中の変更を一時退避"
```

stash 失敗時はエラーを報告して中断する。

### ブランチ作成

```bash
# origin/develop ベースで作成
git checkout -b {branch_name} origin/develop
```

`origin/develop` が存在しない場合はローカルの `develop` を使う:

```bash
git checkout -b {branch_name} develop
```

### 同名ブランチが既に存在する場合

```
ブランチ '{branch_name}' は既に存在します。
別の名前を入力してください:
```

ユーザーに新しい名前を入力させる。

### stash の復元

stash を退避した場合は復元する:

```bash
git stash pop
```

`stash pop` でコンフリクトが発生した場合:
- コンフリクトした旨を報告する
- `git stash list` で stash が残っていることを伝える
- ユーザーに手動解決を促す（自動でマージしない）

---

## Phase 6: 完了報告

成功時:

```
✔ ブランチ '{branch_name}' を origin/develop ベースで作成しました。

現在のブランチ: {branch_name}
ベース: origin/develop ({commit_hash})
```

未コミット変更を stash した場合は追記:

```
※ 作業中の変更を復元しました（git stash pop）。
```

---

## エラーハンドリング早見表

| 状況 | 対応 |
|------|------|
| `origin/develop` が存在しない | fetch を試み、失敗したらローカル develop を使うか中断 |
| 同名ブランチが既に存在 | 警告して別名を要求 |
| stash 失敗 | エラーを報告して中断（変更を失わせない） |
| stash pop でコンフリクト | 報告のみ、手動解決を促す |
| `origin/develop` も `develop` も存在しない | エラー報告して中断 |
| main/master 上で実行 | 通常通り処理（開発開始シーン）|
| develop 上で実行 | 通常通り処理（develop から作業ブランチを切るシーン）|
