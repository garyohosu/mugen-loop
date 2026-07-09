# receipt: fix-edit-policy-wording

<!-- 注意: このレシートに秘密情報(APIキー、トークン、パスワード)を書かないこと -->

## 基本情報

- タスク名: fix-edit-policy-wording（人間の明示承認によるCONTRACT.md/CLAUDE.md/settings.json代行編集）
- 実行時刻: 2026-07-09 13:43:04
- 結果: 「変更は人間のみ」という表現を、「AIは独断で編集禁止だが、人間の明示チャット承認があればAIが代行編集可(5原則付き)」という新方針に修正し、CONTRACT.md/CLAUDE.md/settings.json/README.md/QandA.mdへ実際に反映した

## 承認根拠

人間から次の明示指示を受けた。

> 「人間のみ編集可」としていた箇所は、表現を改める。正しい方針は以下とする。
> CONTRACT.md / CLAUDE.md / settings.json などの重要ファイルは、AIが独断で編集してはいけない。
> ただし、人間がチャット上で明示的に編集を承認・依頼した場合は、AIが代行編集してよい。
> （5原則、および反映対象ファイルの一覧を含む）

これを承認根拠とし、指示内容に限定して編集した。

## 何をしたか

- `CLAUDE.md`
  - 「変更してよい範囲」に `dream.md`（振り返り追記のみ許可）を追加(Q14)
  - 「変更してはいけない範囲」の見出しを「(人間の明示承認がない限り)」に変更し、CONTRACT.md/CLAUDE.md/settings.jsonについて「AIが独断で編集してはならないが、人間の明示承認があれば代行編集可」と5原則付きで書き換えた
  - rubricsは引き続き「常に人間のみが変更する」として代行編集の対象外と明記した
- `CONTRACT.md`
  - 「許可する作業」に、dream.mdへの振り返り追記を追加(Q14)
  - 「禁止する作業」から `settings.json / CONTRACT.md / CLAUDE.md` を外し、rubricsの変更のみ禁止のまま残した
  - 「人間の承認が必要な操作」のファイル書き込み例外行に、docs/loop-status.mdとdream.mdの例外を追記して「許可する作業」と同期した(Q13)
  - 「人間の承認が必要な操作」のsettings.json/CONTRACT.md/CLAUDE.mdの変更について、5原則付きの代行編集ルールを追記した
- `settings.json`
  - `maxChangedFiles` の直後に `_maxChangedFilesNote` を追加し、「許可範囲外の変更数の上限」であることを明文化した(Q19)
- `README.md`
  - 「各ファイルの役割」に `docs/superpowers/specs/` の位置づけ(拡張機能・実験機能の設計書置き場、正式契約ではない)を追記した(Q18)
- `QandA.md`
  - Q3, Q13, Q14, Q18, Q19の「人間のみ編集可能」「人間のみが行う」等の表現を、「人間の明示承認がある場合、AIが代行編集可能」に修正した
  - Q13, Q14, Q18, Q19の将来TODOを、「実際にAIが反映済み」という記述に更新した
- `checkpoint.json` のnotesに今回の方針修正内容を追記した
- 変更後、`git diff`(下記参照)で全変更を確認した

## なぜしたか

- 人間から明示的な承認・依頼があったため(CLAUDE.md/CONTRACT.mdの新方針そのものにより、これが代行編集の正当な根拠となる)
- 「反映対象」として明示された7項目(CONTRACT.md許可範囲同期、CLAUDE.md許可範囲同期、dream.md追記許可、docs/loop-status.mdタスク限定許可、maxChangedFilesの明文化、docs/superpowers/specs/位置づけ追記、QandA.mdの表現修正)に編集範囲を限定した

## 何をしなかったか

- rubricsの変更(新方針でも代行編集の対象外として維持)
- commit / push / PR / merge(別途人間の明示承認が必要、Q25/新方針の原則5)
- 指示された7項目以外のファイルへの追加変更
- 既存レシートの改変

## git diff 確認結果

変更ファイル: `CLAUDE.md`, `CONTRACT.md`, `.claude/loops/settings.json`, `README.md`, `QandA.md`, `.claude/loops/state/checkpoint.json`
(dream.mdは本レシート作成後に別途追記予定)

`git diff --stat` で意図した6ファイルのみが変更されていることを確認した。settings.jsonとcheckpoint.jsonはnode -eによるJSON構文検証もOKだった。

## 人間に確認してほしいこと

- 今回の代行編集内容(CONTRACT.md/CLAUDE.md/settings.json/README.mdの実際の差分)に問題がないか
- 問題なければ、この一式のコミット可否(Q25で確定したテンプレート `chore(loop): record loop outputs for YYYY-MM-DD` が使える)

## 次回への引き継ぎ

- Codex exec実装(Q16〜Q18の設計が出揃ったため着手可能)に進める
- 今回の新方針(代行編集ルール)は、今後CONTRACT.md/CLAUDE.md/settings.jsonへの反映が必要な場面すべてに適用する
