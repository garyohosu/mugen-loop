# receipt: qanda-review

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: qanda-review(QandA.mdの未回答項目への暫定回答づけ)
- 実行時刻: 2026-07-07 18:49:07

## git status

```
?? QandA.md
```
(このレシート作成前の状態。QandA.mdは今回の作業対象そのもの)

## 何をしたか

- QandA.md の8つの未回答項目すべてに、「質問/暫定回答/理由/現時点で採用する方針/将来のTODO」の形式で追記した
- 人間から与えられた回答方針(Phase 1のみ、手動トリガー、GitHub API未実装、Windows対応はGit Bash優先、Codex execはread-onlyレビュアーでRUN_CODEX=1ゲート、等)に沿って各項目を判断した
- 反映が必要と判断したものを、破壊的変更なしで以下に最小限追記した
  - `.claude/loops/tasks/daily-check.md`: run-daily-check.shが人間向け補助ユーティリティである旨(実行前セクション)と、TODO検索の除外ディレクトリ(`.git/`, `node_modules/`, `.claude/loops/receipts/`)を追記
  - `.claude/loops/tasks/pr-hunter.md`: 認証方法TODOに、読み取り専用PAT(`GITHUB_TOKEN`)を優先候補とする暫定メモを追記(実装はしない)
  - `contract.local.example.md`: Windows環境メモに「PowerShell対応は将来TODO」の一文を追記
  - `todo.md`: checkpoint.jsonのヘルパースクリプト化とPowerShell対応を「いつか」セクションに追記し、Phase 1.5(マルチエージェント化)の暫定方針(Claude Codeメイン/Codex exec read-onlyレビュアー/RUN_CODEX=1ゲート/Claude Codeによる再確認)を新規セクションとして追記
  - `.claude/loops/state/checkpoint.json`: notesを日本語に統一し、lastRun/lastTask/statusを今回の実行内容で更新(契約上許可されている更新範囲内)

## なぜしたか

- CLAUDE.md/CONTRACT.mdの「不明点がある場合は作業を止める」を裏返すと、安全に決められる範囲の暫定方針は放置せず記録すべき、という今回の人間からの明示的な依頼に基づく
- CONTRACT.mdの「変更してよい範囲」(receipts新規追加、checkpoint.json更新)を守りつつ、「変更してはいけない範囲」(CONTRACT.md/CLAUDE.md/settings.json/rubrics/既存レシート)には手を入れなかった
- tasks/*.md, todo.md, contract.local.example.md への追記は、CONTRACT.mdの「上記以外への書き込みは、人間の明示的な指示があるときのみ」に基づき、今回のチャットでの明示的な依頼を根拠として実施した

## 何をしなかったか

- CONTRACT.md / CLAUDE.md への変更は行わなかった。CLAUDE.md自身が「変更してはいけない範囲: CONTRACT.md/CLAUDE.md/settings.json/rubrics — 変更は人間のみ」と定めているため、QandA.md #7(マルチエージェント化)の方針をこれらに反映することは提案にとどめ、実際の編集はtodo.mdへの記載のみとした
- README.mdは変更しなかった。今回の8項目の暫定方針は既存のREADME記述と矛盾せず、追記が必要な箇所を見つけられなかったため
- pr-hunter.mdへのGitHub接続の実装、Codex exec連携の実装は一切行わなかった(いずれも設計メモ・優先候補の記録のみ)
- commit / push / merge / PR作成は行わなかった(人間の承認なし)
- 依存関係の追加・更新、ファイルの削除は行わなかった
- settings.json / rubrics の変更は行わなかった

## 人間に確認してほしいこと

- QandA.md #7(マルチエージェント化)でtodo.mdに記録した暫定方針(Claude Codeメイン/Codex exec read-onlyレビュアー/RUN_CODEX=1ゲート)を、CONTRACT.md/CLAUDE.mdへ正式に反映するかどうかは人間の判断が必要(AI自身はこれらのファイルを変更できない)
- QandA.md #6のPAT優先候補、#4のヘルパースクリプト方針、#5のPowerShell対応は、いずれも「将来TODO」として記録した段階であり、実装着手のタイミングは人間が決めること
- 今回の変更一式(QandA.md, tasks/*.md, todo.md, contract.local.example.md, checkpoint.json, dream.md, 本レシート)はコミット前の状態。コミットするかどうかは人間の判断待ち

## メモ

- QandA.mdの8項目すべてに回答したが、いずれも「Phase 1の範囲内で安全に決められる暫定方針」であり、最終決定ではない。運用実績が積み重なった段階で見直す前提とする
