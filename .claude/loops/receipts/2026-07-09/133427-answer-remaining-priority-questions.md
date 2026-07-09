# receipt: answer-remaining-priority-questions

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: answer-remaining-priority-questions（review-qandaの続き、単発の人間承認済み作業）
- 実行時刻: 2026-07-09 13:34:27
- 結果: 人間からQ14, Q17(残り), Q18〜Q25の確定回答が示され、QandA.mdおよび関連タスクファイルへ最小限反映した

## 何をしたか

- `QandA.md` の Q14, Q17(追加分), Q18, Q19, Q20, Q21, Q22, Q23, Q24, Q25 を「未回答」から「回答(2026-07-09、人間の承認により確定)」に更新した
- Q24の結論に従い、Q7本文に「クローズ注記」を追記した(構成決定でクローズ、実装詳細はQ16〜Q18等へ分割)
- Q20の確定方針(docs/note-draft.mdへの直接反映可否の基準)を `tasks/note-experiment.md` に反映した
- Q22の確定方針に従い、`schedule.yml` に `loop-status-report` を週次/手動実行候補として追記した(自動起動はしない)
- Q25の確定方針に従い、`tasks/daily-check.md` と `tasks/loop-status-report.md` に「未コミットの記録系ファイル一覧とコミット推奨」の手順・報告項目を追加した(AIはcommitしない旨も明記)
- `checkpoint.json` のnotesに今回の確定内容を追記した
- 既存レシートは改変していない

## なぜしたか

- 前回レシート(132554-answer-priority-questions.md)の「次回への引き継ぎ」に対する人間からの応答であり、CONTRACT.mdの完了条件(checkpoint更新)とQ9の方針(明示指示によるQandA.md追記)に合致する
- Q20/Q22/Q25は「現時点の方針」として実際に運用ファイルへ反映することが回答内容そのものに含まれており、かつ対象ファイル(tasks/*.md, schedule.yml)は過去にも同様の確定回答を受けて編集してきた実績がある範囲

## 何をしなかったか

- CLAUDE.md / CONTRACT.md / settings.json の実編集（Q14, Q18, Q19の将来TODOが指すCONTRACT.md/CLAUDE.md/settings.jsonへの反映は、CLAUDE.mdの規定により人間のみが編集可能なため未実施）
- Codex実装そのもの(schema/タスクファイルの実体作成、`scripts/write-codex-receipt.sh`等) — Q18はパスの決定のみで、実装はQ7クローズ方針により別途着手する
- `scripts/generate-loop-status.py` の改修(Q23の将来TODOが指すmultiAgent表示の分離)
- README.mdの編集(Q18将来TODOが示す`docs/superpowers/specs/`の位置づけ追記) — CLAUDE.mdは「README.mdは更新を提案する」としており、直接編集ではなく提案止まりとした(未実施)
- git commit / push / PR / merge
- ファイル削除、依存関係更新、秘密情報の記録

## 反映済みファイル一覧

| ファイル | 内容 |
|---|---|
| QandA.md | Q7クローズ注記、Q14, Q17(残り), Q18〜Q25 の回答反映 |
| tasks/note-experiment.md | docs/note-draft.md直接反映可否の基準(Q20) |
| schedule.yml | loop-status-reportを週次/手動候補として追加(Q22) |
| tasks/daily-check.md | 未コミット記録ファイル一覧・コミット推奨手順(Q25) |
| tasks/loop-status-report.md | 同上(Q25) |
| checkpoint.json | notes追記 |

## 次回への引き継ぎ

- CONTRACT.md/CLAUDE.md/settings.jsonへの反映(Q13, Q14, Q18, Q19の将来TODO)は人間の作業として残っている
- README.mdへの`docs/superpowers/specs/`位置づけ追記(Q18)は提案止まり、人間の判断待ち
- Codex実装(schema/タスクファイル作成、開始レシート先行方式の実装)はQ16〜Q18の設計が出揃ったため着手可能な状態
- 未コミットの `QandA.md` / `checkpoint.json` / `tasks/*.md` / `schedule.yml` / receipts / dream.md について、コミット可否の判断が引き続き必要(Q25の運用方針は確定済み)
