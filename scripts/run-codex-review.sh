#!/usr/bin/env bash
# run-codex-review.sh — Codexレビューを安全に呼ぶための入口
#
# 現時点の実装範囲(2026-07-09):
#   - 二重ロック判定(codexExec.enabled && RUN_CODEX=1)      … 実装済み
#   - 日次上限判定(Asia/Tokyo、1日1回、codexRunStarted:true) … 実装済み
#   - 入力検証(review-type / scope / base-branch / files)   … 実装済み
#   - 開始レシート作成                                        … 実装済み
#   - Codexプロセスの起動                                    … 未実装(スタブ。run_codex_process()参照)
#
# 設計: docs/superpowers/specs/2026-07-09-codex-exec-review-design.md
# 確定事項: QandA.md Q16(二重ロック) / Q17(日次上限・機械判定キー) / Q18(配置先)
#
# このスクリプトは、ゲートで拒否されない限りレシートを新規作成します。
# ファイルの変更・削除、push、merge、PR作成、外部送信、Codexプロセスの起動は一切行いません。

set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
ROOT="$(pwd)"

SETTINGS_FILE=".claude/loops/settings.json"
SCHEMA_FILE=".claude/loops/schemas/codex-review-output.schema.json"

usage() {
  cat <<'EOF'
使い方:
  scripts/run-codex-review.sh --review-type code --scope uncommitted --purpose "..." --requested-by "..."
  scripts/run-codex-review.sh --review-type code --scope branch --base-branch main --purpose "..." --requested-by "..."
  scripts/run-codex-review.sh --review-type document --files docs/a.md,docs/b.md --purpose "..." --requested-by "..."

オプション:
  --review-type <code|document>   必須
  --scope <uncommitted|branch>    review-type=code のとき必須
  --base-branch <branch>          scope=branch のとき必須
  --files <path1,path2,...>       review-type=document のとき必須(カンマ区切り、リポジトリルート相対)
  --focus <text>                  任意。確認観点
  --purpose <text>                必須。なぜ重要レビューが必要かの短い説明
  --requested-by <text>           必須。実行を判断した主体

注意:
  このスクリプトは現時点でCodexプロセスを起動しません(run_codex_process()は未実装のスタブ)。
  ゲート判定・入力検証・開始レシート作成までの動作確認が目的です。
EOF
}

# ---- 引数解析 ----
REVIEW_TYPE=""
SCOPE=""
BASE_BRANCH=""
FILES_RAW=""
FOCUS=""
PURPOSE=""
REQUESTED_BY=""

while [ $# -gt 0 ]; do
  case "$1" in
    --review-type) REVIEW_TYPE="${2:-}"; shift 2 ;;
    --scope) SCOPE="${2:-}"; shift 2 ;;
    --base-branch) BASE_BRANCH="${2:-}"; shift 2 ;;
    --files) FILES_RAW="${2:-}"; shift 2 ;;
    --focus) FOCUS="${2:-}"; shift 2 ;;
    --purpose) PURPOSE="${2:-}"; shift 2 ;;
    --requested-by) REQUESTED_BY="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "不明な引数: $1" >&2; usage; exit 2 ;;
  esac
done

# 日付・時刻はAsia/Tokyo(JST)固定。
# 注意: この環境の date コマンドは tzdata (Asia/Tokyo 等の名前付きタイムゾーン)を
# 持たないため、POSIXオフセット形式 "JST-9" を使う(TZ=Asia/Tokyo は無視されHOSTのTZ
# のまま=不定になるため使わないこと)。
NOW_JST="$(TZ=JST-9 date '+%Y-%m-%d %H:%M:%S %Z')"
TODAY_JST="$(TZ=JST-9 date '+%Y-%m-%d')"
TIME_JST="$(TZ=JST-9 date '+%H%M%S')"
RECEIPTS_DIR=".claude/loops/receipts/${TODAY_JST}"

# ---- ブロック時のレシート作成 ----
write_blocked_receipt() {
  local reason="$1"
  mkdir -p "$RECEIPTS_DIR"
  local file="${RECEIPTS_DIR}/${TIME_JST}-codex-review-blocked.md"
  cat > "$file" <<EOF
# receipt: codex-review (blocked_by_gate)

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: codex-review
- 実行時刻(JST): ${NOW_JST}
- codexRunStarted: false
- codexRunDateJST: ${TODAY_JST}
- codexRunMode: ${REVIEW_TYPE:-unknown}
- codexRunResult: blocked_by_gate

## 何をしたか

- run-codex-review.sh を実行し、ゲート判定で拒否された

## なぜしたか

- 二重ロック(codexExec.enabled && RUN_CODEX=1)、日次上限、入力検証のいずれかを満たさなかった

## 何をしなかったか

- Codexプロセスの起動
- ファイルの変更・削除、push、merge、PR作成、外部送信

## ブロック理由

${reason}

## 入力(検証前の生値)

- review-type: ${REVIEW_TYPE:-(未指定)}
- scope: ${SCOPE:-(未指定)}
- base-branch: ${BASE_BRANCH:-(未指定)}
- files: ${FILES_RAW:-(未指定)}
- purpose: ${PURPOSE:-(未指定)}
- requested-by: ${REQUESTED_BY:-(未指定)}
EOF
  echo "ゲートで拒否しました: ${reason}" >&2
  echo "レシートを作成しました: ${file}" >&2
}

