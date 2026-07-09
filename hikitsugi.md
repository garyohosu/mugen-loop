# hikitsugi.md — セッション引き継ぎメモ(2026-07-09)

トークン切れに備えた引き継ぎ資料。次のセッション(人間 or Claude Code)はまずこれを読むこと。
このファイルはCLAUDE.mdの「変更してよい範囲」には含まれないが、人間の明示指示により今回作成した。
役目を終えたら(次セッションの起点として不要になったら)人間の判断で削除してよい。

## 今どこにいるか(要約)

mugen-loopは Phase 1.5: Multi-Agent Review Loop。Codex execを「読み取り専用のセカンドオピニオン」として
限定利用する仕組みは、**安全ゲートと実行本体(`run_codex_process()`)まで実装済み**。
実行本体は**Node.js補助処理＋Bash制御**方式で、10分タイムアウト、固定安全オプション、
`--output-last-message`、JSON Schema検証、結果分類、完了レシート追記を実装している。

- 初回実Codex documentレビューは1回試行したが、Codex CLI本体の起動前にNode.jsの`spawn EPERM`で失敗し、
  `cli_error`として記録済み。Schema検証とレビュー結果生成には到達していない
- 失敗後、Windows npm shim対応resolverを実装済み。POSIX / PowerShell / cmd / bat / directの
  ダミーshim検証はすべて合格
- `.claude/loops/settings.json` の `codexExec.enabled` は **false**
- 2026-07-09は`codexRunStarted: true`の開始レシートがあるため、**同日の実Codex再試行は禁止**
- git: この引き継ぎ更新の着手前は作業ツリーclean。現在は`hikitsugi.md`、checkpoint、
  dream、新規レシートだけが未コミット。ローカルmainはorigin/mainより **11コミット先行**。
  最新コミットは `ad6a13a`。pushは未実施

## 外部AIレビュー方針

- Claude Code: 主作業者・統括・最終確認役
- Codex CLI: 第一レビューアー(primary reviewer)。現在の実装・安定化対象
- Grok / Antigravity: 未実装・非デフォルトの将来候補または補助候補
- 通常運用ではClaude CodeとCodex CLIだけを使用する
- Grok / Antigravityは、Codex CLIでは不足する場合または比較検証が必要な場合に限り、
  人間の個別明示承認を得て使用を検討する。自動fallbackは行わない
- 当面は設定名`codexExec`を維持する。将来provider抽象化を行う場合もdefault providerはCodex CLIとする

## 今回のセッションでやったこと(時系列)

1. `/codex:setup` 実行 → Codex CLI 0.142.5、認証済み、reviewゲートは無効のまま
2. `/codex:review --wait` 実行 → actionable findingsなし
3. QandA.md の優先質問(Q13,Q15,Q16,Q17)に人間が回答 → 反映
4. QandA.md の残り(Q14, Q17続き, Q18〜Q25)に人間が回答 → 反映、関連タスク定義・schedule.yml更新
5. 「CONTRACT.md/CLAUDE.md/settings.jsonは人間のみ編集可」という表現を、
   「AIは独断編集禁止、人間の明示承認があればAIが代行編集可(5原則)」に方針修正
   → CONTRACT.md/CLAUDE.md/settings.json/README.md/QandA.mdへ実際に反映、**コミット済み(`8755f5a`)**
6. Codex exec実装の第一段階を、人間承認範囲(安全ゲートのみ、Codex起動はスタブ)で実装
   - 新規: `.claude/loops/schemas/codex-review-output.schema.json`
   - 新規: `.claude/loops/tasks/codex-review.md`
   - 新規: `scripts/run-codex-review.sh`(二重ロック・日次上限・入力検証・開始レシート作成を実装、
     `run_codex_process()`は未実装スタブ)
   - コミット前確認(人間指定8項目)で `check_daily_limit()` の誤検出バグを発見・修正
   - **コミット済み(`ebe2f33`)**
7. 人間から自己レビュー依頼 → `grep -qx`完全一致がCRLF変換で壊れる残存リスクを発見・報告
8. 承認を得て `receipt_marks_codex_started()`(awkベース、CRLF/LF両対応)に修正
   - **コミット済み(`659a2d6`)**
9. 残存リスクB(ファイル名衝突で誤検出しうる限定事項)を `todo.md` に低優先度TODOとして追記
   - **コミット済み(`9464873`)**
10. `run_codex_process()` の実装方針を詳細化(**まだ実装はしていない**、報告のみ)
    - Codex CLI公式ドキュメントをWebFetchで確認し、設計書の前提(`codex exec review`という
      サブコマンド名)が実際のCLIリファレンス目次と食い違う可能性を発見(要`--help`確認)
    - `--output-last-message <path>`フラグの存在を発見(JSONL逐次パースより単純な抽出方法になりうる)
    - 7項目(コマンド案/タイムアウト実装/JSON抽出/Schema検証/結果分類/レシート追記/追加承認)を整理し、
      「enabled=falseで検証可能な範囲」と「enabled=true(または`--help`起動)が必要な範囲」に分けて報告した
