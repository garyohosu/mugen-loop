# receipt: fix-crlf-daily-limit-detection

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: fix-crlf-daily-limit-detection(自己レビューで発見した残存リスクAの修正)
- 実行時刻: 2026-07-09 14:22:51
- 結果: `check_daily_limit()`の`codexRunStarted: true`判定を、grepの単純完全一致からawkベースのkey/value解析(`receipt_marks_codex_started()`)に置き換え、CRLF/LF・前後空白に頑健にした

## 承認根拠

前回の自己レビューで報告した「残存リスクA」(grep -qxの完全一致がCRLF変換で壊れ、日次上限が誤解除されうる)について、人間から次の承認を得た。

> 変更範囲: 1) check_daily_limit()周辺のみ 2) 小さな補助関数の追加可 3) 新規レシート作成
> 4) checkpoint.json/dream.md更新。修正方針(YAML風key/value解析、CRLF/LF両対応、
> 説明文/blockedレシートの誤検出を防ぐ現行方針は維持)を明示された。
> run_codex_process()の実装には進まない、codexExec.enabledはfalseのまま、
> Codex実行・commit・push・merge・PR作成は行わないことも明示された。

## 何をしたか

- `scripts/run-codex-review.sh`に`receipt_marks_codex_started()`を新規追加した
  - awkでコロン区切りの1フィールド目をキー、2フィールド目を値として抽出
  - キー・値の両方から`\r`(CRLFの行末)を除去
  - キー・値の前後の空白を除去
  - キーは先頭の`- `箇条書き記号も除去してから`codexRunStarted`と厳密一致するか判定
  - 値は`true`と厳密一致する場合のみ真を返す
- `check_daily_limit()`内の`grep -qx -- "- codexRunStarted: true" "$f"`を
  `receipt_marks_codex_started "$f"`の呼び出しに置き換えた
- 対象ファイルの絞り込み(`"$RECEIPTS_DIR"/*-codex-review.md`、`-blocked.md`除外)は変更していない
- 修正後、`bash -n`で構文を再確認した
- スクリプトから関数定義を`sed`で厳密に抽出し、スクラッチパッドの一時ファイル(実receiptsディレクトリの外)でテストした
- 実スクリプトで安全な範囲(`codexExec.enabled=false`)の健全性確認を再実行した

## なぜしたか

- 自己レビューで発見した「CRLF変換により日次上限が誤解除されうる」リスクへの対応として、人間から明示的な修正承認を得た
- 提示された実装方針(awkによるkey/value解析、CRLF/LF両対応)に沿って実装した

## 何をしなかったか

- `run_codex_process()`の実装
- `settings.json`の`codexExec.enabled`の変更(`false`のまま)
- 実Codex実行、外部API呼び出し
- git commit / push / merge / PR作成
- 既存レシートの改変・削除

## 追加確認(人間指定の7項目)

すべてスクラッチパッド上の一時ファイル(実receiptsディレクトリの外)、またはenabled=falseの安全な実行のみで確認した。

1. **LFの`codexRunStarted: true`を検出できること** → OK。`printf -- "- codexRunStarted: true\n"`のファイルに対し`receipt_marks_codex_started`が真を返した
2. **CRLFの`codexRunStarted: true`を検出できること** → OK。`printf -- "- codexRunStarted: true\r\n"`のファイルに対しても真を返した(修正前は偽になっていたはずの箇所)
3. **`codexRunStarted: false`は検出しないこと** → OK。LF版・CRLF版の両方で偽を返した
4. **説明文中の`codexRunStarted: true`を検出しないこと** → OK。
   「日次上限判定(check_daily_limit): ...`codexRunStarted: true`を含む」のような、
   コロンを複数含む解説文を模した一時ファイルに対し、偽を返した(1フィールド目が
   `codexRunStarted`と完全一致しないため)
5. **`*-codex-review-blocked.md`を日次上限対象に含めないこと** → OK。
   スクラッチパッド上に`*-codex-review-blocked.md`と`*-codex-review.md`の両方を作り、
   `check_daily_limit()`と同じグロブ(`*-codex-review.md`)でループさせたところ、
   `-blocked.md`は一致しなかった(既存の絞り込みロジックは変更していないため当然の結果だが、
   修正後も維持されていることを確認した)
6. **`bash -n scripts/run-codex-review.sh`が通ること** → OK
7. **git diffの確認** → 下記参照。変更は`scripts/run-codex-review.sh`のみ

## git diff 概要

`scripts/run-codex-review.sh`のみ変更。`check_double_lock()`の直後に`receipt_marks_codex_started()`を
新規追加し、`check_daily_limit()`内のgrep呼び出しをこの関数呼び出しに置き換えた
(+27行 / -6行、他ファイルへの変更なし)。

## 残っている既知の限定事項(今回の修正対象外、参考記録)

- 「残存リスクB」(ファイル名が偶然`*-codex-review.md`で終わる無関係なレシートが誤って
  対象に含まれる可能性)は今回未対応。今回の依頼はCRLF対応のみだったため対象外とした
- 自由記述欄(purpose/requested-by/focus)の無検閲は引き続き運用上の注意点として残る

## 人間に確認してほしいこと

- 今回の修正内容・テスト結果に問題がないか
- 「残存リスクB」への対応要否(対応する場合は別途承認をお願いします)
