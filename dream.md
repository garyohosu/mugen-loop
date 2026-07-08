# dream.md

## 2026-07-07 17:00 Dreamingタイム

### 今回やったこと
- 指示内容を firststep.md として保存
- mugen-loop テンプレート一式を新規作成(README / CLAUDE.md / CONTRACT.md / contract.local.example.md / .gitignore / .claude/loops/ 配下の settings・schedule・rubrics×3・tasks×3・state・receipts / scripts×2)
- run-daily-check.sh と write-receipt.sh を実行して動作確認
- 初回レシートを receipts/2026-07-07/ に記録し、checkpoint.json を更新

### 気づいたこと
- 「AIに枠を与える」設計は、契約(CONTRACT)・設定(settings.json)・記録(receipts)の3点が揃うと初めて機能する
- Windows環境でもGit Bash経由でシェルスクリプトが問題なく動いた

### 改善点
- pr-hunter はまだ設計メモ段階。GitHub接続の認証方針(読み取り専用トークン)を先に決める必要がある
- write-receipt.sh のテンプレートに rubrics の判定結果欄を足すと運用しやすそう

### 次に試すとよさそうなこと
- 初回コミット(人間の承認後)
- Claude Codeに「daily-checkタスクを実行して」と頼み、報告→レシートの一連の流れを試す
- receipts が数日たまったら、報告の精度を振り返って第2段階(提案)へ進むか判断する

## 2026-07-07 17:06 Dreamingタイム

### 今回やったこと
- テーマ「私は何もしない。ループが働く。」でmugen-loopを再構築
- CONTRACT.md冒頭に宣言文を追加、settings.json/checkpoint.jsonを新仕様に更新
- docs/note-draft.md(note記事下書き)とtasks/note-experiment.mdを新規作成
- rubrics 3種を新観点(実験の正直さ、既存設計との整合など)で更新
- レシートを残し、スクリプト動作を再確認

### 気づいたこと
- 「何をしなかったか」をレシートに残す設計は、承認待ちの状態を可視化するのに効く
- 旧構成のblog-review.mdは「承認なし削除禁止」ルールにより自分では消せない。ルールが自分自身にも作用した好例

### 改善点
- write-receipt.shのテンプレート見出しを「何をしたか/なぜしたか/何をしなかったか」に合わせると記入が楽になる

### 次に試すとよさそうなこと
- blog-review.mdの扱い(削除 or 併存)を人間が決める
- 初回コミット(承認後)とGitHub公開、note記事のURL差し込み
- daily-check→note-experimentを1日通しで回し、レシートから記事に追記する流れを検証する

## 2026-07-07 17:10 Dreamingタイム

### 今回やったこと
- 追加修正の依頼を受け、docs/note-draft.md と tasks/note-experiment.md の存在を確認(両方とも前回作成済みだった)
- blog-review.md(既存記事の校正用)と note-experiment.md(mugen-loop実験の記事化用)の役割分担を両ファイルに明記
- note-experiment.md の読み込み素材に dream.md / firststep.md / README.md を追加
- CLAUDE.md に「note記事化の素材として receipts / dream.md / docs/note-draft.md を意識する」を追記
- README.md のタスク一覧に blog-review を追加

### 気づいたこと
- 「作成一覧に見当たらない」という指摘は、報告の書き方の問題だった。ファイルは存在していたが、報告で新規2件が目立たなかった可能性がある。レシートに存在確認の結果を明記する習慣が大事
- 似たタスクが2つあるときは、削除ではなく役割の線引きで解決できる

### 改善点
- 実装報告では「新規/更新/据え置き」を最初に分けて見せると、こうした行き違いを減らせる

### 次に試すとよさそうなこと
- 初回コミット(人間の承認後)
- note-experimentタスクを実際に1回回して、dream.mdとreceiptsからnote-draft.mdへの追記案を作る流れを検証する

## 2026-07-07 17:15 Dreamingタイム

### 今回やったこと
- 人間側の次アクションを todo.md に整理(すぐやる/近いうち/pr-hunter接続前/note公開前/いつか、の5段階)
- 人間の明示的な承認を得て、初回コミットとGitHub(garyohosu/mugen-loop)へのプッシュを実行

### 気づいたこと
- 「承認があったときだけpush」という契約の初回実運用になった。承認→実行→レシートの流れが一周した
- todo.md は人間用だが、AIが読めば「今どのフェーズか」の判断材料にもなる

### 改善点
- todo.md の完了チェックを daily-check の確認項目に含めると、見回りの価値が上がりそう

### 次に試すとよさそうなこと
- GitHubで公開されたリポジトリを note-draft.md に貼る
- 明日の朝、daily-check を一度回してレシートの精度を見る

## 2026-07-07 17:20 Dreamingタイム

