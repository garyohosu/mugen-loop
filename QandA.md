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
除外対象が増えた場合、設定ファイル化を検討する（`settings.json`の変更はAIが独断で行わず、人間の明示承認がある場合にAIが代行編集可能。別ファイルにするか要検討）。

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

クローズ注記(2026-07-09、Q24により確定):
Q7は「Phase 1.5の構成決定」としてクローズする。実装未着手項目（Codex呼び出し方法・日次上限・レシート機械判定形式・schema/タスク配置先・Antigravity fallback条件）はQ16〜Q18等へ分割済み。

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

---

### Q9. レビュー時に QandA.md へ追記してよい条件

質問:
CONTRACT.mdでは、通常の書き込み許可範囲を `.claude/loops/receipts/`、`.claude/loops/state/checkpoint.json`、`docs/note-draft.md` に限定している。一方で、人間から「レビューして。不明点はQandA.mdに追記して」と明示された場合、QandA.md への追記は人間の承認済み操作として扱ってよいか。今後もレビュータスクで不明点が出たときに、同様の明示指示があればQandA.mdへ追記する運用でよいか。

暫定回答:
今回の実行では、人間の明示指示があるため QandA.md への追記を許可された操作として扱う。

理由:
CONTRACT.mdの「人間の承認が必要な操作」では、通常許可範囲外への書き込みは承認が必要とされている。今回は人間が具体的に QandA.md への追記を依頼しているため、その承認が満たされていると解釈できる。ただし、恒久的な自動追記権限として一般化するにはタスク定義側の整理が必要。

現時点の方針:
レビュー中に不明点があり、かつ人間が明示的に「QandA.mdに追記」と指示した場合のみ追記する。明示指示がない場合は、最終報告またはレシートに質問として残し、QandA.mdは勝手に更新しない。

将来TODO:
レビュー系タスクを正式化する場合、QandA.mdを「質問の記録先」として許可範囲に含めるか、タスク定義に明記する。

---

### Q10. checkpoint.json の lastRun / lastTask の更新対象

質問:
`.claude/loops/state/checkpoint.json` は `lastRun` / `lastTask` を持つが、直近のレシートには `renumber-experiment-heading` のような単発作業も記録されている。checkpoint.json は daily-check などの正式タスクだけを記録するのか、それとも人間承認済みの単発作業やレビュー実行も含めて「最後にAIが動いた作業」を記録するのか。

回答(2026-07-08、人間の承認により確定):
`lastRun` / `lastTask` は「最後にAIがこのリポジトリで実行した作業」を記録する。
daily-check などの正式タスクだけでなく、review や単発の人間承認済み作業も含める。

理由:
CONTRACT.mdの完了条件では「state/checkpoint.json を更新」とあり、タスク種別をdaily-checkだけに限定していない。状態ファイルは「全AI作業の現在地」として扱う方が、監査ログ(receipts)との対応も追いやすい。

現時点の方針:
AIがこのリポジトリで実行した作業単位ごとに `lastRun` / `lastTask` を更新する。現時点では checkpoint.json のフィールド追加はしない。

将来TODO:
正式タスクだけを別管理したくなった場合は、`lastFormalTask` または `lastFormalRun` の追加を検討する。

---

### Q11. run-daily-check.sh の「変更は行っていません」表現

質問:
`scripts/run-daily-check.sh` は receipts 用ディレクトリを `mkdir -p` で作成する可能性がある一方、最後に「変更は行っていません」と表示している。この表現は「破壊的変更や既存ファイル変更はしていない」という意味で許容するか、それとも監査ログとして誤解を避けるために「既存ファイルの変更は行っていません」などへ修正すべきか。

回答(2026-07-08、人間の承認により確定):
表示文言を最小修正する。最終行を「破壊的操作・既存ファイル変更は行っていません」に変更した(実装内容は変更なし)。

