#!/usr/bin/env python3
"""プレビュー HTML に保存されたコメントを JSON で取り出す。

Usage:
    python3 read_comments.py <preview.html>

出力: {"source": "<元マークダウンのパス>", "comments": [...]} を整形 JSON で標準出力に出す。
コメントが 0 件でも comments: [] を出力する（エラーではない）。
"""
import json
import pathlib
import re
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2

    html_text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")

    match = re.search(
        r'<script type="application/json" id="embedded-comments">(.*?)</script>',
        html_text,
        re.DOTALL,
    )
    if not match:
        print("embedded-comments 領域が見つかりません。ore-preview で生成した HTML か確認してください。", file=sys.stderr)
        return 1

    # JSON では "\/" は "/" の正当なエスケープなので、そのまま parse できる
    comments = json.loads(match.group(1))

    source_match = re.search(r'<meta name="source-markdown" content="([^"]*)"', html_text)
    source = source_match.group(1) if source_match else None

    print(json.dumps({"source": source, "comments": comments}, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
