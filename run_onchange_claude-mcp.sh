#!/bin/sh
# Claude Code の user スコープ MCP サーバーを登録する（登録先: ~/.claude.json）。
# ~/.claude.json はセッション状態を含むため chezmoi で直接管理せず、このスクリプトで登録だけを再現する。
# 認証情報は含まない: ~/.config/google-mcp/credentials.json を置き、
# {docs,sheets}-token.json は各 MCP の初回 OAuth（ブラウザ承認）で生成する。
#
# credentials.json は google-sheets と google-docs で共有する（同一の OAuth クライアント）。
# トークンは共有できない: 実装ごとに形式もスコープも違うため、サーバー単位で分ける。
#   docs   … authorized_user 形式（client_id / client_secret / refresh_token / type）
#   sheets … google-auth-library 形式（access_token / expiry_date / scope / ...）
#
# ※ google-docs の OAuth はコールバックにポート3000を使う。使用中なら空けてから実行する。
# ※ パスを変えたときは add_if_missing が既存登録をスキップするので、
#    先に `claude mcp remove <name> -s user` してから apply すること。

set -eu

command -v claude >/dev/null 2>&1 || { echo "claude CLI が無いためスキップ"; exit 0; }

add_if_missing() {
  name=$1; shift
  if claude mcp get "$name" >/dev/null 2>&1; then
    echo "mcp: $name は登録済み"
  else
    claude mcp add "$name" --scope user "$@"
    echo "mcp: $name を登録した"
  fi
}

cred="$HOME/.config/google-mcp/credentials.json"

add_if_missing google-sheets \
  --env "CREDENTIALS_PATH=$cred" \
  --env "TOKEN_PATH=$HOME/.config/google-mcp/sheets-token.json" \
  -- mcp-google-sheets

add_if_missing google-docs \
  --env "CREDENTIALS_PATH=$cred" \
  --env "TOKEN_PATH=$HOME/.config/google-mcp/docs-token.json" \
  -- npx -y @suncreation/mcp-google-docs
