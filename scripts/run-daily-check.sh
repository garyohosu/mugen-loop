#!/usr/bin/env bash
# run-daily-check.sh — 安全な見回りスクリプト(読み取りのみ)
#
# このスクリプトは状態を「読む」だけです。
# push / merge / delete などの破壊的操作は一切行いません。
# 唯一の書き込みは receipts 用ディレクトリの作成(mkdir -p)です。

set -euo pipefail

# リポジトリルートへ移動(gitリポジトリでなければカレントのまま)
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

echo "=== mugen-loop daily-check (dry-run) ==="
echo "現在時刻: $(date '+%Y-%m-%d %H:%M:%S')"
echo

echo "--- git status --short ---"
git status --short || echo "(gitリポジトリではないか、gitが使えません)"
echo

echo "--- checkpoint.json の確認 ---"
CHECKPOINT=".claude/loops/state/checkpoint.json"
if [ -f "$CHECKPOINT" ]; then
  echo "OK: $CHECKPOINT が存在します"
else
  echo "警告: $CHECKPOINT が見つかりません"
fi
echo

echo "--- receipts ディレクトリの準備 ---"
RECEIPTS_DIR=".claude/loops/receipts/$(date '+%Y-%m-%d')"
mkdir -p "$RECEIPTS_DIR"
echo "OK: $RECEIPTS_DIR を用意しました"
echo

echo "=== daily-check 完了(破壊的操作・既存ファイル変更は行っていません) ==="
echo "次の一歩: scripts/write-receipt.sh daily-check でレシートを残してください"
