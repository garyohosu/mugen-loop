# firststep: mugen-loop 初期構築指示

あなたは Claude Code として、このリポジトリ `mugen-loop` を「安全なプロアクティブAIループ実験用テンプレート」として初期構築してください。

## 目的

`mugen-loop` は、AIエージェントをチャットではなく、契約・スケジュール・評価基準・状態保存・監査ログで運用するための最小テンプレートです。
最初の段階では、勝手にコードを修正・push・mergeするのではなく、状況確認、提案、記録までを行う安全設計にしてください。

## 重要な制約

- 人間の承認なしに git push しない
- 人間の承認なしに Pull Request を作らない
- 人間の承認なしに merge しない
- 人間の承認なしにファイル削除しない
- 秘密情報、APIキー、トークンを表示・記録しない
- 本番環境や外部サービスへ変更を反映しない
- まずはローカルで安全に読めるテンプレートとして作る
- 実行スクリプトは破壊的操作をしない
- 不明点があれば作業を止めて、TODOコメントまたはREADMEに明記する

## 作成するファイル構成

```
mugen-loop/
├── README.md
├── CLAUDE.md
├── CONTRACT.md
├── contract.local.example.md
├── .gitignore
├── .claude/
│   └── loops/
│       ├── settings.json
│       ├── schedule.yml
│       ├── rubrics/
│       │   ├── code.md
│       │   ├── writing.md
│       │   └── safety.md
│       ├── tasks/
│       │   ├── daily-check.md
│       │   ├── pr-hunter.md
│       │   └── blog-review.md
│       ├── state/
│       │   └── checkpoint.json
│       └── receipts/
│           └── .gitkeep
└── scripts/
    ├── run-daily-check.sh
    └── write-receipt.sh
```

## 各ファイルの役割

### README.md
- このリポジトリの目的を書く
- 「mugen-loop」とは何かを初心者にも分かるように説明する
- フォルダ構成を説明する
- Claude Codeでの使い方を書く
- 最初の安全な使い方を書く
- 危険な使い方と禁止事項を書く
- 今後の拡張案を書く
- 日本語で書く
- 表は使わない

### CLAUDE.md
Claude Codeがこのリポジトリで作業するときに必ず守る指示を書く。
内容は以下を含める:
- このプロジェクトの目的
- 最優先の安全ルール
- 作業前に読むべきファイル
- 作業手順
- 作業後に必ず receipts に記録すること
- 勝手にpush/mergeしないこと
- README.mdを常に最新に保つこと
- 変更した場合は理由を書くこと

### CONTRACT.md
AIループが守る契約を書く。
内容は以下を含める:
- 目的
- 許可する作業
- 禁止する作業
- 完了条件
- 停止条件
- 人間の承認が必要な操作
- ログに残すべき内容

### contract.local.example.md
個人用の上書き設定例を書く。
実ファイル `contract.local.md` はgit管理しない前提にする。
例として以下を書く:
- 対象リポジトリ名
- 実行したい時間
- 通知先のメモ欄
- ローカル環境依存のメモ欄
秘密情報は絶対に書かないよう注意書きを入れる。

### .gitignore
以下を含める:
- contract.local.md
- .env
- *.log
- node_modules/
- __pycache__/
- .DS_Store
- tmp/
- .claude/loops/state/*.local.json

### .claude/loops/settings.json
安全な初期設定を書く。
例:
- dryRun: true
- allowPush: false
- allowMerge: false
- allowDelete: false
- maxChangedFiles: 0
- maxRuntimeMinutes: 15
- requireHumanApproval: true
- receiptRequired: true

### .claude/loops/schedule.yml
実行スケジュール例を書く。
実際に自動実行するファイルではなく、Claude Codeや外部スケジューラが読む設計メモとして作る。
例:
- daily-check: 毎朝9時
- pr-hunter: 平日朝
- blog-review: 夜
各タスクは dry-run 前提にする。

### .claude/loops/rubrics/code.md
コード確認の評価基準を書く。
例:
- 変更理由が明確か
- テスト方法があるか
- 影響範囲が説明されているか
- 不要な大規模変更がないか
- 秘密情報に触れていないか

### .claude/loops/rubrics/writing.md
文章確認の評価基準を書く。
例:
- タイトルと本文が一致しているか
- 読者が初心者でも分かるか
- 断定しすぎていないか
- 参考リンクやTODOが明確か
- 誤字脱字がないか

### .claude/loops/rubrics/safety.md
安全基準を書く。
例:
- 破壊的操作をしない
- 外部送信しない
- 秘密情報を表示しない
- 勝手に依存関係更新しない
- 実行前に人間の承認が必要な操作を列挙する

### .claude/loops/tasks/daily-check.md
毎日の見回りタスクを書く。
内容:
- git status確認
- README/CONTRACT/CLAUDE.mdの存在確認
- state/checkpoint.json確認
- receipts保存先確認
- TODOの抽出
- 実行結果の要約
- 変更は行わず提案まで

### .claude/loops/tasks/pr-hunter.md
PR/Issue確認タスクの設計を書く。
現時点ではGitHub API接続を前提にしない。
将来GitHub CLIやGitHub Actionsに接続するためのTODOを書く。
内容:
- open PR確認の想定
- CI失敗確認の想定
- レビューコメント確認の想定
- 修正案の作成
- 人間承認待ちで停止

### .claude/loops/tasks/blog-review.md
ブログ記事レビュー用タスクを書く。
内容:
- draft記事のタイトルとH1確認
- 参考リンク確認
- 読みやすさ確認
- 誤字脱字確認
- 公開前TODOの抽出
- 勝手に公開しない

### .claude/loops/state/checkpoint.json
初期状態を書く。
例:

```json
{
  "project": "mugen-loop",
  "version": "0.1.0",
  "lastRun": null,
  "lastTask": null,
  "status": "initialized",
  "dryRun": true,
  "notes": []
}
```

### scripts/run-daily-check.sh
安全なダミースクリプトを書く。
内容:
- bash
- set -euo pipefail
- 現在時刻を表示
- git status --short を表示
- .claude/loops/state/checkpoint.json の存在確認
- receipts用ディレクトリを作成
- 破壊的操作はしない
- push/merge/deleteはしない

### scripts/write-receipt.sh
receiptsに作業ログを作る安全なスクリプトを書く。
内容:
- bash
- set -euo pipefail
- 今日の日付のディレクトリを作成
- receipt markdownを生成
- 実行タスク名、時刻、git status、メモ欄を書く
- 秘密情報を書かない注意コメントを入れる

## 実装後に行うこと

1. 作成・変更したファイル一覧を表示する
2. 重要な設計判断を短く説明する
3. `README.md` の要点を要約する
4. 次に人間が確認すべきことを書く
5. コミットはしない

## README.mdのトーン

- 日本語
- 初心者にも分かりやすい
- これは「AIを勝手に暴走させる道具」ではなく「AIに安全な仕事の枠を与えるテンプレート」と説明する
- 「最初は報告だけ」「次に提案」「最後に承認付き自動化」という段階的な育て方を書く
- 表は使わない