理由:
スクリプトのコメントには「唯一の書き込みは receipts 用ディレクトリの作成」と明記されているため、実装自体は危険ではない。ただし、実行結果の文言だけを見るとディレクトリ作成の可能性と矛盾し、監査ログの正確性を重視する本プロジェクトでは小さな混乱源になり得る。

現時点の方針:
修正済み。`scripts/run-daily-check.sh` の表示文言のみを変更し、処理は一切変えていない。

将来TODO:
特になし(対応完了)。

---

### Q12. docs/loop-status.md の位置づけとCLAUDE.mdの書き込み許可範囲

質問:
`scripts/generate-loop-status.py` は `docs/loop-status.md` を毎回上書き生成する。CLAUDE.mdの「変更してよい範囲」は現在 `receipts/`、`checkpoint.json`、`docs/note-draft.md` を明記しており、`docs/loop-status.md` は含まれていない(今回は人間の明示指示による例外として作成した)。今後この機能を正式なタスク(loop-status-report)として繰り返し使う場合、CLAUDE.mdの許可範囲に `docs/loop-status.md` を追加すべきか。またこのファイルはgitで毎回コミットする実体として管理するのか、それとも生成のたびに内容が変わるスナップショットとして`.gitignore`対象にするのか。

回答(2026-07-08、人間の承認により確定):
`docs/loop-status.md` は正式なレポート出力先として扱う。git管理対象とし、`loop-status-report`タスクに限り更新してよい。ただしそれ以外の任意ファイルへの書き込みは許可しない。

理由:
状態レポートはCONTRACT.mdの目的(判断材料の整理と監査ログの記録)に沿う正式な成果物であり、毎回人間が明示指示する例外運用よりも、タスクを許可範囲として明文化する方が運用がぶれない。自動push・merge・PR作成・既存レシート改変の禁止は維持したまま、書き込み先を`docs/loop-status.md`一箇所に限定することで安全性を保つ。

現時点の方針:
CLAUDE.md「変更してよい範囲」とCONTRACT.md「許可する作業」に、`loop-status-report`タスク実行時に限り`docs/loop-status.md`を生成・更新してよい旨を追記した。`docs/loop-status.md`は`.gitignore`に加えず、通常どおりgit管理する。

将来TODO:
更新頻度が高くなりすぎた場合(毎回差分だけのコミットが積み重なる等)は、git管理から外すか、コミット対象を人間判断にすることを検討する。

---

## 2026-07-09 レビュー追記（未回答）

以下はリポジトリ全体レビューで新たに見つけた不明点・不整合である。
回答・暫定方針の確定は人間が行う。分類は `要判断` / `即修正候補` / `保留`。重大度は `高` / `中` / `低`。

---

### Q13. CONTRACT.md「人間の承認が必要な操作」と loop-status.md 許可範囲の不整合

質問:
Q12で `docs/loop-status.md` は `loop-status-report` タスク実行時に限り正式な書き込み先と確定し、CONTRACT.md「許可する作業」と CLAUDE.md「変更してよい範囲」には反映済みである。
一方、CONTRACT.md「人間の承認が必要な操作」は今も次の文言のままである。

- `receipts/ と state/ と docs/note-draft.md 以外へのファイル書き込み`

ここに `docs/loop-status.md`（タスク限定）が含まれていないため、許可する作業と承認が必要な操作が矛盾している。
「許可する作業」を正として承認リストを同期修正してよいか。修正する場合、`CONTRACT.md` の編集は人間の明示承認がある場合にAIが代行編集してよいか。

重大度: 中  
分類: 即修正候補（文言同期）／要判断（誰が直すか）

回答(2026-07-09、人間の承認により確定):
「許可する作業」を正として、「人間の承認が必要な操作」側の文言を同期修正する。
`docs/loop-status.md` は `loop-status-report` タスク実行時に限り承認不要の書き込み先として扱う。

理由:
Q12で既に`docs/loop-status.md`は正式なレポート出力先として確定しており、運用実績もある。承認リスト側の文言が古いまま残っているのは表記漏れであり、運用を制限し直す理由がない。

