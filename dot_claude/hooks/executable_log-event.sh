#!/bin/bash
# PostToolUse hook: インクリメンタルイベントロガー（LLMなし）
if [ -n "$LOG_EVENT_HOOK_RUNNING" ]; then exit 0; fi
export LOG_EVENT_HOOK_RUNNING=1

INPUT=$(cat)

SESSION_ID=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
sid = d.get('session_id', 'unknown')
print(sid[:8])
" 2>/dev/null)

TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_name', ''))
" 2>/dev/null)

TIMESTAMP=$(date '+%H:%M:%S')
DATE=$(date '+%Y-%m-%d')
LOG_DIR="$HOME/.ai_workspace/claude/session-logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/$(date +%Y%m%d)-${SESSION_ID}.md"

# ファイルが新規なら日付ヘッダーを書く
if [ ! -f "$LOG_FILE" ]; then
  echo "# セッション: ${DATE} (${SESSION_ID})" > "$LOG_FILE"
  echo "" >> "$LOG_FILE"
fi

case "$TOOL_NAME" in
  Bash)
    CMD=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
cmd = d.get('tool_input', {}).get('command', '')
print(cmd.split('\n')[0][:120])
" 2>/dev/null)
    [ -n "$CMD" ] && echo "- ${TIMESTAMP} [Bash] \`${CMD}\`" >> "$LOG_FILE"
    ;;
  Write)
    FILE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)
    [ -n "$FILE" ] && echo "- ${TIMESTAMP} [Write] ${FILE}" >> "$LOG_FILE"
    ;;
  Edit)
    FILE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('file_path', ''))
" 2>/dev/null)
    [ -n "$FILE" ] && echo "- ${TIMESTAMP} [Edit] ${FILE}" >> "$LOG_FILE"
    ;;
  TaskCreate)
    TITLE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('title', ''))
" 2>/dev/null)
    if [ -n "$TITLE" ]; then
      printf "\n## Task: \"%s\" [started: %s]\n" "$TITLE" "$TIMESTAMP" >> "$LOG_FILE"
    fi
    ;;
  TaskUpdate)
    STATUS=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('status', ''))
" 2>/dev/null)
    if [[ "$STATUS" == "completed" || "$STATUS" == "failed" ]]; then
      TITLE=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
r = d.get('tool_response') or {}
title = r.get('title') or d.get('tool_input', {}).get('id', '')
print(title)
" 2>/dev/null)
      printf "- %s [Task:%s] %s\n\n---\n\n" "$TIMESTAMP" "$STATUS" "$TITLE" >> "$LOG_FILE"
    fi
    ;;
esac

exit 0
