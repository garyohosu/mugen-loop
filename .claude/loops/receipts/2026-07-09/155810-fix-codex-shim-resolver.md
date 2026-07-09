# receipt: fix-codex-shim-resolver

## 基本情報

- タスク名: Codex起動resolverのWindows shim対応
- 実行時刻: 2026-07-09 15:58:10 JST
- 結果: resolver実装とダミーshim検証に合格

## 承認根拠

人間から、resolver、Node.js spawn処理、POSIX/PowerShell/cmd/bat/直接実行の判定、
一時ディレクトリ上のダミーshim検証を承認された。実Codex再試行、設定変更、
`RUN_CODEX=1`、外部API、Git書き込み操作は禁止された。

## 実装内容

- Bashの`command -v codex`で起動対象を絶対パス相当へ固定
- Node.js側で次の順にlauncherを判定
  1. `.ps1`またはPowerShell shebang: `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File`
  2. `.cmd` / `.bat`: `cmd.exe /d /s /c`
  3. 拡張子なしのPOSIX shell shebang: `sh`
  4. その他の通常実行ファイル: shellなしで直接spawn
- `.cmd/.bat`では引数値をcommand lineへ連結せず、一時環境変数へ個別格納。
  command lineには固定形式の環境変数参照だけを置き、quoteを二重化
- spawnの同期例外をexit 127へ正規化
- Windows timeoutは`taskkill /T /F`完了と対象closeの両方を待ってからexit 124を返す

## ダミー検証

- POSIX shell shim: `sh`経由で正常起動
- PowerShell shim: 指定オプション経由で正常起動
- `.cmd` shim: `cmd.exe`経由で正常起動
- `.bat` shim: `cmd.exe`経由で正常起動
- 通常実行ファイル: shellなしで直接起動
- 全5経路で次を完全保存
  - スペースを含む引数
  - `"`を含む引数
  - `&`を含む引数
  - `%`を含む引数
  - `%PATH%`という文字列
  - 標準入力
- 非ゼロ終了: exit 23を保持し、`cli_error`へ分類
- timeout: 1秒設定でexit 124
- 孫プロセス: timeout後に終了済みであることをPIDで確認
- `bash -n`: 成功

## 検証中に発見・修正した事項

- cmdの外側引用符と`windowsVerbatimArguments`の組み合わせを修正
- cmdへ直接埋め込むpercent/caret方式は値を完全保存できないため不採用
- 初版timeoutでは`taskkill`完了前に親をkillする競合で孫プロセスが残った
  - 残存したダミープロセスをPIDで特定して停止
  - 状態管理を修正後、孫プロセス終了を再確認

## 何をしなかったか

- `codex`コマンド、実Codexレビュー、外部API、費用発生処理
- `codex.js`の直接起動
- `.claude/loops/settings.json`の変更(`codexExec.enabled=false`のまま)
- `RUN_CODEX=1`の設定
- commit / push / merge / PR作成