現時点の方針:
CONTRACT.mdの「人間の承認が必要な操作」の文言修正は、AIが独断で行うのではなく、人間の明示承認を根拠にAIが代行編集する。

将来TODO:
特になし(2026-07-09、人間の明示承認によりAIがCONTRACT.md/CLAUDE.mdへ実際に反映済み。詳細は同日付のレシートを参照)。

---

### Q14. dream.md の書き込み許可

質問:
プロジェクトの `CLAUDE.md`「変更してよい範囲」には `dream.md` が含まれていない。
一方、ユーザー共通指示では作業完了時に必ず `dream.md` へ追記することになっており、実運用でも毎セッション更新されている。
`dream.md` を恒久的な許可範囲に含めるか、共通指示とプロジェクト契約のどちらを優先するか、方針を決めたい。

重大度: 中  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
`dream.md` は、作業完了時の振り返り・改善点の記録先として、恒久的な許可範囲に含める。
ただし、許可するのは「追記」を基本とする。既存内容の削除、大幅な書き換え、過去記録の改変は行わない。誤記修正など軽微な修正が必要な場合も、人間の明示指示がある場合に限定する。

理由:
ユーザー共通指示では作業完了時に `dream.md` へ振り返りを記録する運用になっており、実運用でも既に更新されている。一方で、プロジェクト側の `CLAUDE.md` に許可範囲として明記されていないため、共通指示とプロジェクト契約の間に不整合がある。
実運用を正とし、`dream.md` を正式な記録先として明文化する方が安全である。許可範囲を曖昧なままにすると、AIが毎回「書いてよいのか」を判断する必要があり、監査ログ運用として不安定になる。

現時点の方針:
`dream.md` は作業完了時の振り返り追記先として許可する。
AIは `dream.md` に追記してよいが、既存内容の削除・大幅編集・過去記録の改変は行わない。

将来TODO:
特になし(2026-07-09、人間の明示承認によりAIが`CLAUDE.md`と`CONTRACT.md`の許可範囲に`dream.md`を「作業完了時の振り返り追記に限り可」として実際に追記済み)。

---

### Q15. メインエージェントの定義（Claude Code 固定か、作業主導エージェントか）

質問:
CONTRACT.md / CLAUDE.md / settings.json は「Claude Code がメインエージェント・最終判断者」と明記している。
実際には Grok など別CLIからも同じリポジトリで見回り・レビュー・記録が行われることがある。
この場合:

1. Claude Code 以外はメインになれず、Codex結果の再確認や最終報告も Claude Code 専用とするか
2. 「その作業セッションを主導するエージェント」を一時的なメインとみなし、ツール名は問わないか
3. settings.json の `mainAgent` を人間が都度切り替える運用にするか

Phase 1.5 の監査（誰が最終判断したか）に直結するため、方針を決めたい。

重大度: 高  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
Claude Code固定とする。Claude Code以外は「メインエージェント」になれない。
Codex結果の再確認・最終報告はClaude Code専用のまま維持する。

理由:
CONTRACT.md/CLAUDE.md/settings.jsonが既に「Claude Codeがメインエージェント・最終判断者」と明記しており、外部レビュアーの結果を必ずClaude Codeが再確認する設計と一致する。ツールを問わず「主導したセッション」をメインとみなす運用は、監査ログ上の最終判断者が揺れ、Phase 1.5の目的（一元管理）に反する。

現時点の方針:
Claude Code以外のCLI（Grok等）がこのリポジトリで作業した場合、その作業は「メインエージェントによる正式実行」としては扱わない。checkpoint.json/receiptsへの記録が必要な場合も、最終判断・報告はClaude Codeが行う前提を維持する。

将来TODO:
Claude Code以外のCLIが実際にどう関与しているか（読み取りのみか、書き込みも行うか）を人間に確認し、必要ならCONTRACT.mdに明記する。

---

### Q16. Codex 実行ゲート: `codexExec.enabled` と `RUN_CODEX=1` の関係

