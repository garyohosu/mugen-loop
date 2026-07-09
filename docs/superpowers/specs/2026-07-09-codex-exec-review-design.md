# Codex exec 読み取り専用レビュー設計

## 1. 目的

Phase 1.5: Multi-Agent Review Loop において、Codex execを「高価なセカンドオピニオン」として限定利用する。
対象はコード差分と文書・設計の両方とし、Codexの出力を最終判断には使わない。
Claude Codeが内容を再確認し、採否を決定してから人間へ報告する。

この文書は呼び出し方法、権限、タイムアウト、利用回数、出力形式、監査方法を確定する。
CLI呼び出しコード、新規タスク定義、Antigravity fallbackは本設計の実装範囲に含めない。

## 2. 前提

- 実行環境はGitリポジトリのルートとする
- Codex CLIがインストール済みで、非対話実行に必要な認証が完了していること
- 設計確認時のローカルCLIは `codex-cli 0.142.5`
- 実行には環境変数 `RUN_CODEX=1` の明示指定が必要
- `.claude/loops/settings.json` の `codexExec.maxRunsPerDay` は1とする
- `dryRun=true`、`allowFileChanges=false`、`allowPush=false`、`allowMerge=false`、
  `allowPullRequestCreation=false` を維持する

## 3. 採用方式

コードレビューと文書レビューで入口を分けるハイブリッド方式を採用する。

### 3.1 コードレビュー

Codex CLIのレビュー専用サブコマンドを使う。

- 未コミット差分: `codex exec review --uncommitted`
- ブランチ差分: `codex exec review --base <明示されたベースブランチ>`

呼び出し側は `uncommitted` または `branch` を必須入力として受け取る。
`branch` の場合はベースブランチ名も必須とする。
範囲が未指定、両方指定、ベースブランチが存在しない場合はCodexを起動せず失敗とする。
自動的なベースブランチ推測は行わない。

### 3.2 文書・設計レビュー

通常の `codex exec` を使い、対象ファイルを明示したプロンプトでレビューする。
対象ファイルはリポジトリルート配下の既存ファイルに限定する。
ワイルドカード、ディレクトリ全体、リポジトリ外のパスは初版では受け付けない。
呼び出し側で正規化したパスがリポジトリルート配下に収まることを確認してから起動する。

### 3.3 共通オプション

両方の呼び出しに次を明示する。

```text
--ignore-user-config
--ephemeral
--strict-config
-c sandbox_mode="read-only"
-c approval_policy="never"
--output-schema <review-schema.json>
--json
```

通常の `codex exec` では、加えて `--cd <repository-root>` を指定する。
`codex exec review` はリポジトリルートをカレントディレクトリとして起動する。

`--ignore-user-config` により個人の `config.toml` とMCP設定への依存を除く。
`--ephemeral` によりセッションのロールアウトを永続化しない。
`sandbox_mode="read-only"` によりモデルが起動するコマンドの書き込みを禁止する。
`approval_policy="never"` により追加権限要求を対話待ちにせず失敗させる。

危険なバイパスオプション、`workspace-write`、`danger-full-access`、追加書き込みディレクトリ、
ライブWeb検索は使用しない。プロンプトにも、MCP、Web検索、外部API、ファイル変更を使わず、
ローカルの対象だけをレビューするよう明記する。

## 4. 入力

共通入力は以下とする。

- `reviewType`: `code` または `document`
- `purpose`: なぜ重要レビューが必要かを示す短い説明
- `requestedBy`: 実行を判断した主体

コードレビューでは以下を追加する。

- `scope`: `uncommitted` または `branch`
- `baseBranch`: `scope=branch` の場合のみ必須
- `focus`: セキュリティ、正確性、保守性などの確認観点

文書レビューでは以下を追加する。

- `files`: 1件以上の明示的な対象ファイル
- `focus`: 契約整合性、安全性、曖昧さ、実装可能性などの確認観点

プロンプトには、推測で問題を作らないこと、指摘には対象箇所と根拠を付けること、
レビューできなかった範囲を明記することを含める。

## 5. JSON出力

最終出力はJSON Schemaで次の形に固定する。

```json
{
  "reviewStatus": "pass | findings | incomplete",
  "summary": "string",
  "scope": {
    "reviewType": "code | document",
    "target": "string"
  },
  "findings": [
    {
      "severity": "critical | high | medium | low",
      "title": "string",
      "file": "string",
      "line": 1,
      "evidence": "string",
      "recommendation": "string",
      "confidence": "high | medium | low"
    }
  ],
  "unreviewed": ["string"]
}
```

