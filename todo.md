# todo.md — 人間(設計者)が次にやること

mugen-loopの人間側タスクリスト。AIはこのファイルを読んで状況を把握してよいが、
完了のチェックや削除は人間が行う。

## すぐやる(次にPCを開いたとき)

- [ ] CONTRACT.md を読み、許可・禁止・停止条件が意図した境界線どおりか確認する
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
