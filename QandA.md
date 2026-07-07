# QandA.md — mugen-loop レビューに伴う不明点・確認事項

リポジトリ内の各種ファイル（`CONTRACT.md`, `CLAUDE.md`, `.claude/loops/` 配下の設定・タスク・評価基準、各種スクリプト、および記事下書き）をレビューし、自律ループの設計において懸念される点や仕様として明確にしたい事項を整理しました。

各項目には、2026-07-07時点の回答（設計方針の判断）を追記しています。回答はPhase 1(Report Loop)の範囲内で安全側に決めたものであり、実装や自動化そのものは行っていません（Q7を除く。Q7はPhase 1.5として人間の承認を得て正式採用しました）。

表は使わず、質問ごとに見出しと項目で整理しています。

---

### Q1. 実行トリガーの方法

質問:
`.claude/loops/schedule.yml` は「自動実行の設計メモ（外部スケジューラ接続前）」と定義されており、実際の自動起動（cron等への登録）は「いつかやる」タスク（`todo.md`）となっています。現段階では、人間が `Claude Code` などのチャットUIで「daily-checkタスクを実行して」と手動指示を出すことだけを想定していますか？それとも、現時点でも `schedule.yml` の記述を読み取って順番に実行するような、簡易的なローカル実行用ランナー（スクリプト等）を設ける予定はありますか？

暫定回答:
現段階では、人間がチャットUI（Claude Code）で「daily-checkタスクを実行して」等と手動指示することのみを想定する。`schedule.yml` を読んで順番に実行するランナースクリプトは、現時点では作らない。

理由:
Phase 1(Report Loop)の目的は「勝手に見回り、判断材料を整理し、ログを残すこと」であり、トリガー自体の自動化はこのフェーズの範囲を超える。`schedule.yml` は既にREADME/CLAUDE.mdで「設計メモであり、実際の起動は人間の承認後」と明記されており、現行方針と一致する。

現時点の方針:
`schedule.yml` は設計メモのまま維持し、変更しない。トリガーは人間の手動指示のみとする。ローカルランナーは作らない。

将来TODO:
cron / GitHub Actions / Claude Codeのスケジュール機能などとの接続は、Phase 1の実績（receiptsの精度）を見たうえで人間が判断する（`todo.md`の「いつか」に既存記載あり）。

---

### Q2. run-daily-check.sh の位置づけ

質問:
`scripts/run-daily-check.sh` は現在時刻、`git status`、`checkpoint.json` の存在を確認するシェルスクリプトであり、`daily-check.md`（タスク定義）にはAIが実行すべき手順が書かれている。`daily-check.md` の手順内にはこのスクリプトを呼び出す明示的な指示がないため、これが「人間が手動で状態を確認するためのユーティリティ」なのか、「AIのタスク手順の一部」なのかを明確にしたい。

暫定回答:
`run-daily-check.sh` は「人間が手動で状態を素早く確認するための補助ユーティリティ」であり、AIの`daily-check`タスク手順の必須ステップではない。AIは`daily-check.md`の手順に従い、対象ファイルを直接読み取って確認を行う。

理由:
現状の`daily-check.md`の手順にスクリプト呼び出しの指示がなく、CLAUDE.mdもタスク定義に従うことを求めている。AIがシェルスクリプト実行に依存する設計にすると、Bashが使えない環境で手順全体が止まるリスクがある。ファイル読み取りだけで完結する設計の方が安全側。

現時点の方針:
`daily-check.md` に、`run-daily-check.sh` は人間向けの補助ユーティリティであり、AIの手順としては任意であることを明記済み。

将来TODO:
AIが直接スクリプトを実行する運用に統一するかは、Phase 2（提案）以降、実績を見て判断する。

---

### Q3. TODO検索の除外対象

質問:
`daily-check.md` の手順6「リポジトリ内のファイルから `TODO` を検索し、一覧にまとめる」について、過去のレシート（`.claude/loops/receipts/`）や `.git`, `node_modules` など、検索から確実に除外すべきディレクトリはあるか。過去のレシート内のTODOや一時ファイル・外部モジュールのTODOが検索に引っかかると、報告がノイズで埋もれてしまう懸念がある。

