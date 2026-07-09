# task: codex-review — Codex execによる読み取り専用セカンドオピニオン

目的: Phase 1.5(Multi-Agent Review Loop)において、重要レビュー・公開前レビュー・
危険操作前レビューに限り、Codex execを読み取り専用の「高価なセカンドオピニオン」として
限定利用する。対象はコード差分(`code`)と文書・設計(`document`)の両方を、
このタスク定義1つで扱う(QandA.md Q18: 最初は分割しない)。

設計の正本: `docs/superpowers/specs/2026-07-09-codex-exec-review-design.md`
確定方針: `QandA.md` Q7(構成決定)、Q16(二重ロック)、Q17(日次上限・機械判定キー)、Q18(配置先)

## 実装状況(2026-07-09時点)

このタスクの実行スクリプトは `scripts/run-codex-review.sh` である。
現時点では次のみ実装済みで、**Codexプロセスの起動は未実装のスタブ**である。

- 二重ロック判定(`codexExec.enabled`(settings.json) かつ 環境変数 `RUN_CODEX=1`)
- 日次上限判定(Asia/Tokyo、1日1回、`codexRunStarted: true` を機械判定キーとする)
- 入力検証(`review-type`/`scope`/`base-branch`/`files`/`purpose`/`requested-by`)
- 開始レシートの作成(ゲート通過時点で `codexRunStarted: true` を先に記録)

Codexプロセスの実際の起動、10分タイムアウト、JSONL抽出、Schema検証、結果分類は
`scripts/run-codex-review.sh` の `run_codex_process()` にTODOとして分離されており、
未実装である。したがって、このタスクを現時点で実行しても、レビュー結果は得られない
(ゲート・検証・レシート作成の動作確認にとどまる)。

## 実行前

- `CONTRACT.md` の「マルチエージェント運用の原則」と rubrics/safety.md を読む
- `.claude/loops/settings.json` の `codexExec.enabled` を確認する。`false` のままなら、
  このタスクを実行してもゲートで必ず拒否される(想定どおりの安全側動作)
- 環境変数 `RUN_CODEX=1` が明示的に設定されているか確認する(人間の明示指示がある場合のみ設定する)
- 重要レビュー・公開前レビュー・危険操作前レビューに該当するか、CONTRACT.mdの原則に照らして判断する

## 手順

1. レビュー種別を決める: コード差分なら `code`、文書・設計なら `document`
2. 入力を用意する
   - `code`: `scope`(`uncommitted` または `branch`)。`branch` の場合は `base-branch` も用意する
   - `document`: `files`(リポジトリルート配下の既存ファイル、ワイルドカード不可)
   - 共通: `purpose`(なぜ重要レビューが必要か)、`requested-by`(実行を判断した主体)、
     任意で `focus`(確認観点)
3. `scripts/run-codex-review.sh` を実行する

   ```bash
   RUN_CODEX=1 scripts/run-codex-review.sh \
     --review-type code \
     --scope uncommitted \
     --purpose "公開前レビュー" \
     --requested-by "human-approved review"
   ```

4. ゲートで拒否された場合、`blocked_by_gate` のレシートが自動生成される。理由を確認し、
   対応(承認取得、入力修正など)を行う。**ゲート拒否をバイパスしようとしない**
5. ゲートを通過した場合、開始レシート(`codexRunStarted: true`)が作成される。
   現時点では `run_codex_process()` が未実装のため、ここで処理は停止する。
   Codexは起動されていない
6. (将来、`run_codex_process()` 実装後)Codexの出力をSchema検証し、結果分類を確認する。
   指摘があれば、各指摘を `accepted`/`rejected`/`needs_human_decision`/`not_verified` に
   Claude Codeが再確認してから報告に反映する。Codexの指摘をそのまま採用しない

## 禁止事項

- ゲート(二重ロック・日次上限・入力検証)を回避する実装・実行
- `settings.json` の `codexExec.enabled` を、人間の明示承認なしに変更すること
- Codexの指摘をClaude Codeの再確認なしに最終報告へ採用すること
- プロンプト全文、JSONLイベント列、環境変数、認証情報、秘密情報のレシートへの記録
- 自動修正、push、merge、PR作成、外部送信

## 実行後

- `scripts/run-codex-review.sh` が自動生成したレシート(`blocked_by_gate` または開始レシート)を確認する
- 追加で確認・判断した内容があれば、同日の receipts に別レシートとして残す
  (「何をしたか、なぜしたか、何をしなかったか」を必ず書く)
- `state/checkpoint.json` を更新する
