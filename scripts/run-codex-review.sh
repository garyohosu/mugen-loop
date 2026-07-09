#!/usr/bin/env bash
# run-codex-review.sh — Codexレビューを安全に呼ぶための入口
#
# 実装範囲(2026-07-09):
#   - 二重ロック判定(codexExec.enabled && RUN_CODEX=1)      … 実装済み
#   - 日次上限判定(Asia/Tokyo、1日1回、codexRunStarted:true) … 実装済み
#   - 入力検証(review-type / scope / base-branch / files)   … 実装済み
#   - 開始レシート作成                                        … 実装済み
#   - Codexプロセス起動・10分タイムアウト・Schema検証・分類  … 実装済み
#
# 設計: docs/superpowers/specs/2026-07-09-codex-exec-review-design.md
# 確定事項: QandA.md Q16(二重ロック) / Q17(日次上限・機械判定キー) / Q18(配置先)
#
# このスクリプトは、ゲートで拒否されない限りレシートを新規作成します。
# Codex起動は二重ロック成立時に限る。自動修正・push・merge・PR作成は行わない。

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
  Codexプロセスは codexExec.enabled=true かつ RUN_CODEX=1 の場合だけ起動します。
  実行には人間の明示承認が必要です。
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

# ---- 補助関数: codexRunStarted: true を、CRLF/LF・前後空白に頑健に判定する ----
# "- codexRunStarted: true" のような行を key/value として解析し、
# キーが厳密に codexRunStarted、値が厳密に true の場合にのみ真(exit 0)を返す。
# grepの単純な文字列一致(2026-07-09に誤検出が発生した)には依存しない。
#   - 行末の \r (CRLF) はキー・値の両方から除去してから比較する
#   - キー・値の前後の空白は除去してから比較する
#   - キー側は先頭の "- " 箇条書き記号も除去してから比較する
#   - ":" を含む地の文(説明文)は、コロン区切りの1フィールド目がちょうど
#     "codexRunStarted" にならない限りヒットしない
receipt_marks_codex_started() {
  local file="$1"
  awk -F: '
    {
      key = $1
      gsub(/\r/, "", key)
      gsub(/^[[:space:]]*-?[[:space:]]*/, "", key)
      gsub(/[[:space:]]+$/, "", key)
      if (key != "codexRunStarted") next

      value = $2
      gsub(/\r/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      if (value == "true") { found = 1 }
    }
    END { exit found ? 0 : 1 }
  ' "$file"
}

# ---- 2. 日次上限判定(QandA.md Q17) ----
# Asia/Tokyoの日付ディレクトリ配下に、このスクリプト自身が作る開始レシート
# (ファイル名が "*-codex-review.md" で終わるもの。"-codex-review-blocked.md" は
# 別名なので対象外)に、codexRunStarted: true の行が含まれていれば、
# その日は実行済みとみなす。判定は receipt_marks_codex_started() で行う。
#
# 注意: 対象ファイルをこのスクリプトが生成するファイル名パターンに限定するのに加え、
# receipt_marks_codex_started() 自体もkey/valueを厳密に解析するため、
# 本スクリプトの説明文や作業レシートの解説文中に "codexRunStarted: true" という
# 文字列が地の文として出現しただけでは誤検出しない(2026-07-09に発見した不具合の修正)。
check_daily_limit() {
  if [ -d "$RECEIPTS_DIR" ]; then
    local f
    for f in "$RECEIPTS_DIR"/*-codex-review.md; do
      [ -e "$f" ] || continue
      if receipt_marks_codex_started "$f"; then
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
- codexRunResult: running

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

## Codex実行

- codexRunResult(開始時): running
- timeoutSeconds: 600
- sandbox: read-only
- approvalPolicy: never
- ephemeral: true
- userConfigLoaded: false
- outputSource: --output-last-message

## 何をしたか

- 二重ロック、日次上限、入力検証を通過し、Codex起動前に開始レシートを作成した

## なぜしたか

- 設計書とQandA.md Q16/Q17の確定方針に従い、「開始レシート先行書き込み」を行った

## 何をしなかったか

- ファイルの変更・削除、push、merge、PR作成、外部送信
EOF
  echo "開始レシートを作成しました: ${file}" >&2
  echo "$file"
}

# ---- 5. Codex起動・タイムアウト・検証・結果分類 ----
CODEX_TIMEOUT_SECONDS=600
CODEX_COMMAND=()

build_review_prompt() {
  if [ "$REVIEW_TYPE" = "document" ]; then
    printf '指定された文書だけを読み取り専用でレビューしてください。対象: %s\n' "$FILES_RAW"
  else
    printf '現在の差分を読み取り専用でレビューしてください。\n'
  fi
  if [ -n "$FOCUS" ]; then
    printf '重点確認: %s\n' "$FOCUS"
  fi
  printf '出力は指定されたJSON Schemaに厳密に従ってください。\n'
}

build_codex_command() {
  local output_file="$1"
  local schema_abs
  schema_abs="$(realpath "$SCHEMA_FILE")"

  # 安全設定は必ずトップレベル、exec設定は必ずexec直後、review設定はreview後に固定する。
  CODEX_COMMAND=(
    codex
    --strict-config
    -s read-only
    -a never
    -C "$ROOT"
    exec
    --ignore-user-config
    --ephemeral
    review
    --output-schema "$schema_abs"
    --output-last-message "$output_file"
    --json
  )

  if [ "$REVIEW_TYPE" = "code" ]; then
    if [ "$SCOPE" = "uncommitted" ]; then
      CODEX_COMMAND+=(--uncommitted)
    else
      CODEX_COMMAND+=(--base "$BASE_BRANCH")
    fi
  fi
  CODEX_COMMAND+=(-)
}

# Node.jsが子プロセスを起動し、期限超過時はプロセスツリーを終了する。
# 戻り値124はtimeout、その他は子プロセスの終了コード。
run_with_timeout() {
  local timeout_seconds="$1"
  local prompt_file="$2"
  local stdout_file="$3"
  local stderr_file="$4"
  shift 4

  node - "$timeout_seconds" "$prompt_file" "$stdout_file" "$stderr_file" "$@" <<'NODE'
const fs = require("fs");
const { spawn } = require("child_process");

const [, , timeoutRaw, promptFile, stdoutFile, stderrFile, ...command] = process.argv;
const timeoutMs = Number(timeoutRaw) * 1000;
if (!Number.isFinite(timeoutMs) || timeoutMs <= 0 || command.length === 0) process.exit(125);

const stdin = fs.openSync(promptFile, "r");
const stdout = fs.openSync(stdoutFile, "w");
const stderr = fs.openSync(stderrFile, "w");
const child = spawn(command[0], command.slice(1), {
  stdio: [stdin, stdout, stderr],
  detached: process.platform !== "win32",
  windowsHide: true
});
let timedOut = false;
let settled = false;

function closeFiles() {
  for (const fd of [stdin, stdout, stderr]) {
    try { fs.closeSync(fd); } catch {}
  }
}

function killTree() {
  if (process.platform === "win32") {
    spawn("taskkill", ["/PID", String(child.pid), "/T", "/F"], {
      stdio: "ignore",
      windowsHide: true,
      detached: false
    });
    setTimeout(() => {
      try { child.kill("SIGKILL"); } catch {}
    }, 250).unref();
  } else {
    try { process.kill(-child.pid, "SIGKILL"); } catch {}
  }
}

const timer = setTimeout(() => {
  timedOut = true;
  killTree();
  setTimeout(() => {
    if (!settled) {
      try { child.kill("SIGKILL"); } catch {}
      closeFiles();
      process.exit(124);
    }
  }, 5000);
}, timeoutMs);

child.on("error", () => {
  settled = true;
  clearTimeout(timer);
  closeFiles();
  process.exit(127);
});
child.on("close", (code, signal) => {
  settled = true;
  clearTimeout(timer);
  closeFiles();
  if (timedOut) process.exit(124);
  if (Number.isInteger(code)) process.exit(Math.max(0, Math.min(255, code)));
  process.exit(signal ? 128 : 1);
});
NODE
}

# 外部パッケージを追加せず、正本Schemaで使用しているDraft-07キーワードをNode.jsで評価する。
# 成功時はレシート用の自由記述を含まない集計だけを出力する。
validate_output_json() {
  local output_file="$1"
  node - "$SCHEMA_FILE" "$output_file" <<'NODE'
const fs = require("fs");
const [,, schemaFile, outputFile] = process.argv;

function isType(value, type) {
  if (type === "null") return value === null;
  if (type === "array") return Array.isArray(value);
  if (type === "object") return value !== null && typeof value === "object" && !Array.isArray(value);
  if (type === "integer") return Number.isInteger(value);
  return typeof value === type;
}

function validate(schema, value, path = "$") {
  const errors = [];
  const types = schema.type === undefined ? [] : (Array.isArray(schema.type) ? schema.type : [schema.type]);
  if (types.length && !types.some(type => isType(value, type))) {
    return [`${path}: type`];
  }
  if (schema.const !== undefined && value !== schema.const) errors.push(`${path}: const`);
  if (schema.enum && !schema.enum.includes(value)) errors.push(`${path}: enum`);
  if (typeof value === "string" && schema.minLength !== undefined && value.length < schema.minLength) {
    errors.push(`${path}: minLength`);
  }
  if (typeof value === "number" && schema.minimum !== undefined && value < schema.minimum) {
    errors.push(`${path}: minimum`);
  }
  if (Array.isArray(value)) {
    if (schema.minItems !== undefined && value.length < schema.minItems) errors.push(`${path}: minItems`);
    if (schema.items) value.forEach((item, i) => errors.push(...validate(schema.items, item, `${path}[${i}]`)));
  }
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    for (const key of schema.required || []) {
      if (!Object.prototype.hasOwnProperty.call(value, key)) errors.push(`${path}.${key}: required`);
    }
    if (schema.additionalProperties === false && schema.properties) {
      for (const key of Object.keys(value)) {
        if (!Object.prototype.hasOwnProperty.call(schema.properties, key)) errors.push(`${path}.${key}: additional`);
      }
    }
    for (const [key, childSchema] of Object.entries(schema.properties || {})) {
      if (Object.prototype.hasOwnProperty.call(value, key)) {
        errors.push(...validate(childSchema, value[key], `${path}.${key}`));
      }
    }
  }
  for (const part of schema.allOf || []) {
    const conditionMatches = !part.if || validate(part.if, value, path).length === 0;
    if (conditionMatches && part.then) errors.push(...validate(part.then, value, path));
  }
  return errors;
}

let schema;
let data;
try {
  schema = JSON.parse(fs.readFileSync(schemaFile, "utf8"));
  data = JSON.parse(fs.readFileSync(outputFile, "utf8"));
} catch {
  process.exit(2);
}
const errors = validate(schema, data);
if (errors.length) process.exit(3);

const severity = { critical: 0, high: 0, medium: 0, low: 0 };
for (const finding of data.findings) severity[finding.severity]++;
process.stdout.write([
  data.reviewStatus,
  data.findings.length,
  data.unreviewed.length,
  severity.critical,
  severity.high,
  severity.medium,
  severity.low
].join("\t"));
NODE
}

classify_cli_failure() {
  local jsonl_file="$1"
  local stderr_file="$2"
  node - "$jsonl_file" "$stderr_file" <<'NODE'
const fs = require("fs");
const [,, jsonlFile, stderrFile] = process.argv;
const values = [];
for (const file of [jsonlFile, stderrFile]) {
  try {
    const text = fs.readFileSync(file, "utf8").slice(0, 262144);
    values.push(text);
    if (file === jsonlFile) {
      for (const line of text.split(/\r?\n/)) {
        try {
          const event = JSON.parse(line);
          values.push(String(event.code || event.error?.code || event.type || ""));
        } catch {}
      }
    }
  } catch {}
}
const haystack = values.join("\n").toLowerCase();
if (/(unauthorized|authentication required|invalid api key|not authenticated|auth_error)/.test(haystack)) {
  process.stdout.write("auth_error");
} else if (/(usage limit reached|rate limit exceeded|quota exceeded|insufficient_quota|limit_reached)/.test(haystack)) {
  process.stdout.write("limit_reached");
} else {
  process.stdout.write("cli_error");
}
NODE
}

append_completion_receipt() {
  local receipt="$1"
  local result="$2"
  local exit_code="$3"
  local elapsed_seconds="$4"
  local validation_summary="${5:-}"

  {
    printf '\n## Codex実行結果\n\n'
    printf -- '- codexRunResult(最終): %s\n' "$result"
    printf -- '- exitCode: %s\n' "$exit_code"
    printf -- '- elapsedSeconds: %s\n' "$elapsed_seconds"
    printf -- '- outputSource: --output-last-message\n'
    printf -- '- schemaValidation: %s\n' "$([ "$result" = "completed" ] && echo passed || echo not_passed)"
    if [ "$result" = "completed" ] && [ -n "$validation_summary" ]; then
      local review_status finding_count unreviewed_count critical high medium low
      IFS=$'\t' read -r review_status finding_count unreviewed_count critical high medium low <<<"$validation_summary"
      printf -- '- reviewStatus: %s\n' "$review_status"
      printf -- '- findingCount: %s\n' "$finding_count"
      printf -- '- unreviewedCount: %s\n' "$unreviewed_count"
      printf -- '- severityCounts: critical=%s, high=%s, medium=%s, low=%s\n' "$critical" "$high" "$medium" "$low"
    fi
    printf '\n自由記述の要約、指摘本文、プロンプト、JSONL、生のCLIエラー、環境変数は記録していない。\n'
  } >> "$receipt"
}

run_codex_process() {
  local receipt="$1"
  local temp_dir
  temp_dir="$(mktemp -d)"
  local prompt_file="${temp_dir}/prompt.txt"
  local final_output="${temp_dir}/last-message.json"
  local jsonl_output="${temp_dir}/events.jsonl"
  local stderr_output="${temp_dir}/stderr.txt"
  local started_at ended_at elapsed exit_code result validation_summary=""

  build_review_prompt > "$prompt_file"
  build_codex_command "$final_output"
  started_at="$(date +%s)"

  set +e
  run_with_timeout "$CODEX_TIMEOUT_SECONDS" "$prompt_file" "$jsonl_output" "$stderr_output" "${CODEX_COMMAND[@]}"
  exit_code=$?
  set -e

  ended_at="$(date +%s)"
  elapsed=$((ended_at - started_at))

  if [ "$exit_code" -eq 124 ]; then
    result="timeout"
  elif [ "$exit_code" -ne 0 ]; then
    result="$(classify_cli_failure "$jsonl_output" "$stderr_output")"
  elif [ ! -s "$final_output" ]; then
    result="invalid_output"
  else
    set +e
    validation_summary="$(validate_output_json "$final_output")"
    local validation_exit=$?
    set -e
    if [ "$validation_exit" -eq 0 ]; then
      result="completed"
    else
      result="invalid_output"
    fi
  fi

  append_completion_receipt "$receipt" "$result" "$exit_code" "$elapsed" "$validation_summary"
  rm -f -- "$prompt_file" "$final_output" "$jsonl_output" "$stderr_output"
  rmdir -- "$temp_dir"

  echo "Codex実行結果: ${result}" >&2
  [ "$result" = "completed" ]
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
  run_codex_process "$receipt"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
