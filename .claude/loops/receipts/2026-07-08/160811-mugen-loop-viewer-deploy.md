# receipt: mugen-loop-viewer-deploy

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: mugen-loop-viewer-deploy
- 実行時刻: 2026-07-08 16:08:10

## git status

```
 M dream.md
?? .claude/loops/receipts/2026-07-08/155051-mugen-loop-viewer-scaffold.md
```

## 確認した内容

- 人間から直接「デプロイしてください」との明示指示があり、`mugen-loop-viewer`(mugen-loop本体とは別ディレクトリ `C:\PROJECT\mugen-loop-viewer`、git未管理)をロリポップ！デプロイナウへ実際にデプロイした
- 事前に人間から共有されたnote記事(https://note.com/hantani/n/n68e320ef6b43)、およびそこから参照されている公式CLIガイド(https://deploy.lolipop.jp/skills/lolipop-cli.md)を読み、実際のCLI仕様(`lolipop health`/`lolipop login`/`lolipop deploy --name --framework next --json` 等)を確認した
- CLI(`lolipop` v2.0.1)はこの環境に既にインストール・ログイン済みだったため、新規ログイン操作は不要だった(既存プロジェクト `garyohosu-minisite` が `lolipop project list` で確認できた)
- デプロイ実行前に、対象ディレクトリを取り違えないよう `cd /c/PROJECT/mugen-loop-viewer && pwd && lolipop deploy ...` を1つの複合コマンドとして実行し、`pwd` の出力で対象がmugen-loop-viewerであることを確認してから実行した
- `lolipop deploy --name mugen-loop-viewer --framework next --json` を実行し、新規project(id: 01KX08GJJSVBTPAWS5W5T77AVP)を作成・デプロイした。`lolipop project show` でビルド完了(`DEPLOYMENT_STATUS_READY`)を確認し、公開URL `https://mugen-loop-viewer.lolipop-now.app/` へcurlで実際にアクセスして全セクションが表示されることを確認した
- README.mdに公開URL・note記事リンク・検証済みのデプロイ手順を反映した

## なぜしたか(判断根拠)

- 人間からの「ここを見てデプロイしてください」という直接的・明示的な指示があったため。これは最優先安全ルールの一つ「本番環境へ反映しない」の例外にあたる明示承認と判断した
- mugen-loop-viewerはmugen-loop本体(このリポジトリ)のgit管理・書き込み許可範囲の外にあるアプリであり、今回のデプロイ操作はmugen-loop本体のCLAUDE.md/CONTRACT.md/settings.json/rubrics/既存receiptsのいずれにも変更を加えていない
- デプロイ対象ディレクトリの取り違え(mugen-loop本体を誤って公開してしまうリスク)を避けるため、cd・pwd確認・複合コマンド化を徹底した

## 何をしなかったか

- mugen-loop本体(このリポジトリ)側のgit commit / push / PR / mergeは一切行っていない
- lolipop CLIの認証情報(APIキー・トークン・credentials.json等)はreceiptsやチャット上に一切記録・表示していない
- mugen-loop-viewer側もまだgit初期化・commitは行っていない(デプロイのみ実施)

## 提案・気づき

- 今後同種のデプロイ作業を行う場合、CLIが既にログイン済みかどうかを事前に確認する手順(`lolipop project list`など)を先に踏むと、認証待ちで止まるリスクを減らせる

## 人間に確認してほしいこと

- 公開されたダッシュボード(https://mugen-loop-viewer.lolipop-now.app/)の表示内容・デザインに問題がないか
- mugen-loop-viewerディレクトリ自体をgit管理下に置く(コミットする)かどうか

## メモ

- 詳細はチャット側の報告を参照