11. Codex CLI 0.142.5のhelpを限定確認
    - `codex exec review`、`--output-last-message`、`--output-schema`、`--ignore-user-config`、
      `--ephemeral`、`--strict-config`、`--cd`、read-only sandbox、approval neverを確認
12. `run_codex_process()`をNode.js補助処理＋Bash制御方式で実装
    - 600秒timeout、プロセスツリー終了、Schema検証、結果分類、完了レシート追記を追加
    - ダミーJSON・ダミープロセス検証後、コミット済み(`559112d`)
13. 初回実レビュー前プリフライトに合格
    - 二重ロック、開始レシート非生成、ブロックレシートの日次上限除外を確認
14. 人間の限定承認で`hikitsugi.md`のdocumentレビューを1回試行
    - 開始レシート: `.claude/loops/receipts/2026-07-09/153850-codex-review.md`
    - `codexRunStarted: true`を記録後、Node.jsの`spawn EPERM`でCLI本体起動前に失敗
    - 最終分類`cli_error`、Schema検証未実施、指摘なし、再確認`not_verified`
    - 実行直後に`codexExec.enabled=false`へ復元
15. Windows npm shim対応resolverを実装
    - `command -v codex`で対象を解決し、`.ps1` / `.cmd` / `.bat` / POSIX shebang /
      通常実行ファイルを判定
    - cmd引数は一時環境変数経由で渡し、スペース・引用符・`&`・`%`・`%PATH%`を保持
    - 全ダミーshim経路、標準入力、非ゼロ終了、timeout、孫プロセス終了を確認
    - コミット済み(`ad6a13a`)

## 次にやるべきこと(優先順)

1. 2026-07-09中は実Codexを再試行しない。Asia/Tokyoの日次上限リセットを待つ
2. リセット後、人間の個別承認を得て、小さいdocumentレビューから1回だけ再試行する
   - 対象候補は`hikitsugi.md`など単一の小さい文書
   - ブランチ全体レビューは、実行経路・Schema検証・完了レシートが正常に一周した後
3. 再試行時だけ、別途承認に基づき`codexExec.enabled=true`へ変更し、
   コマンドプロセス限定で`RUN_CODEX=1`を渡す。終了後は必ず`enabled=false`へ戻す
4. 未pushの11コミットをpushする場合は、実レビューとは別に人間の明示承認を得る
5. 残存リスクB(`todo.md`に記録済み)の対応要否は保留中。優先度低

## 次セッションが必ず守ること(再掲・重要)

- `.claude/loops/settings.json` の `codexExec.enabled` を無断で変更しない
- 2026-07-09は`RUN_CODEX=1`を使った実Codex再試行をしない
- 日次上限リセット後も、次の実行は必ず人間の個別承認後に行う
- Grok / Antigravityを通常運用や自動fallbackで起動しない。利用には別途人間の明示承認が必要
- Codexバイナリの起動(`--help`含む)も、人間の明示承認なしに行わない
- commit / push / merge / PR作成は、都度人間の明示承認があるときだけ
- CONTRACT.md/CLAUDE.md/settings.jsonの編集は、人間の明示承認があれば代行編集可(5原則: 承認根拠明記/
  編集範囲限定/レシート記録/checkpoint・dream更新/commit等は別途承認)。rubricsは常に人間専用
- 作業完了時は必ず `.claude/loops/receipts/YYYY-MM-DD/` にレシートを残し、`checkpoint.json`と
  `dream.md`を更新すること

## 参照すべきファイル

- `docs/superpowers/specs/2026-07-09-codex-exec-review-design.md` — Codex exec設計書(正本)
- `QandA.md` — Q1〜Q25すべて回答済み(Q7はクローズ、Q17の一部・Q19以降も含め全て確定)
- `.claude/loops/tasks/codex-review.md` — 実行手順(実装状況の説明に古いスタブ表記が残る可能性あり)
- `scripts/run-codex-review.sh` — 現在の実装の正本。実行本体・resolverまで実装済み
- `.claude/loops/receipts/2026-07-09/153850-codex-review.md` — 初回実行失敗の開始・完了記録
- `.claude/loops/receipts/2026-07-09/155810-fix-codex-shim-resolver.md` — resolver修正・ダミー検証記録
- `todo.md` — 人間向けTODOリスト(残存リスクB含む)
- `dream.md` — 全セッションの振り返りログ(今回分は末尾に複数エントリあり)
- `.claude/loops/state/checkpoint.json` — 直近の状態要約(notes配列が時系列ログ)