質問:
設計書（`docs/superpowers/specs/2026-07-09-codex-exec-review-design.md`）は `RUN_CODEX=1` の明示を必須としている。
settings.json では `codexExec.enabled: false` かつ `requiresExplicitRunFlag: true` である。
実装時のゲートは次のどれを正とするか。

1. `enabled=true` かつ `RUN_CODEX=1` の両方が必要（二重ロック）
2. `RUN_CODEX=1` だけで足り、`enabled` は将来用の予約フラグ
3. `enabled=true` だけで足り、`RUN_CODEX` は人間向けの運用メモ

現状 `enabled=false` のまま設計承認後の実装に入ると、起動条件の解釈が割れる。

重大度: 中  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
1(二重ロック)を正とする。`enabled=true` かつ `RUN_CODEX=1` の両方が揃って初めて実行可能とする。

理由:
Codex execは費用が発生する外部呼び出しであり、安全側に倒すべき。`enabled`は設定ファイル側の恒久的な許可、`RUN_CODEX`は実行時の明示的な人間意思表示という役割分担にすれば、片方の設定ミスだけでは誤発火しない。

現時点の方針:
実装時、Codex呼び出しの起動条件チェックは「`settings.json`の`codexExec.enabled === true`」と「環境変数`RUN_CODEX === "1"`」の両方をANDで確認する。どちらか一方でも欠ければ実行せず、セルフレビューにfallbackする。

将来TODO:
実装（CLI呼び出し部分）でこのゲート条件をコードコメント等に明記する。

---

### Q17. Codex 日次上限の「1日」境界とレシート上の機械判定形式

質問:
設計書は `maxRunsPerDay=1` とし、当日実行済み判定にレシート内の `codexRunStarted: true` と実行日を使うとしている。
次が未定義のままである。

1. 日付境界は `Asia/Tokyo` か UTC か（`schedule.yml` は Asia/Tokyo）
2. 判定対象は `.claude/loops/receipts/YYYY-MM-DD/` のディレクトリ名か、レシート本文の時刻か
3. `codexRunStarted: true` を必須キーとして `write-receipt.sh` テンプレートや専用レシート形式にどう埋め込むか（現状テンプレートに当該フィールドはない）
4. 起動成功後にレシート作成前で失敗した場合、上限消費の記録をどこに残すか

重大度: 中  
分類: 要判断

回答(2026-07-09、人間の承認により一部確定):
1について、日付境界は `Asia/Tokyo` を正とする（`schedule.yml`と統一）。

理由:
このリポジトリの人間の運用時間・既存の`schedule.yml`はAsia/Tokyo前提であり、統一しないと「今日もう実行済みか」の判定がAIと人間でずれる。

追加回答(2026-07-09、人間の承認により確定):
2〜4について、以下の方針とする。

2. 判定対象は `.claude/loops/receipts/YYYY-MM-DD/` のディレクトリ名を主とし、レシート本文の機械判定キーを補助として使う。日付はすべて Asia/Tokyo の日付とする。

3. Codexを実行したレシートには、機械判定用のキーを必ず記録する。最低限、次の項目を本文の先頭付近に記載する。

```yaml
codexRunStarted: true
codexRunDateJST: YYYY-MM-DD
codexRunMode: review
codexRunResult: completed
```

`codexRunMode` は `review` / `adversarial-review` / `rescue` など、実行内容に応じて記録する。
`codexRunResult` は `started` / `completed` / `failed` / `cancelled` / `skipped` のように、後から機械的に判定しやすい値にする。

4. Codexの起動成功後にレシート作成前で失敗する問題を避けるため、Codexを呼び出す前に、まず「開始レシート」を作成する。つまり、二重ロックと日次上限チェックを通過した時点で、`codexRunStarted: true` を含むレシートを先に残す。その後にCodexを実行し、完了後に同じレシートへ結果を追記する。

理由(2〜4):
Codexは費用・利用枠を消費する外部呼び出しであるため、「実行したのに記録が残らない」状態を避ける必要がある。先に開始レシートを作れば、途中でCodexが失敗しても「その日の実行枠を使った」ことが残る。

