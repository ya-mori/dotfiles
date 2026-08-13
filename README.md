# chezmoi dotfiles

Claude Code / Codex CLI の設定に加え、zsh・git・mise・自作スクリプトを管理する chezmoi リポジトリ。

コンセプト: ~/.ai_agent を単一の AI 共有ベースとし、Claude・Codex がこれを参照する対称構成。共通ルールを1箇所修正して chezmoi apply を実行するだけで、全ツールに設定が反映される。

## ディレクトリ構成

```
~/.local/share/chezmoi/
├── .chezmoidata/
│   └── permissions.yaml          # Bash 許可コマンドの単一定義
├── .chezmoitemplates/
│   └── claude/settings.json      # settings.json 本体（modify_settings.json から参照される）
├── .chezmoiscripts/
│   └── run_onchange_*.sh.tmpl    # apply 時に実行（ホームには展開しない）
├── .chezmoiignore                # chezmoi の展開対象外（README・Brewfile）
├── .gitignore                    # git 管理対象外（private* ／ private_ 属性は除く）
├── dot_ai_agent/
│   ├── docs/                     # → ~/.ai_agent/docs/（Claude・Codex 共通の参照ドキュメント）
│   │   └── <topic>/              # トピックごとに1ディレクトリ
│   │       ├── public.md         # 仕組み・ルール本体
│   │       └── private.md        # 秘匿部分の差分（git 追跡なし・「公開方針」参照）
│   ├── instructions/
│   │   └── core.md               # 全ツール共通ルール（Claude・Codex 両方に埋め込まれる）
│   └── skills/                   # スキル実体（→ ~/.ai_agent/skills/）
│       └── ore-*/                # 1スキル1ディレクトリ（SKILL.md 必須）
├── dot_claude/
│   ├── CLAUDE.md.tmpl            # → ~/.claude/CLAUDE.md（core.md include + Claude 固有内容）
│   ├── modify_settings.json      # → ~/.claude/settings.json（ランタイム書き込みを保持してマージ）
│   ├── agents/
│   │   └── *.md                  # → ~/.claude/agents/（サブエージェント定義）
│   └── skills/                   # → ~/.claude/skills/（全スキルを symlink）
│       └── symlink_ore-*.tmpl    # ~/.ai_agent/skills/ へのシンボリックリンク
├── dot_codex/
│   ├── AGENTS.md.tmpl            # → ~/.codex/AGENTS.md（core.md include + Codex 固有内容）
│   ├── rules/
│   │   └── default.rules.tmpl    # → ~/.codex/rules/default.rules
│   └── skills/                   # → ~/.codex/skills/（Codex 対象スキルのみ symlink）
│       └── symlink_*.tmpl        # ~/.ai_agent/skills/ へのシンボリックリンク
├── dot_zshenv                    # → ~/.zshenv（Keychain から秘匿トークンを注入）
├── dot_zshrc                     # → ~/.zshrc
├── dot_zprofile                  # → ~/.zprofile
├── dot_config/
│   ├── git/
│   │   └── ignore                # → ~/.config/git/ignore
│   └── mise/
│       └── config.toml           # → ~/.config/mise/config.toml
├── bin/
│   └── executable_*.sh           # → ~/bin/*.sh（prefix が外れ実行権限が付く）
├── Brewfile                      # brew パッケージの宣言（ホームには展開しない）
└── README.md                     # このファイル（chezmoi 管理対象外）
```

## アーキテクチャ

### テンプレートによる設定生成

| ソース | 生成先 | 内容 |
|--------|--------|------|
| `dot_ai_agent/instructions/core.md` | `~/.claude/CLAUDE.md` と `~/.codex/AGENTS.md` の両方 | 両ツール共通の行動ルール |
| `dot_claude/CLAUDE.md.tmpl`（インライン部分） | `~/.claude/CLAUDE.md` のみ | Claude Code 専用設定 |
| `dot_codex/AGENTS.md.tmpl`（インライン部分） | `~/.codex/AGENTS.md` のみ | Codex CLI 専用設定 |

