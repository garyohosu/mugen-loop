# receipt: prefer-windows-native-codex

## 基本情報

- タスク名: Windows native Codex resolver優先化
- 実行時刻: 2026-07-09 16:09:39 JST
- 結果: 方針修正とダミー`.cmd`検証に合格

## 確認結果

- Git Bash `uname`: `MINGW64_NT-10.0-26200`
- Git Bash `command -v codex`: `/c/Users/hantani/AppData/Roaming/npm/codex`
  - 拡張子なしPOSIX shell shim
- Git Bash `where.exe codex`:
  - npmの拡張子なしshim
  - npmの`codex.cmd`
  - WindowsAppsの拡張子なし実体
  - WindowsAppsの`codex.exe`
- PowerShell:
  - `codex.ps1`、`codex.cmd`、拡張子なしshim、`codex.exe`を解決可能

## 実装内容

- `uname`がMINGW/MSYS/CYGWIN系ならWindows互換shellとして扱う
- Windowsでは`where.exe codex`を`command -v codex`より先に確認
- 選択順: `.cmd`、`.bat`、`.exe`、その他
- Windows native候補がない場合だけ`command -v codex`へfallback
- `CODEX_PATH`が指定された場合は単一ファイルパスとして最優先
- 引数を含む`CODEX_COMMAND`はshell再解釈の危険があるため採用しない
- 現環境の解決結果: `/c/Users/hantani/AppData/Roaming/npm/codex.cmd`
- `.cmd/.bat`は既存の安全な`cmd.exe /d /s /c`経路へ渡す

## ダミー検証

- 選択順`.cmd` > `.bat` > `.exe` > その他: 合格
- `CODEX_PATH` override: スペースを含む単一パスで合格
- ダミー`.cmd`:
  - スペース、引用符、`&`、`%`、`%PATH%`を完全保存
  - 標準入力を完全保存
  - exit 0
- Bash構文: 合格

## 何をしなかったか

- 実Codex、外部API、費用発生処理
- `RUN_CODEX=1`
- `.claude/loops/settings.json`の変更(`codexExec.enabled=false`のまま)
- commit / push / merge / PR作成