現時点の方針:
日次上限判定は `Asia/Tokyo` の日付で行う（1で確定）。
判定は、Asia/Tokyoの日付ディレクトリと `codexRunStarted: true` を組み合わせて行う（2で確定）。
Codexを実行する場合は、実行前に開始レシートを作成する（4で確定）。`codexRunStarted: true` があるレシートは、成功・失敗にかかわらず、その日のCodex実行回数としてカウントする。

将来TODO:
`write-receipt.sh` とは別に、Codex実行用のレシートテンプレート、または `scripts/write-codex-receipt.sh` のような専用ヘルパーを追加するか検討する。

---

### Q18. Codex レビュー用 JSON Schema とタスク定義の配置先

質問:
設計書の実装単位には JSON Schema とタスク定義が含まれるが、リポジトリ内の正式パスが決まっていない。
例として次のどちら（または別案）にするか。

- Schema: `.claude/loops/schemas/codex-review-output.json` など
- タスク: `.claude/loops/tasks/codex-review.md`（code/document を1タスクにまとめるか、分割するか）
- 設計書置き場: 今回の `docs/superpowers/specs/` を今後も公式の設計書ディレクトリとするか

「superpowers」というディレクトリ名の意味と、今後も使う前提かも確認したい。

重大度: 低  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
Schemaは `.claude/loops/schemas/codex-review-output.schema.json` に置く。
タスク定義は `.claude/loops/tasks/codex-review.md` に置く。`code` / `document` / `adversarial` を最初から複数タスクへ細かく分けず、まずは1タスクにまとめる。必要に応じて後から `codex-adversarial-review.md` や `codex-document-review.md` へ分割する。
設計書置き場は当面 `docs/superpowers/specs/` を継続使用する。ただしこのディレクトリは「正式契約」ではなく「拡張機能・実験機能の設計書置き場」と位置づける。最終的な運用ルールはCONTRACT.md/CLAUDE.md/`.claude/loops/tasks/`を正とする。

理由:
`.claude/loops/` 配下に schema と task を置くことで、ループ実行に必要な定義が一箇所に集まる。`docs/superpowers/specs/` は設計検討の履歴として有用だが、実行時にAIが参照すべき正式タスク定義とは分けた方が安全である。

現時点の方針:
Schemaは `.claude/loops/schemas/codex-review-output.schema.json`。
タスク定義は `.claude/loops/tasks/codex-review.md`。
設計書は引き続き `docs/superpowers/specs/` に置くが、実行ルールとしてはtask/schema側を優先する。
※本回答はパスの決定のみであり、Codex実装(実際のschema/タスクファイル作成)はQ7クローズ方針により別途着手する。

将来TODO:
将来的に名称が分かりにくくなった場合は `docs/specs/` への移動を検討する。
（2026-07-09、人間の明示承認によりAIが`README.md`の「各ファイルの役割」に`docs/superpowers/specs/`の位置づけを実際に追記済み）

---

### Q19. `maxChangedFiles: 0` の解釈

質問:
`settings.json` の `maxChangedFiles` は `0` である。
Phase 1 では毎回、許可範囲内でも `receipts/` 新規作成と `checkpoint.json` 更新が発生する。
`maxChangedFiles` は次のどれを意味するか。

1. 許可範囲外の変更ファイル数の上限（許可内はカウントしない）
2. リポジトリ全体の変更数上限（この場合、現状の運用と矛盾する）
3. まだ未使用の予約フィールドで、現時点では参照しなくてよい

AIが停止条件や自己点検でこの値を参照すべきかも決まっていない。

重大度: 中  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
1を採用する。`maxChangedFiles: 0` は「許可範囲外の変更ファイル数の上限が0」という意味とする。
許可範囲内の変更(`receipts/`の新規作成、`checkpoint.json`の更新、`docs/loop-status.md`の生成、`dream.md`の追記など)は、このカウントには含めない。

