#!/bin/bash
# PostToolUse hook: インクリメンタルイベントロガー（LLMなし）
LOG_DIR="$HOME/.ai_workspace/claude/session-logs"
mkdir -p "$LOG_DIR"

python3 - "$LOG_DIR" <<'PYEOF'
import glob
import json
import os
import sys
import time

log_dir = sys.argv[1]
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)

sid = (d.get("session_id") or "unknown")[:8]
tool = d.get("tool_name") or ""
ti = d.get("tool_input") or {}
ts = time.strftime("%H:%M:%S")
date = time.strftime("%Y-%m-%d")
path = os.path.join(log_dir, f"{time.strftime('%Y%m%d')}-{sid}.md")

line = None
if tool == "Bash":
    cmd = (ti.get("command") or "").split("\n")[0][:120]
    if cmd:
        line = f"- {ts} [Bash] `{cmd}`\n"
elif tool in ("Write", "Edit"):
    file = ti.get("file_path") or ""
    if file:
        line = f"- {ts} [{tool}] {file}\n"
elif tool == "TaskCreate":
    title = ti.get("title") or ""
    if title:
        line = f'\n## Task: "{title}" [started: {ts}]\n'
elif tool == "TaskUpdate":
    status = ti.get("status") or ""
    if status in ("completed", "failed"):
        r = d.get("tool_response") or {}
        title = (r.get("title") if isinstance(r, dict) else None) or ti.get("id") or ""
        line = f"- {ts} [Task:{status}] {title}\n\n---\n\n"

if line is None:
    sys.exit(0)

is_new = not os.path.exists(path)
with open(path, "a") as fp:
    if is_new:
        fp.write(f"# セッション: {date} ({sid})\n\n")
    fp.write(line)

# 新規セッションの開始時に 30 日より古いログを削除する
if is_new:
    cutoff = time.time() - 30 * 86400
    for old in glob.glob(os.path.join(log_dir, "*.md")):
        try:
            if os.path.getmtime(old) < cutoff:
                os.remove(old)
        except OSError:
            pass
PYEOF
exit 0