暫定回答:
検索から除外するのは `.git/`、`node_modules/`、`.claude/loops/receipts/` の3つとする。

理由:
レシートは監査ログであり、その本文中のTODO文言まで拾うと日々のTODO一覧がレシート由来のノイズで埋まってしまう。レシートは「読む」対象ではなく「記録専用」の場所という役割分担にも合う。`.git`と`node_modules`は対象外であることが自明。

現時点の方針:
`daily-check.md` の手順6に、上記3ディレクトリを検索除外対象として明記済み。

将来TODO:
除外対象が増えた場合、設定ファイル化を検討する（ただし`settings.json`の変更は人間のみのため、別ファイルにするか要検討）。

---

### Q4. checkpoint.json の管理方法

質問:
`daily-check.md` や `CONTRACT.md` には「`state/checkpoint.json` を更新する」とあるが、更新用のスクリプトはなく、AIがファイルを直接編集する前提になっている。今後、状態に記録するデータや構造が複雑化した場合、AIが直接編集する運用ではJSONフォーマットの破損やスキーマ違反が発生しやすくなる。現時点ではAIが直接JSONを書き換える運用で問題ないか、または読み書き・バリデーションを行うヘルパースクリプトを`scripts/`配下に用意する計画はあるか。

暫定回答:
現時点ではAIが直接JSONを書き換える運用で問題ない。バリデーション用のヘルパースクリプト／CLIツールは今は作らない。

理由:
現在の`checkpoint.json`の構造は小さく単純（`project`/`version`/`status`/`mode`/`lastRun`/`lastTask`/`currentPhase`/`notes`）。この規模でCLIツールを作るのは過剰であり、シンプルさを保つ方がPhase 1の趣旨（正確な観察と記録を優先する）に合う。`checkpoint.json`は「現在状態のメモ」、`receipts`は「監査ログ」という役割分担も、構造を複雑化させない前提を後押しする。

現時点の方針:
`checkpoint.json`のフィールド構成は現状維持。AIは更新時に既存フィールドの型（`notes`が配列であることなど）を保ったまま値のみ更新する。

将来TODO:
フィールドが増えて壊れやすくなったら、`scripts/`配下にcheckpoint読み書き用の検証スクリプトを追加することを検討する（`todo.md`に記載）。

---

### Q5. Windows環境でのスクリプト対応

質問:
`contract.local.example.md` や `dream.md` には「Windows環境では Git Bash でシェルスクリプトを実行する」旨の記述がある。今後、完全自動実行のスケジューラ等を導入するにあたり、Windows環境でも Bash（Git Bash）が確実に利用可能である前提で設計を進めてよいか。他環境での汎用性を重視する場合、PowerShell対応やPython/Node.jsでの再実装も考えられるが、方針はどうするか。

暫定回答:
Windows環境ではまず WSL2 または Git Bash でのシェルスクリプト実行を前提とする。PowerShell（`.ps1`）対応は将来TODOとする。

理由:
現状の`contract.local.example.md`/`dream.md`の記述と一致し、実績としてGit Bashで動作確認済み。今クロスプラットフォーム化に踏み出すのはPhase 1の範囲外であり、既に動いているものを変える必要がない。

現時点の方針:
`contract.local.example.md`の記載を維持しつつ、「PowerShell対応は将来TODO」であることを一文追記済み。

将来TODO:
完全自動実行のスケジューラを導入する段階で、PowerShellまたはPython/Node.jsでの再実装を検討する。

---

### Q6. pr-hunter のGitHub認証方式

質問:
`pr-hunter.md` は現在設計段階であり、GitHub CLI (`gh`) または GitHub Actions を用いてオープンPRやIssueの状況を読み取る構想になっている。認証情報はリポジトリに書かず環境変数で管理する方針だが、開発者個人の`gh`認証セッションを共有・借用するのか、このリポジトリ専用の読み取り専用PAT（Personal Access Token）を環境変数からロードするのか、どちらを推奨（予定）するか。