### 許可コマンドの一元管理

`.chezmoidata/permissions.yaml` に Bash 許可コマンドを単一定義し、`chezmoi apply` 時に以下の両方へ展開される:

- `~/.claude/settings.json` の `Bash(xxx:*)` 許可リスト
- `~/.codex/rules/default.rules` の `prefix_rule`

許可するのは読み取り系・テスト系コマンドのみ。リダイレクトや `-exec` / `system()` / `-i` 等で書き込み・任意実行に転用できるコマンド（`find`, `sed`, `awk`, `echo`, `cp`, `chmod` など）は意図的に許可しない。

### スキルの共有

実体は `dot_ai_agent/skills/` で `~/.ai_agent/skills/` に展開される。Claude・Codex とも `symlink_*.tmpl` により `~/.ai_agent/skills/` を参照する対称構成。
`ore-ai-review` は Claude のサブエージェント機構に依存するため Codex からは除外。

現在のスキル一覧は `ls dot_ai_agent/skills/` で確認する（**README には列挙しない** ── 追加のたびに更新が必要になり、実態と乖離するため）。

## 日常の運用

### 共通ルールを変更する

```bash
chezmoi edit ~/.claude/CLAUDE.md
chezmoi apply
```

### 共通ルールへの昇格を判断する

`CLAUDE.md.tmpl` / `AGENTS.md.tmpl` の**ツール固有セクション**にルールを追記・変更したら、
そのつど `core.md` への昇格を検討し、`y/n` で確認を取る。

固有ファイルに書いたルールが実は共通ルールだった、という取りこぼしを防ぐための手順。
（実例: 「Notion タスク管理」は当初 CLAUDE.md 固有に書かれていたが、Codex でも使うため core へ昇格した）

**判断フロー**

1. **そのルールは、そのツール固有の機能に依存するか？**
   （hook / サブエージェント / プラグイン / スラッシュコマンド / そのツールにしかない MCP 設定）
   - **Yes → 固有のまま。** なぜ固有なのかを一言添えて報告する
2. **もう一方のツールにも同じ振る舞いをしてほしいか？**
   - **Yes → `core.md` へ昇格**することを `y/n` で確認する
   - No → 固有のまま

**棚卸しの記録**（2026-08-07 実施）

| セクション | 判定 | 根拠 |
|---|---|---|
| Subagent Usage Guidelines | 固有 | Codex はサブエージェント機構を持たず、AGENTS.md に「自身で直接実装する」逆のルールがある |
| Codex 実装委譲ルール | 固有 | Claude が Codex へ委譲する側のルール |

> Self-Improvement Loop（`PostToolUse` hook によるセッションログ収集）も固有と判定していたが、
> **2026-08-13 に廃止した。** hook が 2026-07-08 の書き換え以降サイレントに停止しており、
> 36日間気づかれなかったため。設計し直しは別タスクで扱う。

### 許可コマンドを追加する

```bash
# permissions.yaml に1行追加して適用（両ツールに同時反映）
chezmoi edit ~/.local/share/chezmoi/.chezmoidata/permissions.yaml
chezmoi apply
```

### スキルを追加する

```bash
# 実体を dot_ai_agent/skills に作成（SKILL.md が必須）
mkdir dot_ai_agent/skills/<スキル名>
$EDITOR dot_ai_agent/skills/<スキル名>/SKILL.md

# Claude に追加する場合（symlink テンプレートを作成）
printf '{{ .chezmoi.homeDir }}/.ai_agent/skills/<スキル名>\n' > dot_claude/skills/symlink_<スキル名>.tmpl

# Codex にも共有する場合（Codex 用 symlink テンプレートも作成）
printf '{{ .chezmoi.homeDir }}/.ai_agent/skills/<スキル名>\n' > dot_codex/skills/symlink_<スキル名>.tmpl

chezmoi apply
```

**README の更新は不要**（スキル一覧・個数を載せていないため）。

### ドリフト（アプリ側の書き換え）を検知・対処する

