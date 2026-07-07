#!/usr/bin/env bash
# write-receipt.sh — receiptsに作業ログ(レシート)を作る安全なスクリプト
#
# 使い方: ./scripts/write-receipt.sh <タスク名>
# 例:     ./scripts/write-receipt.sh daily-check
#
# 注意: レシートに秘密情報(APIキー、トークン、パスワード)を書かないこと。
# このスクリプトは新しいレシートファイルを作るだけで、既存ファイルは変更しません。

set -euo pipefail

TASK_NAME="${1:-manual}"

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

TODAY="$(date '+%Y-%m-%d')"
NOW="$(date '+%Y-%m-%d %H:%M:%S')"
RECEIPTS_DIR=".claude/loops/receipts/$TODAY"
mkdir -p "$RECEIPTS_DIR"

# 同名ファイルを上書きしないよう時刻をファイル名に含める
RECEIPT_FILE="$RECEIPTS_DIR/$(date '+%H%M%S')-${TASK_NAME}.md"

GIT_STATUS="$(git status --short 2>/dev/null || echo '(git情報なし)')"
[ -z "$GIT_STATUS" ] && GIT_STATUS="(変更なし)"

cat > "$RECEIPT_FILE" <<EOF
# receipt: ${TASK_NAME}

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: ${TASK_NAME}
- 実行時刻: ${NOW}

## git status

\`\`\`
${GIT_STATUS}
\`\`\`

## 確認した内容

- (ここに確認した内容を書く)

## 提案・気づき

- (ここに提案を書く。実行は人間の承認後)

## 人間に確認してほしいこと

- (なければ「なし」と書く)

## メモ

-
EOF

echo "レシートを作成しました: $RECEIPT_FILE"
