# task: blog-review — 文章レビュータスク(記事を読む係)

目的: 既存の記事下書き・README.md・docs/note-draft.md などの文章をレビューし、
公開前に直すべき点を提案する。
**このタスクは記事を公開しない。修正もしない。指摘と提案のみ。**

## note-experiment.md との役割分担

- blog-review(このタスク)は「文章そのもの」を見る係
  - 対象: 既存の記事下書き、README.md、docs/note-draft.md などの本文
  - 観点: タイトル、H1、読みやすさ、誤字脱字、参考リンク、公開前TODO
- note-experiment は「実験ログ」を見る係
  - mugen-loop実験そのものをnote記事に育てる(tasks/note-experiment.md 参照)
- 迷ったら: 文章の出来を確認したいなら blog-review、記事の素材を増やしたいなら note-experiment

## 実行前

- CONTRACT.md と rubrics/writing.md、rubrics/safety.md を読む
- レビュー対象のdraft記事の場所を人間に確認する(contract.local.md に書いてあればそれに従う)

## 手順

1. タイトルとH1の確認
   - タイトルと本文のH1が一致しているか、内容を正しく表しているか確認する
2. 参考リンクの確認
   - リンクの記載漏れ、明らかに間違ったURL、リンク切れの疑いを列挙する
   - (外部アクセスが許可されていない場合は、形式チェックのみ行い、その旨を記録する)
3. 読みやすさの確認
   - rubrics/writing.md の基準で評価する(初心者に分かるか、断定しすぎていないか)
4. 誤字脱字の確認
   - 該当箇所を引用して修正案を添える
5. 公開前TODOの抽出
   - 記事内の「TODO」「あとで」「仮」などの未完了マークを列挙する
   - 公開前チェックリストとしてまとめる

## 禁止事項

- 記事の公開・予約投稿・下書きの上書き
- 外部サービス(CMS等)へのアクセス(人間の承認がある場合を除く)

## 実行後

- レビュー結果を receipts/YYYY-MM-DD/ にレシートとして残す
- state/checkpoint.json を更新する