# ---- 1. 二重ロック判定(QandA.md Q16) ----
# codexExec.enabled(settings.json) と 環境変数 RUN_CODEX=1 の両方が揃って初めて通過する。
check_double_lock() {
  if [ ! -f "$SETTINGS_FILE" ]; then
    write_blocked_receipt "settings.json が見つかりません: ${SETTINGS_FILE}"
    return 1
  fi

  local enabled
  enabled="$(node -e "
    const s = JSON.parse(require('fs').readFileSync('${SETTINGS_FILE}', 'utf8'));
    process.stdout.write(String(!!(s.codexExec && s.codexExec.enabled)));
  ")"

  if [ "$enabled" != "true" ]; then
    write_blocked_receipt "codexExec.enabled が false です(settings.json)。二重ロック不成立。"
    return 1
  fi

  if [ "${RUN_CODEX:-}" != "1" ]; then
    write_blocked_receipt "環境変数 RUN_CODEX=1 が指定されていません。二重ロック不成立。"
    return 1
  fi

  return 0
}

# ---- 2. 日次上限判定(QandA.md Q17) ----
# Asia/Tokyoの日付ディレクトリ配下に、このスクリプト自身が作る開始レシート
# (ファイル名が "*-codex-review.md" で終わるもの。"-codex-review-blocked.md" は
# 別名なので対象外)に、"- codexRunStarted: true" の行が完全一致で含まれていれば、
# その日は実行済みとみなす。
#
# 注意: リポジトリ全体やreceipts配下を広くgrepすると、本スクリプトの説明文や
# 作業レシートの解説文中に "codexRunStarted: true" という文字列が地の文として
# 出現しただけで誤検出する(実際に2026-07-09の実装レシートで発生した)。
# そのため、対象ファイルをこのスクリプトが生成するファイル名パターンに限定し、
# 行の完全一致(grep -x)でのみ判定する。
check_daily_limit() {
  if [ -d "$RECEIPTS_DIR" ]; then
    local f
    for f in "$RECEIPTS_DIR"/*-codex-review.md; do
      [ -e "$f" ] || continue
      if grep -qx -- "- codexRunStarted: true" "$f" 2>/dev/null; then
        write_blocked_receipt "本日(${TODAY_JST}, Asia/Tokyo)は既にCodexを起動済みです(1日1回まで)。(${f})"
        return 1
      fi
    done
  fi
  return 0
}

# ---- 3. 入力検証(設計書 3.1/3.2/4/11) ----
validate_input() {
  if [ "$REVIEW_TYPE" != "code" ] && [ "$REVIEW_TYPE" != "document" ]; then
    write_blocked_receipt "review-type は code または document を指定してください(現在: ${REVIEW_TYPE:-未指定})。"
    return 1
  fi

  if [ -z "$PURPOSE" ] || [ -z "$REQUESTED_BY" ]; then
    write_blocked_receipt "purpose と requested-by は必須です。"
    return 1
  fi

  if [ "$REVIEW_TYPE" = "code" ]; then
    if [ "$SCOPE" != "uncommitted" ] && [ "$SCOPE" != "branch" ]; then
      write_blocked_receipt "review-type=code のとき scope は uncommitted または branch が必須です(現在: ${SCOPE:-未指定})。"
      return 1
    fi
    if [ "$SCOPE" = "branch" ]; then
      if [ -z "$BASE_BRANCH" ]; then
        write_blocked_receipt "scope=branch のとき base-branch は必須です。"
        return 1
      fi
      if ! git rev-parse --verify "$BASE_BRANCH" >/dev/null 2>&1; then
        write_blocked_receipt "base-branch '${BASE_BRANCH}' が見つかりません。"
        return 1
      fi
    fi
  fi

  if [ "$REVIEW_TYPE" = "document" ]; then
    if [ -z "$FILES_RAW" ]; then
      write_blocked_receipt "review-type=document のとき files は必須です。"
      return 1
    fi
    local f
    local IFS=','
    for f in $FILES_RAW; do
      if [[ "$f" == *'*'* ]]; then
        write_blocked_receipt "files にワイルドカードは使用できません: ${f}"
        return 1
      fi
      local abspath
      abspath="$(realpath -m "${ROOT}/${f}" 2>/dev/null || echo "")"
      case "$abspath" in
        "${ROOT}"/*) : ;;
        *)
          write_blocked_receipt "files はリポジトリルート配下のみ許可されます: ${f}"
          return 1
          ;;
      esac
      if [ ! -f "$f" ]; then
        write_blocked_receipt "files に存在しないファイルが含まれています: ${f}"
        return 1
      fi
    done
  fi

  return 0
}

# ---- 4. 開始レシート作成(QandA.md Q17-4: 開始レシート先行方式) ----
# 二重ロック・日次上限・入力検証をすべて通過した時点で、Codexを実行する前に
# codexRunStarted: true を含むレシートを先に残す。
write_start_receipt() {
  mkdir -p "$RECEIPTS_DIR"
  local file="${RECEIPTS_DIR}/${TIME_JST}-codex-review.md"
  cat > "$file" <<EOF
# receipt: codex-review

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: codex-review
- 実行時刻(JST、開始): ${NOW_JST}
- codexRunStarted: true
- codexRunDateJST: ${TODAY_JST}
- codexRunMode: ${REVIEW_TYPE}
- codexRunResult: not_implemented_stub

## 入力

- review-type: ${REVIEW_TYPE}
- scope: ${SCOPE:-N/A}
- base-branch: ${BASE_BRANCH:-N/A}
- files: ${FILES_RAW:-N/A}
- focus: ${FOCUS:-(未指定)}
- purpose: ${PURPOSE}
- requested-by: ${REQUESTED_BY}

## ゲート判定

- 二重ロック(codexExec.enabled && RUN_CODEX=1): 通過
- 日次上限(Asia/Tokyo、1日1回): 通過
- 入力検証: 通過

## Codex実行(未実装)

このスクリプトは現時点でCodexプロセスの起動を実装していません(run_codex_process() はスタブ)。
設計書(docs/superpowers/specs/2026-07-09-codex-exec-review-design.md)実装単位3〜6
(プロセス起動、タイムアウト、JSON抽出、結果分類とレシート追記)は次回以降の別作業で追加する。

- codexRunResult(最終、現時点): not_implemented_stub

## 何をしたか

- 二重ロック、日次上限、入力検証を通過し、開始レシートを作成した
- Codexプロセスは起動していない(未実装のスタブのため)

## なぜしたか

- 設計書とQandA.md Q16/Q17の確定方針に従い、「開始レシート先行書き込み」を実装した
- 費用が発生する実Codex実行は、人間の別途明示承認後に実装・実行する方針のため

## 何をしなかったか

- Codexプロセスの起動、外部API呼び出し
- ファイルの変更・削除、push、merge、PR作成、外部送信
EOF
  echo "開始レシートを作成しました: ${file}" >&2
  echo "$file"
}

# ---- 5. Codex起動(スタブ・TODO) ----
# TODO(次回以降の別作業、人間の明示承認後に実装):
#   設計書(docs/superpowers/specs/2026-07-09-codex-exec-review-design.md)実装単位3〜6。
#   - code: codex exec review --uncommitted / --base <base-branch>
#   - document: codex exec <対象ファイルを明示したプロンプト>
#   - 共通オプション(設計§3.3): --ignore-user-config --ephemeral --strict-config
#     -c sandbox_mode="read-only" -c approval_policy="never"
#     --output-schema "${SCHEMA_FILE}" --json
#     (通常の codex exec には --cd "${ROOT}" も付与する)
#   - Codexプロセスは10分でハードタイムアウトし、プロセスツリーを終了する
#   - JSONLイベント列から最終JSONを抽出し、SCHEMA_FILE で検証する
#   - 結果分類(completed/timeout/auth_error/limit_reached/cli_error/invalid_output)を
#     開始レシートに追記する(このレシートを上書きするのではなく追記する)
#   - Claude Codeが各指摘を accepted/rejected/needs_human_decision/not_verified に再確認する
#
# 実装が完了するまで、このスクリプトから絶対に呼び出さないこと。
run_codex_process() {
  echo "run_codex_process(): 未実装のスタブです。ここでは何も実行しません。" >&2
  return 1
}

# ---- main ----
main() {
  if [ -z "$REVIEW_TYPE" ]; then
    usage
    exit 2
  fi

  check_double_lock || exit 1
  check_daily_limit || exit 1
  validate_input || exit 1

  local receipt
  receipt="$(write_start_receipt)"

  echo "=== gate / validation / 開始レシート作成 完了 ===" >&2
  echo "レシート: ${receipt}" >&2
  echo "Codexプロセスは起動していません(run_codex_process() は未実装のスタブ)。" >&2
}

main "$@"
