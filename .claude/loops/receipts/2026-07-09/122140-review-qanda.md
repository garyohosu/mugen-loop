# receipt: review-qanda

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: review-qanda
- 実行時刻: 2026-07-09 12:21:40
- 結果: リポジトリレビューを実施し、不明点を QandA.md に Q13〜Q25 として追記した

## 何をしたか

- CONTRACT / CLAUDE / settings / schedule / tasks / rubrics / scripts / Codex設計書 / checkpoint / 既存Q1〜Q12 / git状態を読み取りレビューした
- 契約の不整合、Phase 1.5/Codex設計の未決事項、運用上の曖昧点を洗い出した
- 人間の明示指示に基づき `QandA.md` へ Q13〜Q25 を追記した（回答は未記入・判断待ち）
- 既存レシートは改変していない

## なぜしたか

- 人間から「レビューして不明点をQandA.mdに書いて」と明示指示があった（Q9の方針に合致）
- CONTRACT.md の目的（判断材料の整理）と Phase 1 / 1.5 の範囲（実行より観察・提案）に沿うため

## 何をしなかったか

- Q13〜Q25 への回答・暫定方針の確定（人間判断待ち）
- CONTRACT.md / CLAUDE.md / settings.json / rubrics / 設計書の修正（安全の根幹・設計変更は人間のみ）
- Codex / Antigravity の実装、タスク新規作成
- git commit / push / PR / merge
- ファイル削除、依存関係更新、秘密情報の記録

## 主な発見（要約）

| ID | 題 | 重大度 | 分類 |
|----|----|--------|------|
| Q13 | CONTRACT承認リストと loop-status 許可の不整合 | 中 | 即修正候補 |
| Q14 | dream.md の書き込み許可 | 中 | 要判断 |
| Q15 | メインエージェント定義（Claude Code固定か） | 高 | 要判断 |
| Q16 | Codex enabled と RUN_CODEX の関係 | 中 | 要判断 |
| Q17 | Codex日次上限の日付境界とレシート形式 | 中 | 要判断 |
| Q18 | Schema/タスク/設計書の配置先 | 低 | 要判断 |
| Q19 | maxChangedFiles:0 の解釈 | 中 | 要判断 |
| Q20 | note-draft 反映タイミング | 中 | 要判断 |
| Q21 | mugen-loop-viewer との公式関係 | 中 | 要判断/保留 |
| Q22 | schedule への loop-status-report 登録 | 低 | 要判断 |
| Q23 | multiAgent:true の意味 | 低 | 要判断 |
| Q24 | Q7 と Codex設計書のクローズ方針 | 低 | 要判断 |
| Q25 | 未コミット成果物の運用 | 中 | 要判断 |

## 提案

- 優先して判断してほしい順: Q15 → Q13 → Q16/Q17 → Q14/Q19/Q20/Q25 → その他
- Q13 は文言同期のみなので、人間が CONTRACT.md を1行直せば閉じやすい
- Q16〜Q18 が決まると Codex 実装に進みやすい

## 人間に確認してほしいこと

- Q13〜Q25 の回答（または優先して答える項目の指定）
- 未コミットの `QandA.md` / receipts / checkpoint / dream 等をいつコミットするか

## 次回への引き継ぎ

- 回答が付いた項目から tasks / CONTRACT / settings への最小反映を提案する（勝手に CONTRACT は直さない）
- Codex 実装は Q16〜Q18 と設計書承認後
