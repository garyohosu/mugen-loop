# task: daily-check — 毎日の見回りタスク

目的: プロジェクトの状態を毎日確認し、判断材料を整理して報告する。
このタスクではファイルの変更は行わない(receipts/ と state/checkpoint.json の更新を除く)。

## 実行前

- CONTRACT.md を読む
- rubrics/safety.md のチェックリストを満たせるか確認する

## 手順

1. git statusの確認
   - `git status --short` と `git log --oneline -5` を実行し、未コミットの変更や直近の動きを把握する
2. 基本ドキュメントの存在確認
   - README.md、CLAUDE.md、CONTRACT.md が存在するか確認する
   - 欠けていれば停止条件として報告する
3. settings.jsonの確認
   - .claude/loops/settings.json を読み、安全設定(dryRun、allowPush等)が想定どおりか確認する
   - 想定と異なる場合は変更せず、その旨を報告する
4. checkpoint.jsonの確認
   - .claude/loops/state/checkpoint.json を読み、前回の実行・現在のフェーズ・引き継ぎ事項(notes)を確認する
5. receipts保存先の確認
   - .claude/loops/receipts/ が存在し、書き込めることを確認する
6. TODOを探す
   - リポジトリ内のファイルから `TODO` を検索し、一覧にまとめる
7. 結果の要約
   - 上記の結果を「問題なし / 要注意 / 要対応」に分類して要約する
8. 提案の作成
   - 改善が必要な点があれば、変更内容と理由を提案としてまとめる
   - **変更は行わず、提案だけ行う**

## 実行後

- receipts/YYYY-MM-DD/ にレシートを残す(scripts/write-receipt.sh 参照)
- 「何をしたか、なぜしたか、何をしなかったか」を必ず書く
- state/checkpoint.json の lastRun / lastTask / status を更新する