`line` は特定できない場合に限り `null` を許可する。
`findings` は指摘なしの場合に空配列とする。
`reviewStatus=incomplete` の場合は `unreviewed` を1件以上必須とする。
Schemaは未知フィールドを拒否する。

`--json` のJSONLイベント列は診断用の一時データとして扱う。
監査ログへ保存するのは、Schema検証済みの最終JSONから必要な項目を抽出した内容だけとする。
認証情報、環境変数、推論過程、コマンドの生出力は保存しない。

## 6. タイムアウトと回数制限

Codexプロセスのハードタイムアウトは10分とする。
10分を超えた場合はプロセスツリーを終了し、結果を採用しない。
後処理とレシート作成を含むタスク全体は、既存設定の15分以内に収める。

1日あたりの上限は1回とする。
「1回」はCodexプロセスの起動に成功した時点で消費したものと数える。
成功、指摘あり、タイムアウト、認証失敗、CLI異常、利用枠到達のいずれでも再実行しない。
入力検証で起動前に拒否した場合は消費しない。

当日の実行済み判定は、既存レシート内の機械判定可能な
`codexRunStarted: true` と実行日を使う。
上限到達時はCodexを起動せず、その事実をレシートへ記録する。

## 7. 結果分類

呼び出し側は結果を次のいずれかに分類する。

- `completed`: 終了コードが成功で、最終JSONがSchemaに適合
- `timeout`: 10分を超過
- `auth_error`: 認証に関する明確なCLIエラー
- `limit_reached`: 利用枠到達を示す明確なCLIエラー
- `cli_error`: その他の非ゼロ終了
- `invalid_output`: 最終JSONの欠落またはSchema不適合
- `blocked_by_gate`: 実行フラグ、入力、日次上限のいずれかで起動前に拒否

エラー文字列の全文一致には依存しない。
CLIの構造化イベントや終了コードで確定できない場合は `cli_error` とし、
推測で `limit_reached` に分類しない。

Antigravityを起動する条件と方法は別設計で確定する。
本設計では結果分類とレシート記録まで行い、自動fallbackは行わない。

## 8. Claude Codeによる再確認

Codexの指摘は提案であり、最終判断ではない。
Claude Codeは各指摘について対象ファイルと根拠を直接確認し、次のいずれかに分類する。

- `accepted`: 根拠を確認し、報告へ反映
- `rejected`: 誤認またはスコープ外として不採用
- `needs_human_decision`: 仕様判断が必要なため人間へ確認
- `not_verified`: 制約により確認不能

Codexの重大度をそのまま採用せず、再確認後の重大度を別に記録する。
Phase 1.5では修正を自動実行せず、報告と提案までで停止する。

## 9. レシート

レシートには以下を記録する。

- タスク名、開始・終了時刻
- `reviewType`、対象、目的
- 実行ゲートの判定
- `codexRunStarted: true | false`
- Codex CLIバージョン
- 適用したsandbox、approval、ephemeral、user-config無効化
- 結果分類、終了コード、経過時間
- Schema検証済みの要約と指摘
- Claude Codeによる各指摘の再確認結果
- 自動修正、push、merge、PR作成、外部送信を行わなかったこと

プロンプト全文、JSONLイベント列、環境変数、認証情報、秘密情報は記録しない。
必要なエラー情報は秘密情報を除去した短い分類と要約に限定する。

## 10. 実装単位

設計承認後の実装は次の単位に分ける。

1. JSON Schema
2. 入力検証、実行ゲート、日次上限判定
3. Codexプロセス起動と10分タイムアウト
4. JSONLからの最終出力抽出とSchema検証
5. レシート生成
6. コードレビューと文書レビューのタスク定義
7. 失敗系を含むテスト

Antigravity fallbackは上記と分離し、fallback条件の承認後に追加する。

## 11. 検証項目

- `RUN_CODEX` が未設定または `1` 以外なら起動しない
- 当日実行済みなら起動しない
- コード差分範囲が曖昧なら起動しない
- 文書パスがリポジトリ外、存在しない、またはディレクトリなら起動しない
- Codexからファイル変更が発生しない
- 10分でプロセスツリーが終了する
- 正常JSON、指摘なしJSON、`incomplete` JSONを受理できる
- Schema不適合、非ゼロ終了、認証失敗、利用枠到達を区別して記録できる
- JSONL、生ログ、秘密情報をレシートへ書かない
- Claude Codeの再確認なしに指摘を最終報告へ採用しない

## 12. 参考仕様

- [Codex non-interactive mode](https://developers.openai.com/codex/noninteractive)
- [Codex CLI reference](https://developers.openai.com/codex/cli/reference)
- [Codex sandboxing](https://developers.openai.com/codex/concepts/sandboxing)
