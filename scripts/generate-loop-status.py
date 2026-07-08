#!/usr/bin/env python3
"""mugen-loop自身の状態を読み取り、docs/loop-status.mdにレポートを生成する。

Phase 1: Report Loopの範囲内の機能。状態を読んで整理して書き出すだけで、
自動修正・自動push・自動PR作成・外部API接続は一切行わない。
Python標準ライブラリのみを使用する。
"""

import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTPUT_PATH = ROOT / "docs" / "loop-status.md"

CHECKPOINT_PATH = ROOT / ".claude" / "loops" / "state" / "checkpoint.json"
SETTINGS_PATH = ROOT / ".claude" / "loops" / "settings.json"
RECEIPTS_DIR = ROOT / ".claude" / "loops" / "receipts"
QANDA_PATH = ROOT / "QandA.md"
TODO_PATH = ROOT / "todo.md"

DOCUMENT_CHECK_TARGETS = [
    "README.md",
    "CLAUDE.md",
    "CONTRACT.md",
    "QandA.md",
    "docs/note-draft.md",
    ".claude/loops/settings.json",
    ".claude/loops/state/checkpoint.json",
]

SAFETY_FIELDS = [
    "dryRun",
    "allowPush",
    "allowMerge",
    "allowDelete",
    "requireHumanApproval",
    "multiAgent",
    "currentPhase",
]

MAX_RECEIPTS = 5
MAX_TODO_ITEMS = 20


def read_json(path):
    """JSONファイルを読む。存在しない・壊れている場合はNoneを返す(例外を投げない)。"""
    if not path.exists():
        return None
    try:
        with path.open("r", encoding="utf-8") as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def read_text(path):
    """テキストファイルを読む。読めない場合はNoneを返す。"""
    if not path.exists():
        return None
    try:
        with path.open("r", encoding="utf-8") as f:
            return f.read()
    except OSError:
        return None


def build_summary(checkpoint):
    lines = ["## Summary", ""]
    if checkpoint is None:
        lines.append("- checkpoint.json を読み取れませんでした。")
        lines.append("")
        return lines
    fields = ["project", "currentPhase", "status", "lastRun", "lastTask"]
    for field in fields:
        value = checkpoint.get(field, "未設定")
        if value is None:
            value = "未設定"
        lines.append("- {}: {}".format(field, value))
    lines.append("")
    return lines


def collect_receipts():
    """receipts/YYYY-MM-DD/*.md を新しい順に集める。.gitkeep等は除外する。"""
    if not RECEIPTS_DIR.exists():
        return []
    entries = []
    for date_dir in RECEIPTS_DIR.iterdir():
        if not date_dir.is_dir():
            continue
        for receipt_file in date_dir.glob("*.md"):
            entries.append((date_dir.name, receipt_file.name, receipt_file))
    # ファイル名は "HHMMSS-taskname.md" 形式のため、(日付, ファイル名) の文字列順ソートが
    # そのまま時系列順になる。新しい順に並べるため降順にする。
    entries.sort(key=lambda e: (e[0], e[1]), reverse=True)
    return entries


def extract_receipt_title(path):
    """レシートの先頭付近から見出し行を探す。見つからなければNone。"""
    text = read_text(path)
    if text is None:
        return None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("# "):
            return stripped[2:].strip()
    return None


def build_latest_receipts():
    lines = ["## Latest Receipts", ""]
    entries = collect_receipts()
    if not entries:
        lines.append("- レシートが見つかりませんでした。")
        lines.append("")
        return lines
    latest = entries[:MAX_RECEIPTS]
    for date_dir, filename, path in latest:
        title = extract_receipt_title(path)
        rel_path = "{}/{}".format(date_dir, filename)
        if title:
            lines.append("- {} — {} (`{}`)".format(date_dir, title, rel_path))
        else:
            lines.append("- {} — (`{}`)".format(date_dir, rel_path))
    lines.append("")
    lines.append("(全 {} 件のうち新しい順に最大 {} 件を表示)".format(len(entries), MAX_RECEIPTS))
    lines.append("")
    return lines


