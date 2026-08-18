#!/usr/bin/env python3
"""マークダウンをコメント可能な HTML プレビューに変換する。

Usage:
    python3 build_preview.py <input.md> <output.html> [--title TITLE]

テンプレート（assets/template.html）にマークダウン原文を JSON として埋め込む。
レンダリングはブラウザ側の marked.js が行うため、このスクリプトに依存ライブラリはない。
"""
import argparse
import html
import json
import pathlib
import sys


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", help="入力マークダウンファイル")
    parser.add_argument("output", help="出力 HTML ファイル")
    parser.add_argument("--title", default=None, help="ドキュメントタイトル（省略時は入力ファイル名）")
    args = parser.parse_args()

    input_path = pathlib.Path(args.input).resolve()
    source = input_path.read_text(encoding="utf-8")

    template_path = pathlib.Path(__file__).resolve().parent.parent / "assets" / "template.html"
    template = template_path.read_text(encoding="utf-8")

    title = args.title or input_path.stem
    # JSON 文字列内の "</" は "<\/" にエスケープし、script ブロックの強制終了を防ぐ
    markdown_json = json.dumps(source, ensure_ascii=False).replace("</", "<\\/")

    result = (
        template
        .replace("__TITLE__", html.escape(title))
        .replace("__SOURCE_PATH__", html.escape(str(input_path)))
        .replace("__MARKDOWN_JSON__", markdown_json)
    )

    output_path = pathlib.Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(result, encoding="utf-8")
    print(output_path)


if __name__ == "__main__":
    sys.exit(main())
