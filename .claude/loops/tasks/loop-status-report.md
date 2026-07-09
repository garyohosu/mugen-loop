# task: loop-status-report — mugen-loop状態レポート生成タスク

目的: mugen-loop自身の現在状態(checkpoint、receipts、QandA、todo、各種ドキュメントの有無、
安全設定)を読み取り、`docs/loop-status.md` に1枚のダッシュボードとしてまとめる。
**このタスクは観察と報告のみ。自動修正・push・merge・PR作成は行わない。**

## 入力ファイル

- `.claude/loops/state/checkpoint.json`
- `.claude/loops/receipts/` 配下の各レシート
- `QandA.md`
- `todo.md`
- `README.md`
- `CONTRACT.md`
- `CLAUDE.md`
- `docs/note-draft.md`
- `.claude/loops/settings.json`

## 出力ファイル

- `docs/loop-status.md`(このファイルのみ。他のファイルは生成しない)
- `docs/loop-status.md` は、CLAUDE.md「変更してよい範囲」およびCONTRACT.md「許可する作業」に
  loop-status-reportタスク実行時の出力先として正式に許可された生成物である(2026-07-08、
  QandA.md Q12の確定方針による)。git管理対象とし、通常のコミットフローに含めてよい

## 実行手順

1. `python scripts/generate-loop-status.py` を実行する
   - 外部API・GitHub APIには接続しない(スクリプト自体もローカルファイル読み取りのみ)
2. 生成された `docs/loop-status.md` を確認する
   - Summary、Latest Receipts、QandA Status、TODO Summary、Document Check、
     Safety Status、Notes の各セクションが揃っているか
   - 秘密情報が紛れ込んでいないか(通常は紛れ込まない設計だが念のため確認する)
3. 内容に問題があれば、スクリプトの出力ロジックの改善提案をまとめる(このタスクでは実装しない)
3.5. `git status --short` を確認し、未コミットの記録系ファイル(receipts、checkpoint.json、
     docs/loop-status.md、dream.md、QandA.md)があれば一覧化し、レシートと報告にコミット推奨として
     含める。AIはcommitしない(QandA.md Q25)
4. receipts にレシートを残す(「何をしたか、なぜしたか、何をしなかったか」)
5. state/checkpoint.json を更新する(lastRun / lastTask のみ。Q10の確定方針に従う)

## 禁止事項

- ファイルの削除
- `docs/loop-status.md` 以外のファイルへの書き込み(checkpoint.json とレシートの更新を除く)
- 外部API・GitHub APIへの接続
- 秘密情報の表示・記録
- push / merge / PR作成

## 完了条件

- `docs/loop-status.md` が最新の状態で生成されている
- レシートに実行結果の要約が記録されている
- state/checkpoint.json が更新されている

## レシートに残す内容

- 実行日時とコマンド
- 生成された `docs/loop-status.md` の要約(Summary・Safety Statusの値など)
- 発見した異常や不整合があれば、その内容と提案
- 何もしなかったこと(自動修正はしていない、等)
