# receipt: codex-cli-help-check

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: Codex CLI help限定確認
- 実行時刻: 2026-07-09 14:59:54
- 結果: 実レビューや外部API呼び出しを行わず、CLI 0.142.5のコマンド構造と必要フラグを確認した

## 承認根拠

人間から、実装前の調査としてversion/helpコマンド5件のみ個別承認を得た。実レビュー、実タスク、
外部API呼び出し、`RUN_CODEX=1`、設定変更、`run_codex_process()`実装、Git書き込み操作は禁止された。

## 実行したコマンド

1. `codex --version`
2. `codex --help`
3. `codex exec --help`
4. `codex exec review --help`
5. `codex review --help`

## 確認結果

- バージョン: `codex-cli 0.142.5`
- reviewコマンドは2系統存在する
  - `codex exec review`: exec共通の安全・出力制御オプションを利用できる実装候補
  - `codex review`: 簡易な独立コマンド。review対象指定以外のオプションが少ない
- `codex exec review`で確認できた出力制御:
  - `--output-last-message <FILE>` (`-o`)
  - `--output-schema <FILE>`
  - `--json`
- 設定分離・検証:
  - `--ignore-user-config`
  - `--ephemeral`
  - `--strict-config`
- 作業ルートと安全ポリシー:
  - `--cd <DIR>` (`-C`)
  - `--sandbox read-only` (`-s read-only`)
  - `--ask-for-approval never` (`-a never`)
- `--ask-for-approval`はトップレベルhelpに存在するが、`codex exec review --help`には直接表示されない。
  親コマンド側のグローバルオプションとして`codex -a never ... exec ... review`の順で指定する。
- 実装時の基本形候補:
  `codex --strict-config -s read-only -a never -C <ROOT> exec --ignore-user-config --ephemeral review --output-schema <SCHEMA> --output-last-message <OUTPUT> --json -`

## 確認できなかったもの

- `--ignore-user-config`、`--ephemeral`、`--strict-config`、`--cd`、read-only sandbox、
  approval never、`--output-last-message`、`--output-schema`はすべて存在を確認できた
- help確認だけでは、上記の組み合わせが実レビュー時に正常動作することまでは未確認
- `codex review`単体では、出力schema、最終メッセージ出力、sandbox、approval、作業ディレクトリ、
  ephemeral、user config無視の各フラグはhelpに表示されなかった

## 実装方針への影響

- 設計上のコマンド名`codex exec review`は実在し、そのまま採用可能
- 独立した`codex review`より、構造化出力と安全制御を備える`codex exec review`を使用する
- JSONLから最終回答を自前抽出する必要はなく、`--output-last-message`を主経路にできる
- `--output-schema`でCLI側にもSchemaを渡し、受領後のローカル検証と二重化できる
- 安全指定は親階層を含むため、フラグの配置順を固定する必要がある
- 実行時の組み合わせ検証は、実Codex起動の別承認後に残る

## 何をしなかったか

- Codexの実レビュー、実タスク、外部API呼び出し
- `RUN_CODEX=1`の設定
- `.claude/loops/settings.json`の変更(`codexExec.enabled`は`false`のまま)
- `run_codex_process()`の実装
- commit / push / merge / PR作成
- help出力全文の記録