理由:
リポジトリ全体の変更数上限を0と解釈すると、Phase 1の通常運用で必ず発生するレシート作成やcheckpoint更新と矛盾する。一方、「許可範囲外の変更を0にする」と解釈すれば、CONTRACT.mdの安全思想と一致する。

現時点の方針:
AIが自己点検で `maxChangedFiles` を参照する場合は、許可範囲外の変更が0件であることを確認するために使う。
許可範囲内の変更は、件数ではなく内容と必要性を確認する。

将来TODO:
特になし(2026-07-09、人間の明示承認によりAIが`settings.json`に`maxChangedFiles`は「許可範囲外の変更数」の上限である旨を`_maxChangedFilesNote`として実際に追記済み)。

---

### Q20. note-experiment における `docs/note-draft.md` の「反映」タイミング

質問:
CONTRACT.md は `docs/note-draft.md` への「追記案の作成と反映（人間がレビューする前提）」を許可している。
`note-experiment.md` も「反映してよいのは docs/note-draft.md のみ」と書く一方、「大きな構成変更は提案にとどめ、人間の判断を待つ」とも書く。
運用上の境界を次のように切り分けたい。

1. 小さな追記はタスク実行中にAIが `docs/note-draft.md` へ直接反映してよい
2. 常に追記案をレシート（または報告）にだけ残し、反映は人間承認後
3. 1と2の中間（追記は可、削除・大幅な構成変更は不可 など）

「人間がレビューする前提」が事前レビューか事後レビューかも明確にしたい。

重大度: 中  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
3(中間案)を採用する。
小さな追記・表現調整・明らかな補足は、AIが `docs/note-draft.md` に直接反映してよい。ただし、削除、大幅な構成変更、主張の変更、タイトル変更、結論の変更は、直接反映せず、提案にとどめて人間の判断を待つ。
「人間がレビューする前提」は、小さな追記については事後レビュー、大きな変更については事前レビューと解釈する。

理由:
`docs/note-draft.md` は人間がレビューする前提の下書きであり、小さな追記まで毎回承認待ちにすると運用が重くなる。一方で、記事の構成や主張をAIが勝手に変えると、人間の意図から外れる危険がある。

現時点の方針:
AIが直接反映してよいもの: 誤字脱字修正、1〜数文程度の補足、既存方針に沿った説明の追加、参考情報の短い追記、表現の軽微な整理。
AIが提案にとどめるもの: 見出し構成の大幅変更、段落の大規模移動、既存記述の削除、結論や主張の変更、記事タイトルの変更、外部公開に影響する断定表現の追加。

将来TODO:
`note-experiment.md` に「小さな追記は直接反映可、削除・大幅変更は提案のみ」と明記する。

---

### Q21. mugen-loop-viewer と本リポジトリの公式関係

質問:
公開viewer（https://mugen-loop-viewer.lolipop-now.app/）は README からリンクされ、レシート上は `C:\PROJECT\mugen-loop-viewer` の別ディレクトリで scaffold / デプロイされたと記録されている。
本リポジトリ内には viewer のソースがなく、別ディレクトリは当初 git 管理外だった。
次を決めたい。

1. viewer を本リポジトリの monorepo 配下に取り込むか、別リポジトリとして公式管理するか
2. 表示データは静的サンプルのままでよいか、いつ `docs/loop-status.md` や receipts と同期するか
3. 再デプロイや文言更新の責任範囲（mugen-loop タスクに含めるか、人間の手動運用か）

重大度: 中  
分類: 要判断／保留（実装は急がない）

回答(2026-07-09、人間の承認により確定):
`mugen-loop-viewer` は、本リポジトリの補助的な公開ビューアとして扱う。ただし、現時点では本リポジトリに取り込まず、別ディレクトリ／別リポジトリ候補として管理する。
本リポジトリの正式な状態情報のソースは、引き続き `docs/loop-status.md`、`.claude/loops/receipts/`、`.claude/loops/state/checkpoint.json` とする。viewerはそれらを見やすく表示するための補助UIであり、契約上の正本ではない。
表示データは当面、静的サンプルのままでよい。`docs/loop-status.md` や receipts と自動同期する機能は、まだ実装しない。
再デプロイや文言更新は、当面は人間の手動運用とする。mugen-loopの正式タスクにはまだ含めない。