def build_qanda_status():
    lines = ["## QandA Status", ""]
    text = read_text(QANDA_PATH)
    if text is None:
        lines.append("- QandA.md が見つかりませんでした。")
        lines.append("")
        return lines
    numbers = [int(n) for n in re.findall(r"^###\s+Q(\d+)\.", text, re.MULTILINE)]
    if not numbers:
        lines.append("- Q付き見出しが見つかりませんでした。")
        lines.append("")
        return lines
    numbers.sort()
    is_contiguous = numbers == list(range(numbers[0], numbers[-1] + 1))
    if is_contiguous:
        lines.append("- 検出数: {}件 (Q{}〜Q{})".format(len(numbers), numbers[0], numbers[-1]))
    else:
        lines.append("- 検出数: {}件 (Q{})".format(
            len(numbers), ", Q".join(str(n) for n in numbers)))
    lines.append("")
    return lines


def build_todo_summary():
    lines = ["## TODO Summary", ""]
    text = read_text(TODO_PATH)
    if text is None:
        lines.append("- todo.md が見つかりませんでした。")
        lines.append("")
        return lines
    items = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("- [ ]"):
            items.append(stripped[len("- [ ]"):].strip())
    if not items:
        lines.append("- 未完了のTODO項目は見つかりませんでした。")
        lines.append("")
        return lines
    shown = items[:MAX_TODO_ITEMS]
    for item in shown:
        lines.append("- {}".format(item))
    if len(items) > MAX_TODO_ITEMS:
        lines.append("")
        lines.append("(全 {} 件のうち先頭 {} 件のみ表示)".format(len(items), MAX_TODO_ITEMS))
    lines.append("")
    return lines


def build_document_check():
    lines = ["## Document Check", ""]
    for rel_path in DOCUMENT_CHECK_TARGETS:
        exists = (ROOT / rel_path).exists()
        mark = "OK" if exists else "MISSING"
        lines.append("- [{}] {}".format(mark, rel_path))
    lines.append("")
    return lines


def format_value(value):
    if value is None:
        return "未設定"
    if isinstance(value, bool):
        return "true" if value else "false"
    return value


def build_safety_status(settings):
    lines = ["## Safety Status", ""]
    if settings is None:
        lines.append("- settings.json を読み取れませんでした。")
        lines.append("")
        return lines
    for field in SAFETY_FIELDS:
        value = format_value(settings.get(field))
        lines.append("- {}: {}".format(field, value))
    lines.append("")
    return lines


def build_notes():
    lines = [
        "## Notes",
        "",
        "このレポートは状態確認用です。自動修正・push・merge・PR作成は行いません。",
        "内容は生成時点のリポジトリ状態のスナップショットであり、判断や実行は人間が行います。",
        "",
    ]
    return lines


def render_report():
    checkpoint = read_json(CHECKPOINT_PATH)
    settings = read_json(SETTINGS_PATH)
    generated_at = datetime.now(timezone.utc).astimezone().isoformat(timespec="seconds")

    lines = [
        "# mugen-loop Status Report",
        "",
        "<!-- このファイルは scripts/generate-loop-status.py により自動生成されます。手動編集しても次回実行で上書きされます。 -->",
        "",
        "生成日時: {}".format(generated_at),
        "",
    ]
    lines += build_summary(checkpoint)
    lines += build_latest_receipts()
    lines += build_qanda_status()
    lines += build_todo_summary()
    lines += build_document_check()
    lines += build_safety_status(settings)
    lines += build_notes()
    return "\n".join(lines).rstrip() + "\n"


def main():
    report = render_report()
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with OUTPUT_PATH.open("w", encoding="utf-8", newline="\n") as f:
        f.write(report)
    print("状態レポートを生成しました: {}".format(OUTPUT_PATH.relative_to(ROOT)))


if __name__ == "__main__":
    main()
