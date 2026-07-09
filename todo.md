# todo.md — 人間(設計者)が次にやること

mugen-loopの人間側タスクリスト。AIはこのファイルを読んで状況を把握してよいが、
完了のチェックや削除は人間が行う。

## すぐやる(次にPCを開いたとき)

- [x] CONTRACT.md を読み、許可・禁止・停止条件が意図した境界線どおりか確認する(2026-07-09、人間が確認・問題なしと判断)
- [ ] docs/note-draft.md を読み、記事のトーンと構成を確認する(修正指示はチャットでOK)
- [ ] blog-review と note-experiment の役割分担(既存記事の校正 / 実験の記事化)がこの理解で良いか判断する
- [ ] Claude Codeに「daily-checkタスクを実行して」と頼み、報告→レシートの流れを一度試す

## 近いうち(今週〜来週)

- [ ] contract.local.example.md を contract.local.md にコピーし、自分の運用時刻・確認対象を書く(秘密情報は書かない)
- [ ] 夜に「note-experimentタスクを実行して」と頼み、receipts/dream.mdからnote-draft.mdへの追記案が作れるか検証する
- [ ] blog-review を schedule.yml に再登録するか決める(現在の夜枠は note-experiment)
- [ ] receipts/ にたまったレシートを読み、AIの報告が正確か確認する(Phase 2「提案」へ進む判断材料)

## pr-hunter をGitHub接続する前に決めること

- [ ] GitHub CLI (`gh`) を使うか、GitHub Actionsから起動するかを決める
- [ ] 認証方法を決める(読み取り専用スコープのトークンから始める。リポジトリには絶対に書かない)
- [ ] 対象リポジトリを contract.local.md に定義する
- [ ] privateリポジトリの内容をレシートにどこまで書いてよいか決める

## note記事の公開前に

- [ ] docs/note-draft.md にリポジトリ公開URLを貼る
- [ ] 実際のレシート例を1つ記事に引用する
- [ ] スクリーンショットを入れるか検討する
- [ ] rubrics/writing.md の基準でセルフチェック(またはAIにレビューさせる)してから公開する

## いつか(ループを育てる)

- [ ] スケジューラ(cron / タスクスケジューラ / GitHub Actions)から schedule.yml どおりに自動起動する仕組みを作る
- [ ] receipts を集計する「働きぶりレポート」タスクを設計する
- [ ] 実績のあるタスクから、承認付きで実行権限を渡す(settings.json は一つずつ緩める)
- [ ] checkpoint.json の構造が複雑化したら、読み書き・検証用のヘルパースクリプトを scripts/ 配下に用意する(QandA.md #4)
- [ ] Windows PowerShell(.ps1)対応、またはPython/Node.jsでのクロスプラットフォーム実装を検討する(QandA.md #5)

## Phase 1.5(Multi-Agent Review Loop)— 2026-07-07 人間の承認により正式採用済み(QandA.md #7)

構成・ゲート・再確認のルールは CONTRACT.md「マルチエージェント運用の原則」、CLAUDE.md、
`.claude/loops/settings.json` に反映済み。ここでは未完了の作業だけを残す。

優先順位の考え方(2026-07-08、人間の承認により確定):

1. Loop Status Report Generator(Phase 1の観察・報告機能)を先に完成させる。
   これは完了・コミット済み(`scripts/generate-loop-status.py`、`docs/loop-status.md`、
   `.claude/loops/tasks/loop-status-report.md`)。Phase 1(観察と報告)を固めることを、
   Phase 1.5の新機能より優先した。
2. Codex呼び出し設計は、その次に着手する残TODOとして扱う。まだ実装しない。
   設計ドキュメント化(呼び出し方法・権限・タイムアウト・レシート記録方法を決める)を先に行い、
   実装はその後の別作業とする。
3. Codex exec は「高価なセカンドオピニオン」であり、常用のレビュー係にはしない。
   重要レビュー・公開前レビュー・危険操作前レビューに限定利用する方針は変わらない
   (CONTRACT.md「マルチエージェント運用の原則」、QandA.md #7参照)。
4. Codex呼び出しを設計する際は、次を前提にする:
   - `RUN_CODEX=1` が明示的に指定された場合のみ実行する(デフォルトは無効)
   - read-only reviewer(ファイル変更・push・merge・PR作成はさせない)
   - `maxRunsPerDay` などの利用枠制限を設ける
   - 利用枠に達した場合はAntigravityへfallbackする
5. 実装(具体的なCLI呼び出しコード、タスク定義の新規作成)はまだ行わない。
   今回は優先順位と前提条件を明文化しただけ。

- [x] 構成の決定: Claude Codeがメイン(最終判断者)、Codex execはread-only reviewer、Antigravityはlimit時のfallback、Claude Code self-reviewは最低限のfallback
- [x] ゲートの決定: Codex execは環境変数 `RUN_CODEX=1` が明示的に指定された場合のみ実行する
- [x] 再確認ルールの決定: 外部レビュアーの結果は最終判断とせず、Claude Codeが必ず再確認してから報告・提案に反映する
- [x] Loop Status Report Generator(Phase 1の観察・報告機能)を先に完成させる(2026-07-08、完了・コミット済み)
- [ ] Codex execの具体的な呼び出し方法(CLIコマンド・権限・タイムアウト)とレシートへの記録方法を人間と設計する(次の作業。まだ実装しない)
- [ ] Antigravity fallbackの具体的な起動条件(Codexのlimit検知方法など)を決める
- [ ] 上記が固まったら `.claude/loops/tasks/` に新規タスク定義を追加する
- [ ] (低優先度、2026-07-09の自己レビューで発見・2026-07-09に対応保留と確定)
      `scripts/run-codex-review.sh` の `check_daily_limit()` は、ファイル名が
      たまたま `*-codex-review.md` で終わる無関係なレシート(命名衝突)を
      日次上限判定の対象に含めてしまう可能性がある(「残存リスクB」)。
      CRLF対応(2026-07-09、`receipt_marks_codex_started()`導入)は完了済みだが、
      この命名衝突リスクへの対応は見送った。対応する場合は、対象ファイルの識別を
      ファイル名パターンではなく本文中の一意なマーカー(例: レシート先頭の
      専用フロントマター)に変更するなどの案を検討する