```bash
# 差分を確認
chezmoi diff

# ソース側に取り込む（アプリの変更を正とする場合）
chezmoi re-add ~/.claude/CLAUDE.md

# ソース優先で上書き（chezmoi の設定を正とする場合）
chezmoi apply
```

注意: `~/.claude/CLAUDE.md` や `~/.codex/AGENTS.md` はテンプレートからの生成物のため、直接編集しないこと。次の `chezmoi apply` で上書きされる。

ツールが `~/.zshrc` に自動追記した場合は `chezmoi diff` で検知できる。必要な行は `~/.zshrc.local` に移し、`chezmoi apply` で `.zshrc` をクリーンな状態に戻す。

## 公開方針（L1 / L2 / L3）

**このリポジトリは public であっても差し支えない状態を保つ。**
そのために情報を3層に分け、層ごとに置き場を変える。

| 層 | 中身 | 置き場 | git |
|---|------|--------|-----|
| **L1: 公開可** | 仕組み・ルール・構造。汎用的な知恵 | このリポジトリ | ✅ 管理する |
| **L2: 秘匿** | 識別子・社内固有名詞・実名・社内制度・業務実例 | `private.md`（**chezmoi は管理する**） | ❌ 追跡しない |
| **L3: 認証情報** | PAT・API キー | macOS Keychain / `*.local` ファイル | ❌ 置かない |

L3 の詳細は次節「秘匿情報の管理」を参照。

### public / private ペア規約

L2 を切り出すときは、**public.md と同じディレクトリ**に `private.md` として置く。

```
~/.ai_agent/docs/
└── task-system/
    ├── public.md     # 仕組み・ルール本体（このリポジトリで管理）
    └── private.md    # 識別子・実例だけの差分（chezmoi 管理・git 追跡なし）
```

トピック単位でまとまるため、public を読んだ時点で private の有無が同じディレクトリ内で分かる。

**private も chezmoi のソースに置く。** `dot_ai_agent/docs/<topic>/private.md` に実体があり、`chezmoi apply` で
`~/.ai_agent/docs/<topic>/private.md` へ展開される。`.gitignore` によって git だけが追跡しない状態になっている。
`chezmoi edit` で public 側と同じ操作で編集でき、置き場が分散しない。

> **履歴は残らない。** git 管理外のため、うっかり上書きしても戻せない。
> 実体はソースとターゲットの2箇所にあるので片方からは復旧できるが、変更履歴は追えない。

- **private 側は本文を複製しない。** 秘匿部分の差分だけを持つ
- AI エージェントは `<topic>/public.md` を読んだら同ディレクトリの `private.md` の有無を確認し、あれば併せて読む（規約は `dot_ai_agent/instructions/core.md` の Document Reference Guidelines に定義）
- **private が無い環境でも public 側だけで動作すること。** 新マシンや他人の環境で壊れないようにする
- 記述が競合する場合は private 側を優先する

### 安全網

| 仕組み | ファイル | 効果 |
|--------|---------|------|
| git 除外 | `.gitignore` の `**/private*` | 階層を問わず、private で始まるファイル・ディレクトリをコミットさせない |
| 例外の復帰 | `.gitignore` の `!**/private_*` | chezmoi の `private_` 属性 prefix を追跡対象に戻す |

`private*` としているのは `private.md` だけでなく `private-notes.md` のような派生名も拾うため。
命名を厳密に守れなくても秘匿側に倒れる。

> ⚠️ **安全網はこの1本しかない。** `private.md` は chezmoi の管理対象なので、
> `.gitignore` の `**/private*` を消すと秘匿情報が即座に git に入る。編集時は注意すること。
>
> 確認コマンド: `git status --short`（private が出なければ正常）/ `chezmoi managed | grep private`（出れば chezmoi 管理下）

> `private.md` は chezmoi の `private_` 属性 prefix（パーミッション 0600）とは**別物**。
> あちらは underscore 付きのファイル名に付く属性で、通常の dotfiles として git 追跡したい。
> そのため `!**/private_*` で除外から戻している。**この negate 行を消すと
> `private_` 付きの dotfiles が静かに git 管理外になる**（秘匿漏洩ではなく逆方向の事故）。
>
> 確認コマンド: `git check-ignore -v --no-index <パス>`（どのルールが効いたか分かる）

