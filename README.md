# chezmoi dotfiles

Claude Code / Codex CLI の設定に加え、zsh・git・mise・自作スクリプトを管理する chezmoi リポジトリ。

コンセプト: ~/.ai_agent を単一の AI 共有ベースとし、Claude・Codex がこれを参照する対称構成。共通ルールを1箇所修正して chezmoi apply を実行するだけで、全ツールに設定が反映される。

## ディレクトリ構成

```
~/.local/share/chezmoi/
├── .chezmoidata/
│   └── permissions.yaml          # Bash 許可コマンドの単一定義（33個）
├── dot_ai_agent/
│   ├── instructions/
│   │   └── core.md               # 全ツール共通ルール（Claude・Codex 両方に埋め込まれる）
│   └── skills/                   # スキル実体7個（→ ~/.ai_agent/skills/）
│       ├── ore-ai-review/        # Claude 専用（Codex には symlink しない）
│       ├── ore-checkout/
│       ├── ore-commit/
│       ├── ore-message/
│       ├── ore-plan-setup/
│       ├── ore-push/
│       └── ore-think/
├── dot_claude/
│   ├── CLAUDE.md.tmpl            # → ~/.claude/CLAUDE.md（core.md include + Claude 固有内容）
│   ├── settings.json.tmpl        # → ~/.claude/settings.json
│   ├── agents/
│   │   └── codex-implementer.md  # → ~/.claude/agents/
│   ├── hooks/
│   │   └── executable_log-event.sh  # → ~/.claude/hooks/
│   └── skills/                   # → ~/.claude/skills/（7個すべて symlink）
│       └── symlink_ore-*.tmpl    # ~/.ai_agent/skills/ へのシンボリックリンク
├── dot_codex/
│   ├── AGENTS.md.tmpl            # → ~/.codex/AGENTS.md（core.md include + Codex 固有内容）
│   ├── rules/
│   │   └── default.rules.tmpl   # → ~/.codex/rules/default.rules
│   └── skills/                   # → ~/.codex/skills/（symlink、6個）
│       └── symlink_*.tmpl        # ~/.ai_agent/skills/ へのシンボリックリンク
├── dot_zshrc                         # → ~/.zshrc
├── dot_zprofile                      # → ~/.zprofile
├── dot_config/
│   ├── git/
│   │   └── ignore                   # → ~/.config/git/ignore
│   └── mise/
│       └── config.toml              # → ~/.config/mise/config.toml
├── bin/
│   ├── executable_gsopen.sh         # → ~/bin/gsopen.sh
│   ├── executable_hello.sh          # → ~/bin/hello.sh
│   └── executable_tmpdir.sh         # → ~/bin/tmpdir.sh
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

`.chezmoidata/permissions.yaml` に Bash 許可コマンド（33個）を単一定義し、`chezmoi apply` 時に以下の両方へ展開される:

- `~/.claude/settings.json` の `Bash(xxx:*)` 許可リスト
- `~/.codex/rules/default.rules` の `prefix_rule`

### スキルの共有

実体は `dot_ai_agent/skills/`（7個）で `~/.ai_agent/skills/` に展開される。Claude・Codex とも `symlink_*.tmpl` により `~/.ai_agent/skills/` を参照する対称構成。
`ore-ai-review` は Claude のサブエージェント機構に依存するため Codex からは除外。

## 日常の運用

### 共通ルールを変更する

```bash
chezmoi edit ~/.claude/CLAUDE.md
chezmoi apply
```

### 許可コマンドを追加する

```bash
# permissions.yaml に1行追加して適用（両ツールに同時反映）
chezmoi edit ~/.local/share/chezmoi/.chezmoidata/permissions.yaml
chezmoi apply
```

### スキルを追加する

```bash
# 実体を dot_ai_agent/skills に作成
mkdir dot_ai_agent/skills/<スキル名>

# Claude に追加する場合（symlink テンプレートを作成）
printf '{{ .chezmoi.homeDir }}/.ai_agent/skills/<スキル名>\n' > dot_claude/skills/symlink_<スキル名>.tmpl

# Codex にも共有する場合（Codex 用 symlink テンプレートも作成）
printf '{{ .chezmoi.homeDir }}/.ai_agent/skills/<スキル名>\n' > dot_codex/skills/symlink_<スキル名>.tmpl

chezmoi apply
```

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

## 秘匿情報の管理

GitHub PAT は macOS Keychain に保存され、`chezmoi apply` 時にテンプレートへ注入される。リポジトリに平文は存在しない。

| 項目 | 値 |
|------|-----|
| Keychain service | `github` |
| Keychain account | ログインユーザー名（`$USER`） |
| テンプレート参照 | `{{ keyring "github" .chezmoi.username }}` |

### PAT のローテーション

```bash
# -w を値なしで実行するとプロンプトで安全に入力できる
security add-generic-password -U -s github -a "$USER" -w
chezmoi apply
```

## 新マシンでのセットアップ

0. `~/.zshenv.local` を手動作成する（シェル秘匿トークン置き場）:
   ```bash
   echo 'export GITHUB_PERSONAL_ACCESS_TOKEN=<トークン>' > ~/.zshenv.local && chmod 600 ~/.zshenv.local
   ```

0-b. git のユーザー情報を設定する:
   ```bash
   git config --global user.name ya-mori
   git config --global user.email <メールアドレス>
   ```

0-c. `~/.zshrc.local` は必須ではない。Antigravity や Kiro など各ツールの再インストール時に自動追記されるため、必要に応じて手動作成すればよい。

1. Keychain へ PAT を登録する（必須・事前に実施）:
   ```bash
   security add-generic-password -s github -a "$USER" -w
   ```

2. chezmoi をインストールして初期化する:
   ```bash
   brew install chezmoi
   # リモートリポジトリが設定済みの場合
   chezmoi init --apply <リポジトリURL>
   # ローカルパスから初期化する場合
   chezmoi init --apply /path/to/chezmoi-source
   ```

## 管理対象外のもの

以下は chezmoi の管理対象に含めない:

| パス | 理由 |
|------|------|
| `~/.codex/config.toml` | Codex が実行時に自己書き換えするため |
| `~/.claude/history.jsonl` | ランタイム状態 |
| `~/.claude/projects/` | ランタイム状態 |
| `~/.claude/plugins/` | ランタイム状態 |
| `README.md`（このファイル） | `.chezmoiignore` により管理対象外 |
| `~/.zshenv.local` | シェル用の秘匿トークン置き場（平文をリポジトリに入れないため） |
| `~/bin/cloud-sql-proxy` | バイナリのため（brew 等で導入する） |
| `~/.gitconfig` | ユーザー情報（メールアドレス）と Sourcetree の自動生成設定を含むため管理しない。共通 ignore は ~/.config/git/ignore で管理 |
| `~/.zshrc.local` | ツール（Antigravity, Kiro 等）が自動追記するマシン固有設定の受け皿 |