### 今回やったこと
- 人間の判断「blog-review.md は削除せず併存」を受けて役割を確定
  - blog-review = 記事を読む係(文章そのもの: 下書き・README・note-draft.md)
  - note-experiment = 実験を記事に育てる係(実験ログ: receipts・dream.md・firststep.md・checkpoint.json)
- 両タスク・README・CLAUDE.md・schedule.yml に役割分担を反映(blog-reviewは定期実行なし、必要時起動)

### 気づいたこと
- 「入力が違えば別タスク」という切り方は分かりやすい。文章を入力にするか、ログを入力にするか
- 判断待ちにしていた項目が人間の一言で解決した。承認待ちで止まる設計が機能している

### 改善点
- note-experiment の素材リストからREADME.mdを外しchekpoint.jsonに揃えた。素材の定義は1箇所(タスク定義)に集約されているのが良い状態

### 次に試すとよさそうなこと
- Phase 1.5 としてマルチエージェント化の設計を検討する(人間からの次の指示待ち)
- 変更分のコミット(承認後)

## 2026-07-07 17:16 Dreamingタイム

### 今回やったこと
- 役割分担整理(blog-review併存)の変更一式を、承認を得てコミット・プッシュ

### 気づいたこと
- 「承認→実行→レシート」のサイクルが2周目。定型化してきた

### 改善点
- push系レシートは定型なので、write-receipt.shにpush用テンプレートを足してもよい

### 次に試すとよさそうなこと
- Phase 1.5(マルチエージェント化)の構成案を人間と詰める

## 2026-07-07 18:49 Dreamingタイム

### 今回やったこと
- QandA.md の未回答8項目すべてに「質問/暫定回答/理由/現時点で採用する方針/将来のTODO」の形式で回答を追記
- 反映が必要な項目を、tasks/daily-check.md・tasks/pr-hunter.md・contract.local.example.md・todo.md・checkpoint.json に破壊的変更なしで最小限反映
- CONTRACT.md/CLAUDE.md自体への反映は「変更は人間のみ」という契約上の理由で見送り、todo.mdへの記録にとどめた

### 気づいたこと
- 「不明点があれば止まる」契約は、疑問を放置してよい理由にはならない。安全に決められる範囲は暫定方針として言語化し、決められない部分だけを人間待ちとして残す方が、次に読む人(未来の自分や人間)にとって親切
- 自分自身が変更してはいけないファイル(CONTRACT.md/CLAUDE.md)に対して「ここを変えたい」という結論が出たとき、変更を諦めるのではなく、変更できる場所(todo.md)に方針を書き残すことで、承認待ちの意思決定を可視化できた

### 改善点
- QandA.mdのような「暫定回答つきの疑問リスト」は、今後も定期的に見直して「将来のTODO」を`todo.md`に集約する運用がよさそう

### 次に試すとよさそうなこと
- 今回の変更一式を人間が確認し、コミットするか判断する
- Phase 1.5(マルチエージェント化)の暫定方針をもとに、Codex exec呼び出しの具体設計を人間と詰める

## 2026-07-07 19:22 Dreamingタイム(修復・Phase 1.5正式反映)

### 今回やったこと
- リポジトリ内を文字欠け・ログ混入(「Allowed by auto mode classifier」「ITHUB_TOKEN」等の断片)がないか検索したが、実際のファイルには見つからなかった。前回の崩れはチャット表示上のものだったと判断
- QandA.mdを、太字ラベル付きの箇条書きから、質問/暫定回答/理由/現時点の方針/将来TODOのプレーンな見出し形式に統一しなおした(表は使っていない)
- Phase 1.5「Multi-Agent Review Loop」を人間の承認により正式採用し、CONTRACT.md・CLAUDE.md・settings.jsonに最小限反映(Claude Codeがメイン、Codex execはread-onlyでlimit運用、Antigravityがfallback、Claude Code self-reviewが最終fallback)
- docs/note-draft.mdに「実験4: Codexのリミットは思ったより早く来る」を追加
- todo.mdのPhase 1.5項目を、正式採用済みの決定事項と未完了TODOに分けて整理し直した

### 気づいたこと
- 「崩れている」という指摘を受けたとき、まず実物のファイルを検索して確認するステップを踏むと、チャット表示上のノイズと実データの破損を区別できる。慌てて直しにいかないことが大事
- 自分が変更できないファイル(CONTRACT.md/CLAUDE.md)への反映は、人間の明示的な許可を得てから初めて実行するという手順が、今回はっきり機能した

### 改善点
- 今後も「崩れ」の指摘が来たら、まず検索で実在を確認する、を先頭の手順として明文化してもよさそう

### 次に試すとよさそうなこと
- 今回の修復・Phase 1.5反映一式を人間が確認し、コミットするか判断する
- Codex exec呼び出しの具体設計、Antigravity fallbackの起動条件を人間と詰める

## 2026-07-07 19:35 Dreamingタイム(既存プロジェクトとの関係整理)

