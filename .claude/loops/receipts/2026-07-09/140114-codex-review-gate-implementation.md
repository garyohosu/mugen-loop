# receipt: codex-review-gate-implementation

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: codex-review-gate-implementation(人間承認範囲内でのCodex exec実装第一段階)
- 実行時刻: 2026-07-09 14:01:14
- 結果: Codexレビュー用のschema・タスク定義・ゲート/検証/開始レシート実装を作成した。Codexプロセスの起動は未実装のスタブのまま。実Codex実行、commit/push/merge/PR、Antigravity fallbackは行っていない

## 承認根拠

人間から次の範囲の実装承認を得た。

> 実装を承認する範囲: 1) schemaの新規作成 2) タスク定義の新規作成 3) run-codex-review.shの新規作成
> 4) 二重ロック判定、日次上限判定、入力検証、開始レシート作成までの実装
> 5) Codexを実際に起動する処理は、まだスタブまたは明示的に無効化された状態にしてください

あわせて、settings.jsonのcodexExec.enabled変更禁止、RUN_CODEX=1での実Codex実行禁止、
Codexプロセス起動・外部API呼び出し・費用が発生する処理の禁止、commit/push/merge/PR作成の禁止、
Antigravity fallback実装の禁止が明示された。

## 何をしたか

- `.claude/loops/schemas/codex-review-output.schema.json` を新規作成した
  - 設計書(docs/superpowers/specs/2026-07-09-codex-exec-review-design.md)§5のJSON構造をJSON Schema(draft-07)化
  - `additionalProperties: false`で未知フィールドを拒否、`line`はnull許容、`findings`は空配列許容、
    `reviewStatus=incomplete`のとき`unreviewed`が1件以上必須になる条件分岐(`allOf`/`if`/`then`)を実装
  - `node -e`によるJSON構文検証を実施しOKだった
- `.claude/loops/tasks/codex-review.md` を新規作成した
  - code/documentを1タスクにまとめた(QandA.md Q18の確定方針)
  - 「実装状況」セクションで、Codexプロセス起動が未実装のスタブであることを明記した
  - ゲート拒否時のバイパス禁止、`codexExec.enabled`の無断変更禁止などを禁止事項に明記した
- `scripts/run-codex-review.sh` を新規作成し、実行権限を付与した
  - 二重ロック判定(`check_double_lock`): `settings.json`の`codexExec.enabled`をnodeでJSONパースして確認し、
    環境変数`RUN_CODEX`が`"1"`であることを確認する。どちらか一方でも欠ければ`blocked_by_gate`レシートを
    作成して拒否する(QandA.md Q16)
  - 日次上限判定(`check_daily_limit`): Asia/Tokyo日付ディレクトリ配下に`codexRunStarted: true`を含む
    レシートがあれば拒否する(QandA.md Q17)
  - 入力検証(`validate_input`): `review-type`必須、`code`なら`scope`(`uncommitted`/`branch`)必須で
    `branch`なら`base-branch`の存在を`git rev-parse --verify`で確認、`document`なら`files`必須で
    ワイルドカード拒否・`realpath -m`によるリポジトリルート配下チェック・存在確認を行う
  - 開始レシート作成(`write_start_receipt`): 全ゲート通過時点で`codexRunStarted: true`を含むレシートを
    先に作成する「開始レシート先行方式」(QandA.md Q17-4)を実装した
  - `run_codex_process()`は未実装のスタブ関数とし、実装すべき内容(codex execの呼び出し方、固定オプション、
    タイムアウト、JSON抽出、結果分類)をTODOコメントとして明記した。`main()`からは一切呼び出していない
  - タイムゾーン処理で問題を発見し修正した: この環境の`date`コマンドは名前付きタイムゾーン(`Asia/Tokyo`)の
    zoneinfoを持たず、`TZ=Asia/Tokyo date`は無視されGMT表示になることを確認したため、POSIXオフセット形式
    `TZ=JST-9`に変更した(修正前のまま実装していたら日付境界の判定が誤る可能性があった)
  - リポジトリルートの取得方法にも問題を発見し修正した: `git rev-parse --show-toplevel`は
    `C:/PROJECT/mugen-loop`形式で返るが、`realpath`は`/c/PROJECT/mugen-loop`形式を返すため、
    そのまま文字列前方一致でパス封じ込めチェックをすると常に不一致になるバグがあった。
    `cd`してから`pwd`で`ROOT`を取得し直すことで形式を統一した
- 動作確認(安全な範囲のみ、下記参照)を実施した
- `checkpoint.json`のnotesに今回の実装内容を追記した

## なぜしたか