理由:
viewerは有用だが、本リポジトリ内にソースがなく、当初は別ディレクトリでscaffoldされたもの。急いでmonorepo化すると、mugen-loop本体の契約・監査ログ・公開UIの責任範囲が混ざる。まずは「補助ビューア」として位置づけ、正式な同期仕様が固まってから取り込み方を決める方が安全である。

現時点の方針:
viewerは公式補助UIだが、正本ではない。本リポジトリにはまだ取り込まない。表示データは静的サンプルのまま維持する。再デプロイは人間の手動運用とする。

将来TODO:
viewerを別リポジトリとして正式管理するか、本リポジトリの `viewer/` 配下に取り込むかを検討する。同期する場合は、`docs/loop-status.md` から静的JSONを生成する方式を優先候補とする。

---

### Q22. schedule.yml への `loop-status-report` 登録有無

質問:
`loop-status-report` は正式タスクとして存在し、実用機能として使われているが、`schedule.yml` には未登録である。
定期実行の設計メモに載せるか（例: 週1、または daily-check の後）、必要時のみ手動起動のままにするか。
なお Q1 により、schedule 自体の自動起動はまだ行わない前提は維持してよい。

重大度: 低  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
`loop-status-report` は `schedule.yml` に登録する。ただし、自動実行ではなく、定期実行候補の設計メモとして登録する。
頻度は「週1回」を候補とし、必要に応じて人間が手動で実行する。daily-checkのたびに毎回実行する必須タスクにはしない。

理由:
`loop-status-report` は正式タスクとして存在し、実用機能として使われているため、scheduleの設計メモに載せておく方が全体像を把握しやすい。一方で、毎日実行すると `docs/loop-status.md` の差分が増えすぎる可能性があるため、daily-check後の常時実行にはしない。

現時点の方針:
`schedule.yml` には、週1回または手動実行候補として `loop-status-report` を追記する。実際の自動起動は行わない。Q1の方針どおり、トリガーは人間の手動指示のみとする。

将来TODO:
Phase 1の運用実績を見て、週1回で十分か、daily-check後に必要時だけ実行するかを再評価する。

---

### Q23. `multiAgent: true` の意味（能力フラグか、実行中モードか）

質問:
settings.json は `multiAgent: true` だが `codexExec.enabled: false` である。
`multiAgent` は次のどれか。

1. Phase 1.5 を採用済みという能力・方針フラグ（Codex無効でも true でよい）
2. 今この実行で複数エージェントを使うモード（常用時は false に戻す）
3. Codex / Antigravity が実際に使える状態になったら true にする準備フラグ

loop-status の Safety Status にも出るため、人間が見たときの意味を揃えたい。

重大度: 低  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
`multiAgent: true` は、Phase 1.5 Multi-Agent Review Loop を採用済みであることを示す「能力・方針フラグ」とする(1)。
これは「現在の実行で必ず複数エージェントを使っている」という意味ではない。CodexやAntigravityが実際に呼ばれるかどうかは、`codexExec.enabled`、`RUN_CODEX=1`、日次上限、fallback条件などで別途判定する。

理由:
Phase 1.5の設計方針は採用済みだが、Codex execは常時有効ではなく、`codexExec.enabled: false` のように個別ゲートで制御される。`multiAgent` を実行中モードとして扱うと、実際にはCodexを使っていないのに「使っている」と誤解される。

現時点の方針:
`multiAgent: true` は「マルチエージェント構成を採用済み」という意味。実際に外部レビュアーを使ったかどうかは、レシートの `codexRunStarted` やreview記録で判断する。