### 今回やったこと
- 既存のバーチャルカンパニー運用（AIブログ、翻訳、取引、監視など）とmugen-loopの関係性を明文化
- `docs/note-draft.md` に「すでに私はバーチャルカンパニーを動かしている」「mugen-loop はバーチャルカンパニーのOSになるかもしれない」の2つの章を追記
- `README.md` に、既存のバーチャルカンパニー群を安全に運用するための共通テンプレートとしての位置づけと、監視プロジェクト `CompanyGuardian` との将来的な連携の展望を追記
- 新しいレシート（193200-virtual-company-context.md）を作成

### 気づいたこと
- mugen-loop は「ゼロから自動化を夢想する」のではなく「既存の無人運用（個別最適化されカオス化しつつある複数プロジェクト）をいかに安全・説明可能・再現可能にするか」という切実な課題に対する解である。この文脈が加わったことで、プロジェクトの意義がより強固になった
- 個別のプロジェクトに CONTRACT / schedule / rubrics / state / receipts を持たせることで、個々の自律性を保ちつつ監査可能な「運用OS」として束ねるという構造は、マルチエージェントシステムの管理パターンとして汎用性が高い

### 改善点
- 今回は既存リポジトリへの文脈追加（ドキュメントのみ）に留めたが、実際に他プロジェクトにこの構造を移植する際、どのようなコード上のフックやライブラリが必要になるかの設計がまだ不足している

### 次に試すとよさそうなこと
- 今回の追記内容の確認とコミット可否の判断
- 他のバーチャルカンパニーへのmugen-loop構造の適用方法（ポータブルなテンプレート化）の検討

## 2026-07-08 Dreamingタイム

### 今回やったこと
- pull で入ってきた別セッションの成果(Phase 1.5正式採用、QandA.md、note-draft拡充)を要約報告
- note-draft.md の「実験4」を「実験3」に修正し、承認を得てコミット・プッシュ

### 気づいたこと
- 複数セッション・複数場所で同じループを育てる場合、pull後の「差分キャッチアップ報告」自体が daily-check の一部になりそう
- 見回り→指摘→人間の判断→修正→記録、の流れが最小サイズで一周した

### 改善点
- 章番号のような機械的に検査できる項目は blog-review の確認観点に追加してもよい

### 次に試すとよさそうなこと
- Phase 1.5 の残TODO(Codex呼び出し方法、Antigravity起動条件、新タスク定義)を人間と設計する

## 2026-07-08 08:50 Dreamingタイム

### 今回やったこと
- リポジトリ全体をレビューし、README/CONTRACT/CLAUDE.md、`.claude/loops/`配下、スクリプト、note下書きを確認した
- `bash -n` で2つのシェルスクリプトの構文を確認し、settings/checkpointのJSONを読み込めることを確認した
- 不明点を QandA.md に Q9〜Q11 として追記した

### 気づいたこと
- `scripts/run-daily-check.sh` は receipts ディレクトリを作る可能性があるのに、最後の表示が「変更は行っていません」となっていて、監査ログ重視の思想と少しずれる
- `checkpoint.json` の lastRun/lastTask が正式タスクだけを指すのか、単発作業やレビューも含むのかが明確ではない
- `docs/note-draft.md` の構成例では tasks が daily-check/pr-hunter/note-experiment だけになっており、現行の blog-review 併存方針と少しずれている

### 未解決
- QandA.md をレビュー時の正式な質問記録先にするかどうか
- checkpoint.json に `lastFormalTask` と `lastActivity` のような区別が必要かどうか
- run-daily-check.sh の表示文言を修正するかどうか

### 次に試すとよさそうなこと
- 人間の承認があれば、run-daily-check.sh の最終表示を「破壊的操作・既存ファイル変更は行っていません」に修正する
- note-draft の構成例に blog-review を追加する
- レビュー系タスクの正式定義を作り、QandA.md への追記条件を明文化する

## 2026-07-08 レビュー反映 Dreamingタイム

### 今回やったこと
- レビュー指摘3件を最小修正: Q10確定(checkpointは全AI作業を記録)、run-daily-check.shの完了表示を「破壊的操作・既存ファイル変更は行っていません」に修正(Q11)、note-draft構成例にblog-reviewを追加
- レシート・checkpoint.json更新、構文/JSON検証まで実施。コミットは承認待ち

### 気づいたこと
- 「未確定」とマークしておいた項目が、人間の一言で確定に変わる流れが定着してきた。QandA.mdが承認の受け皿として機能している
- 監査ログの文言は「何をしていないか」まで正確に書く必要がある。mkdir一つでも「変更なし」とは言えない

### 改善点
- レビュー指摘に「修正済み/未対応」の状態を持たせると、対応漏れの機械的な検出ができそう

### 次に試すとよさそうなこと
- 今回の修正のコミット(承認後)
- Phase 1.5 残TODO(Codex呼び出し設計)の着手