- 人間の明示承認(実装範囲1〜5、および重要な制限)を根拠とした
- 設計書とQandA.md Q16〜Q18の確定方針に沿って実装単位を最小化した(設計書§10の実装単位1〜2にほぼ相当)

## 何をしなかったか

- `run_codex_process()`の実装(Codexプロセスの実際の起動、10分タイムアウト、JSONL抽出、Schema検証、結果分類) — 明示的にスタブのまま
- `settings.json`の`codexExec.enabled`の変更 — `false`のまま維持した
- `RUN_CODEX=1`を使った実Codex実行 — 一度も`codex`コマンドを呼び出していない
- 外部API呼び出し、費用が発生する処理 — 一切行っていない
- git commit / push / merge / PR作成
- Antigravity fallbackの実装
- ファイルの削除(動作確認で作成された2件のblockedレシートも削除せず保持した。理由は下記)

## 動作確認(安全な範囲のみ)

以下はいずれもCodexプロセスを一切起動せず、ファイル変更・削除・外部通信を伴わない確認である。

1. `bash -n scripts/run-codex-review.sh` — 構文チェックOK
2. `node -e "JSON.parse(...)"` — schema/checkpoint.jsonのJSON構文検証OK
3. 引数なしで実行 → usageを表示しexit code 2(レシートは作成されない、想定通り)
4. `--review-type code --scope uncommitted ...`を実行(`RUN_CODEX`未設定、`codexExec.enabled=false`)
   → 二重ロックで拒否され、`135933-codex-review-blocked.md`が作成された(`codexRunStarted: false`,
   `codexRunResult: blocked_by_gate`)
5. `RUN_CODEX=1`を設定した状態で`--review-type document --files docs/note-draft.md ...`を実行
   (`codexExec.enabled`は`false`のまま) → それでも二重ロックで拒否され、
   `135943-codex-review-blocked.md`が作成された。AND条件(両方trueで初めて通過)が正しく機能することを確認した
6. 現在の`receipts/2026-07-09/`配下を`grep -rl "codexRunStarted: true"`で確認し、
   `codexRunStarted: true`を含むレシートが存在しないこと(=日次上限が未消費であること)を読み取り専用で確認した

上記4,5で作成された2件のブロックレシートは、実際にスクリプトを実行して得られた正直な監査ログであるため
(「試験のために捏造した」ものではない)、既存レシート改変禁止の原則に沿って削除せず保持した。

## 未検証の部分(正直な申告)

- `check_daily_limit`と`validate_input`が全ゲート通過して`write_start_receipt`まで到達する「成功パス」は、
  `codexExec.enabled`を`true`にしない限り`main()`経由では再現できない(二重ロックが常に先に拒否するため)。
  制約により`enabled`を変更していないため、このパスは未実行である。個々の下位処理
  (`realpath -m`によるパス封じ込め、`git rev-parse --verify`によるブランチ存在確認、
  `grep`によるcodexRunStarted検出)は本レシート作成前に個別のBashコマンドで動作を確認済みだが、
  `validate_input`/`write_start_receipt`関数そのものを直接呼び出すテストは行っていない
  (実行すると成功したかのようなレシートが生成されてしまい、監査ログとして不正確になるため意図的に見送った)

## 実Codex実行を行っていないことの確認

- `codex`コマンドは本セッション中一度も実行していない(`run_codex_process()`は`echo`と`return 1`のみのスタブで、
  どこからも呼び出されていない)
- `RUN_CODEX=1`は動作確認5でのみ、ゲートのAND条件を確認する目的で環境変数として設定したが、
  `codexExec.enabled=false`により二重ロックで即座に拒否されているため、Codexプロセスへは到達していない
- 外部ネットワークアクセス、API呼び出しは行っていない

## 人間に確認してほしいこと

- 今回作成した3ファイル(schema/タスク定義/スクリプト)の内容、特に`run_codex_process()`のTODO記述が
  次回実装の指針として十分か
- ブロックレシート2件(動作確認の産物)をこのまま残してよいか、それとも別の扱いを希望するか
- 次のステップ(`run_codex_process()`の実装、または`codexExec.enabled`を`true`にする判断)をいつ・誰が承認するか

## 次回への引き継ぎ

- `run_codex_process()`の実装(設計書実装単位3〜6: プロセス起動・タイムアウト・JSON抽出・結果分類・レシート追記)が次の作業
- `codexExec.enabled`を`true`にする操作は、実装完了後に人間が個別に明示承認してから行う
- 成功パス(ゲート通過→開始レシート作成)の実地検証は、`enabled=true`にした後の最初の安全な確認事項とする
- Antigravity fallback設計は本実装の範囲外のまま