将来TODO:
loop-status の Safety Status では、`multiAgent: true` を「Phase 1.5採用済み」と表示し、Codex実行可否は `codexExec.enabled` や `RUN_CODEX` と分けて表示する(scripts/generate-loop-status.pyの改修が必要、実装は別途)。

---

### Q24. Q7 将来TODOと Codex 設計書の関係（クローズ方針）

質問:
Q7 の将来TODOには「Codex呼び出し方法・権限・タイムアウト、レシート記録、タスク定義追加」が残っている。
2026-07-09 の設計書で呼び出し方法・権限・タイムアウト・レシート項目・実装単位は文書化されたが、CLI実装・タスク追加・Antigravity条件は未着手である。
Q7 を次のどう扱うか。

1. 「設計完了・実装未着手」と更新して部分クローズする
2. 実装完了まで Q7 をオープンのまま残す
3. 実装・fallback・タスク定義を別Q（本レビューの Q16〜Q18 など）へ分割し、Q7 は構成決定のみクローズする

重大度: 低  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
3を採用する。Q7は「Phase 1.5の構成決定」としてクローズする。
残っている実装詳細、fallback条件、タスク定義、レシート形式、日次上限などは、Q16〜Q18および関連TODOへ分割して管理する。

理由:
Q7の本質は「マルチエージェント化の構成をどうするか」であり、Claude Codeをメイン、Codexを読み取り専用のセカンドオピニオンとして使う方針は既に確定している。実装詳細までQ7に抱え続けると、質問の範囲が広がりすぎて進捗管理しづらくなる。

現時点の方針:
Q7は「構成決定済み」としてクローズ。実装未着手項目は、Q16〜Q18およびTODOに引き継ぐ(Q7本文にも追記済み)。

将来TODO:
特になし(クローズ)。

---

### Q25. 未コミット成果物の扱い（receipts / checkpoint / loop-status / dream）

質問:
運用上、レシートや checkpoint、`docs/loop-status.md`、`dream.md` が未コミットのまま溜まることがある（2026-07-09 時点でも同様の状態を確認）。
CONTRACT は commit を人間承認必須としている。次の運用を決めたい。

1. daily-check の提案項目として「未コミットの記録ファイル一覧とコミット推奨」を必須にするか
2. 記録系ファイルは人間がまとめてコミットする前提で、AIは毎回触らない報告にとどめるか
3. 記録系だけをまとめるコミット文面のテンプレを用意するか

監査ログが git に載らない期間が長いと、viewer や status と履歴の対応が取りにくくなる。

重大度: 中  
分類: 要判断

回答(2026-07-09、人間の承認により確定):
1と3を採用する。
daily-check または loop-status-report の報告項目として、「未コミットの記録系ファイル一覧」と「コミット推奨」を含める。ただし、AIは自動で commit しない。commit は引き続き人間の承認必須操作とする。
あわせて、記録系ファイルをまとめてコミットするためのコミット文面テンプレートを用意する。

理由:
receipts、checkpoint、loop-status、dream は監査ログや状態把握に関わる重要な成果物であり、未コミットのまま長く残ると、viewerや履歴との対応が取りにくくなる。一方で、CONTRACT.mdはcommitを人間承認必須としているため、AIが自動commitするのは避けるべきである。

現時点の方針:
AIは、作業完了報告またはdaily-check内で、未コミットの記録系ファイルを一覧化し、人間にcommitを推奨する。AIはcommitしない。必要に応じて、コミット候補コマンドを提示する。

コミット文面テンプレート:

```text
chore(loop): record loop outputs for YYYY-MM-DD
```

コミット対象候補:

```text
.claude/loops/receipts/
.claude/loops/state/checkpoint.json
docs/loop-status.md
dream.md
QandA.md
```

ただし、実際にどのファイルを含めるかは人間が `git status` を確認して判断する。

将来TODO:
`daily-check.md` または `loop-status-report.md` に、「未コミットの記録系ファイル一覧とコミット推奨」を報告項目として追加する。
