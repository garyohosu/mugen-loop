# task: note-experiment — note記事化のための実験ログ整理タスク

目的: mugen-loopの実験そのものを、note記事「私は何もしないループエンジニアになりたい」の
素材として整理する。**記事の公開は絶対にしない。整理と追記案の作成まで。**

## blog-review.md との役割分担

- このタスク(note-experiment)は「mugen-loop実験の記録」を記事化するためのもの
- 既存のブログ記事やdraft記事の校正・確認は tasks/blog-review.md が担当する
- 迷ったら: 対象がこのリポジトリの実験ログなら note-experiment、外部の記事原稿なら blog-review

## 実行前

- CONTRACT.md と rubrics/writing.md、rubrics/safety.md を読む
- docs/note-draft.md の現在の内容を読む

## 手順

1. 今日のループ実験の確認
   - 今日(または前回実行以降)のループ実験で何をしたかを、
     receipts/ と state/checkpoint.json から確認する
2. 素材から発見を抜き出す
   - receipts/、dream.md、firststep.md、README.md を読み、記事に使える発見を抜き出す
   - 例: うまく回った仕組み、止まった場面、人間とAIの役割分担の気づき
3. 失敗、不明点、設計判断も正直に記録する
   - うまくいかなかったこと、まだ分からないこと、迷った末の設計判断を、隠さず素材として残す
   - 実験記事の価値は正直さにある(rubrics/writing.md 5番)
4. 「何もしないために何を設計したか」を整理する
   - 今日、人間が設計したもの(契約・基準・境界線)と、
     その結果AIが自律的にできたことを対応づけて整理する
5. docs/note-draft.md への追記案を作る
   - どのセクションに何を足すかを明示した追記案を作成する
   - 反映してよいのは docs/note-draft.md のみ(CONTRACT.md 許可範囲)
   - 大きな構成変更は提案にとどめ、人間の判断を待つ

## 禁止事項

- noteへの公開・予約投稿・外部サービスへの送信
- receipts の原文の改変
- 秘密情報・個人情報の記事素材への転記

## 実行後

- receipts/YYYY-MM-DD/ にレシートを残す
- 「何をしたか、なぜしたか、何をしなかったか」を必ず書く
- state/checkpoint.json を更新する
