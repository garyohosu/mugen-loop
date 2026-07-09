# receipt: answer-priority-questions

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: answer-priority-questions（review-qandaの続き、単発の人間承認済み作業）
- 実行時刻: 2026-07-09 13:25:54
- 結果: 前回レシート(122140-review-qanda)が提案した優先順位に従い、Q15・Q13・Q16・Q17について人間の回答を得て QandA.md / checkpoint.json に反映した

## 何をしたか

- 人間に「次にやることは？」と問われ、未コミット状態と優先候補Q15/Q13/Q16/Q17を提示した
- AskUserQuestionでQ15・Q13・Q16・Q17を提示し、いずれも推奨案（Claude Code固定／許可作業を正として同期／二重ロック／Asia/Tokyo）で承認を得た
- `QandA.md` の該当4項目を「未回答」から「回答(2026-07-09、人間の承認により確定)」に更新した（Q17は日付境界のみ確定、判定形式など残り3点は未確定のまま明記）
- `checkpoint.json` の notes に今回の確定内容を日本語で追記した
- 既存レシートは改変していない

## なぜしたか

- 前回レシートの「人間に確認してほしいこと」に対する人間からの応答であり、CONTRACT.mdの完了条件(checkpoint更新)とQ9の方針(明示指示によるQandA.md追記)に合致する

## 何をしなかったか

- CONTRACT.md の実編集（Q13の結論はCONTRACT.md「人間の承認が必要な操作」の文言修正を要するが、CLAUDE.mdにより人間のみが編集可能なため未実施。次回人間がCONTRACT.mdを編集する際の根拠として回答をQandA.mdに残した）
- Q17の残り3項目（判定対象、`codexRunStarted`キーの埋め込み方法、失敗時の記録方法）の確定
- Q14, Q18〜Q25 への回答（未回答のまま）
- git commit / push / PR / merge
- ファイル削除、依存関係更新、秘密情報の記録

## 次回への引き継ぎ

- Q13の結論（承認リスト文言同期）をCONTRACT.mdに反映するのは人間の作業
- Q16の「二重ロック」確定を受け、Codex exec実装（CLI呼び出し部分）を設計書に沿って進められる状態になった
- Q17の残り3項目、Q14/Q18〜Q25は引き続き人間の判断待ち
- 未コミットファイル（QandA.md, checkpoint.json, docs/loop-status.md, dream.md, receipts）はQ25の結論待ちのため、今回もコミットは行っていない
