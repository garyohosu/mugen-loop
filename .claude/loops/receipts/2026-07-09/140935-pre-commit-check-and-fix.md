# receipt: pre-commit-check-and-fix

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: pre-commit-check-and-fix(codex-review安全ゲート実装のコミット前確認)
- 実行時刻: 2026-07-09 14:09:35
- 結果: 人間指定の8項目を確認する過程で、日次上限判定(`check_daily_limit`)の誤検出バグを発見し修正した。修正後、8項目すべて確認済み

## 何をしたか(人間指定の8項目の確認結果)

1. **2件のブロックレシートに`codexRunStarted: true`が入っていないこと** → 確認OK。
   `135933-codex-review-blocked.md`、`135943-codex-review-blocked.md`ともに`codexRunStarted`行は
   `false`のみで、`true`は含まれない
2. **ブロックレシートが`codexRunStarted: false`または未実行扱いとして記録されていること** → 確認OK。
   両ファイルとも`- codexRunStarted: false`、`codexRunResult: blocked_by_gate`
3. **日次上限判定が`blocked_by_gate`のレシートを実行済みとして誤カウントしないこと** →
   **確認の過程でバグを発見**。修正後は誤カウントしないことを確認(詳細は下記)
4. **`codexExec.enabled=false`の状態では必ずCodex起動前に止まること** → 確認OK。
   `node -e`で`settings.json`の`codexExec.enabled`が`false`であることを確認したうえで、
   `RUN_CODEX=1`を付けて再実行しても二重ロックで拒否され、`140737-codex-review-blocked.md`が
   作成された。Codexプロセスへは到達していない
5. **`run_codex_process()`がmainから呼ばれていないこと** → 確認OK。
   `main()`の本体は`check_double_lock` → `check_daily_limit` → `validate_input` →
   `write_start_receipt`のみで、`run_codex_process`という文字列は`main()`内に一切現れない
6. **`bash -n scripts/run-codex-review.sh`で構文エラーがないこと** → 確認OK(修正前・修正後とも)
7. **JSON SchemaがJSONとして妥当であること** → 確認OK。
   `node -e "JSON.parse(...)"`でパース成功、`type: object`、`required`5項目を確認
8. **`git diff --stat`と`git status --short`の再確認** → 下記「最終git状態」参照

## 発見したバグと修正(項目3)

`check_daily_limit()`は当初、`grep -rl "codexRunStarted: true" "$RECEIPTS_DIR"`で
その日のreceiptsディレクトリ全体を対象に文字列検索していた。

この実装は、`.claude/loops/receipts/2026-07-09/140114-codex-review-gate-implementation.md`
(本セッションで作成した実装レシート、地の文で`codexRunStarted: true`という語を解説として使っていた)
にヒットし、**実際にはCodexを一度も起動していないのに「本日は実行済み」と誤判定して以後の
codex-review実行を全てブロックする**バグだった。項目3の確認作業中に実際に`grep`を実行して発見した。

修正: 検索対象をスクリプト自身が作る開始レシートのファイル名パターン(`*-codex-review.md`。
`*-codex-review-blocked.md`や他の作業レシートは対象外)に限定し、判定も`grep -qx`による
行の完全一致(`- codexRunStarted: true`)に変更した。修正後、`bash -n`で構文を再確認し、
現在のreceipts配下(該当ファイルなし)に対して誤検出しないことを確認した。

## なぜしたか

- 人間から明示された8項目のコミット前確認指示に従った
- 項目3の確認中に偶然ではなく必然的にバグを発見した(実装レシートを先に書いていたため)。
  「動作確認のために書いた記録が、機能そのものを壊す」という発見だったため、コミット前に必ず修正する
  必要があると判断した

## 何をしなかったか

- 既存レシート(`140114-codex-review-gate-implementation.md`を含む、本セッション中に作成した
  他のレシート)の書き換え・削除。CONTRACT.mdの「既存レシートの改変は禁止」に従い、
  発見した事実は本レシートに新規追記する形で記録した
- `settings.json`の`codexExec.enabled`の変更(`false`のまま)
- 実Codex実行、commit以外のgit操作(push/merge/PR)

## 最終git状態(修正反映後)

```
 M .claude/loops/state/checkpoint.json
 M dream.md
?? .claude/loops/receipts/2026-07-09/135933-codex-review-blocked.md
?? .claude/loops/receipts/2026-07-09/135943-codex-review-blocked.md
?? .claude/loops/receipts/2026-07-09/140114-codex-review-gate-implementation.md
?? .claude/loops/receipts/2026-07-09/140737-codex-review-blocked.md
?? .claude/loops/receipts/2026-07-09/140935-pre-commit-check-and-fix.md (本ファイル)
?? .claude/loops/schemas/codex-review-output.schema.json
?? .claude/loops/tasks/codex-review.md
?? scripts/run-codex-review.sh
```

`git diff --stat`(追跡対象ファイルのみ): `checkpoint.json`(+3/-1)、`dream.md`(+20)

## 結論

8項目すべて確認済み、1件のバグを発見・修正済み。コミットして問題ない状態と判断する。