### 新しくドキュメントを追加するときの判断

1. 識別子（UUID・DB id・トークン）を含むか → **含むなら private へ**
2. 社内固有名詞（プロダクト名・施策名）・実名・社内制度を含むか → **含むなら private へ**
3. どちらも無く、仕組みや汎用的な知恵であれば public へ

迷ったら private に置く。後から public に上げるのは安全だが、逆は履歴に残る。

## 秘匿情報の管理

L3（認証情報）の扱い。GitHub の認証は用途ごとに分離し、シェルには一切 export しない（環境変数としての露出を避ける）。

| 用途 | 認証の担い手 | 備考 |
|------|-------------|------|
| git 操作（push/pull 等） | osxkeychain credential helper | `git config --global credential.helper osxkeychain` |
| `gh` CLI | gh 自身の認証（`gh auth login`） | gh 専用の keyring にトークンを保持 |
| Claude Code（GitHub 連携） | `~/.claude/settings.json` の env | `chezmoi apply` 時に `{{ keyring "github" .chezmoi.username }}` で PAT を注入 |

Claude Code 用の PAT のみ macOS Keychain に保持する:

| 項目 | 値 |
|------|-----|
| Keychain service | `github` |
| Keychain account | ログインユーザー名（`$USER`） |

### PAT のローテーション

```bash
# -w を値なしで実行するとプロンプトで安全に入力できる
security add-generic-password -U -s github -a "$USER" -w
chezmoi apply   # settings.json を再生成
```

注意: 生成後の `~/.claude/settings.json` には PAT が平文で含まれる（Claude Code の制約上不可避）。リポジトリと Keychain 以外にトークンを増やさないこと。

## 新マシンでのセットアップ

1. Keychain へ PAT を登録する（必須・事前に実施）:
   ```bash
   security add-generic-password -s github -a "$USER" -w
   ```

2. git のユーザー情報を設定する:
   ```bash
   git config --global user.name ya-mori
   git config --global user.email <メールアドレス>
   ```

3. chezmoi をインストールして初期化する:
   ```bash
   brew install chezmoi
   # リモートリポジトリが設定済みの場合
   chezmoi init --apply <リポジトリURL>
   # ローカルパスから初期化する場合
   chezmoi init --apply /path/to/chezmoi-source
   ```
   `chezmoi apply` の中で `run_onchange_after_brew-bundle.sh` が実行され、Brewfile 記載のパッケージが自動インストールされる。

補足:
- `~/.zshenv.local` / `~/.zshrc.local` は必須ではない。GitHub PAT は Keychain から自動注入されるため、追加のシークレットやツール自動追記分が発生したときに手動作成すればよい。

## 管理対象外のもの

以下は chezmoi の管理対象に含めない:

| パス | 理由 |
|------|------|
| `~/.codex/config.toml` | Codex が実行時に自己書き換えするため |
| `~/.claude/history.jsonl` | ランタイム状態 |
| `~/.claude/projects/` | ランタイム状態 |
| `~/.claude/plugins/` | ランタイム状態 |
| `README.md`（このファイル） | `.chezmoiignore` により管理対象外 |
| `~/.zshenv.local` | GitHub PAT 以外の追加シークレット置き場（任意・平文をリポジトリに入れないため）。GitHub PAT は Keychain から注入されるためここには不要 |
| `~/bin/cloud-sql-proxy` | バイナリのため（brew 等で導入する） |
| `~/Brewfile` | Brewfile はソースリポジトリ内にのみ置き、`run_onchange` スクリプトに埋め込んで使う（ホームへは展開しない） |
| `~/.gitconfig` | ユーザー情報（メールアドレス）と Sourcetree の自動生成設定を含むため管理しない。共通 ignore は ~/.config/git/ignore で管理 |
| `~/.zshrc.local` | ツール（Antigravity, Kiro 等）が自動追記するマシン固有設定の受け皿 |