暫定回答:
GitHub API/CLI連携はまだ実装しない。実装する際は、開発者個人の`gh`認証セッションを共有・借用するのではなく、このリポジトリ専用の読み取り専用PAT（Personal Access Token）を`GITHUB_TOKEN`のような環境変数からロードする方式を優先候補とする。

理由:
`gh`のログインセッションを共有すると、意図せず広いスコープ（書き込み権限を含む）がAIエージェントに渡ってしまうリスクがある。専用の読み取り専用PATであればスコープを最小化できる。「GitHub API連携はまだ実装しない」「認証情報やトークンはリポジトリに保存しない」という方針にも合致する。

現時点の方針:
実装はしない。`pr-hunter.md`のTODOリストに、優先候補として上記PAT方式を追記済み（決定事項ではなく方向性のメモ）。

将来TODO:
実装時に、具体的なスコープ（例: 読み取り専用の最小権限）、トークンの保管場所（環境変数／OSのキーチェーン等）を人間が最終決定する。

---

### Q7. マルチエージェント化（Phase 1.5）の構成

質問:
`dream.md` や `todo.md` にて「Phase 1.5: マルチエージェント化の構成案を人間と詰める」というステップが示されていた。単一セッション内での役割分割（サブエージェントを動的に呼び出す）か、独立したプロセスの非同期協調（複数の独立AIプロセスがreceipts等を介して情報を受け渡す）か、どちらの形態を想定しているか。

暫定回答:
2026-07-07、人間の承認により正式採用した。名称は「Multi-Agent Review Loop」とし、単一セッション内での役割分割（A案）に近い形を採る。Claude Codeをメインエージェント（司令塔・最終判断者）とし、Codex execを「高価なセカンドオピニオン」として読み取り専用レビューに限定利用する。Codex execの利用枠(limit)に達した場合はAntigravityへ、それも使えない場合はClaude Code自身によるセルフレビューへfallbackする。外部レビュアー（Codex exec・Antigravity）の結果は最終判断ではなく、Claude Codeが必ず再確認する。

理由:
Codex execを常時起動する独立プロセス協調（B案）よりも、Claude Codeが主導権を持ち続ける設計の方が、CONTRACT.mdが定める「人間の承認が必要な操作」の一元管理と相性が良く、監査ログ（receipts）も1本の流れで残せる。また、Codex execは便利だが利用枠を早く使い切るため、常用レビュー係にはせず「重要レビュー・公開前レビュー・危険操作前レビュー」に限定し、通常時やlimit到達時はAntigravityやセルフレビューに逃がす方が持続可能。

現時点の方針:
Phase構成を「Phase 1: Report Loop → Phase 1.5: Multi-Agent Review Loop → Phase 2: Proposal Loop」と定義し、CONTRACT.md・CLAUDE.md・settings.jsonに最小限反映した（詳細は各ファイルを参照）。

将来TODO:
Codex execの具体的な呼び出し方法（CLIコマンド、権限、タイムアウト）、Antigravity fallbackの具体的な起動条件、レビュー結果をレシートにどう記録するかを人間と設計してから、`.claude/loops/tasks/`に新規タスク定義を追加する。

---

### Q8. checkpoint.json のnotesの言語

質問:
リポジトリ内の主要な説明ドキュメントやスクリプトは日本語で書かれているが、`.claude/loops/state/checkpoint.json` の `"notes"` や `"currentPhase"` などのテキスト値は英語（`"Initial goal: observe and report only."` など）で記述されていた。今後AIが checkpoint.json を更新する際、追加する notes 等のテキスト情報は日本語と英語のどちらで記述すべきか。

暫定回答:
今後、`checkpoint.json`の`notes`等のテキストは日本語で統一して記述する。

理由:
リポジトリの主要ドキュメント（README/CLAUDE.md/CONTRACT.md/dream.md等）はすべて日本語で書かれており、人間の設計者も日本語で読み書きしている。`checkpoint.json`だけ英語のままだと一貫性が失われる。

現時点の方針:
`checkpoint.json`の`notes`は日本語に変更済み（既存レシートの改変ではなく、契約上許可されている`checkpoint.json`の更新の範囲内）。

将来TODO:
特になし（方針確定。運用上不都合が出た場合のみ再検討する）。
