# Motolii の開発原則

ネットで見つけた表現を、そのまま動画に持ち込めること。エンジンは元から在るものを最大限そのまま解放し、自分の都合で握りつぶさない。成果は使う人が表現を使えること ── コード量や機能数ではない。

1. **エンジンは最小コア。表現を最大限そのまま解放する。** エフェクト・式・シェーダー・形状はユーザが作る側（`shelves/`・外のコード・スクリプト言語）にあり、エンジンは「どう動かすか」の骨組みだけを持つ。外に出せるものは全部外へ：独自の C++ 再実装より、shelves の JS や Lua・QuickJS・ThorVG・Skia の既存コードを動かす。値・範囲・組み合わせを独自の判断で握りつぶさない。制限が要るなら、根拠となる元の仕様に従う。（テキストのパス化も、変形してはみ出した輪郭を切らないのも、元から在るものを解放するこの一つ。）
2. **既存実装を使う。** AE 式・Cavalry・p5.js・シェーダーは元のコードでできる限り動かす。同じ動きを C++ で再実装しない。
3. **情報を二重に持たない。** コードから UI を作り、変更は元のコードに書き戻す。設定のコピーを作らない。アプリの中に Web ページを埋めない。
4. **役割を重複させない。** Dart は見た目に集中し、押し・重ね・選択・OS 連携は既存ライブラリやエンジンに任せる。1 つの役目に 1 つ。正本はエフェクトのカード（`ValuesCard`）で、他は畳む。
5. **小さく直す。** 既存の仕組みで済むなら、新しいライブラリや専用機能を増やさない。外の調べ物は、Motolii に何も無い時だけ。
6. **交換・削除しやすくする。** 外部コード（`shelves/`・`engine/third_party/`）、変更パッチ（`engine/deps/patches/<lib>/`）、動かす口（`engine/community/`）を分け、名前と配置で役割が分かるようにする。名前は After Effects・Filament・Flutter・Blender を使う人の言葉。番号名・3 文字略語は使わない（[renamed_words.md §1](docs/design/renamed_words.md)）。自前は 1 フォルダ 40 本まで（棚の中身は数えない）。
7. **実際に動かして確かめる。** 解析やテストの合格だけでなく、使う人に見える物（画面・映像・書き出したファイル）で確かめる。

判断基準：利用者の表現の自由を狭めず、開発者が保守する独自実装を増やさない。

コメントの書き方：**コードから読み取れない「理由」だけ**を 1 行（長くても 2 行）で書く。ファイル先頭は役割 1 行。
- 残す：制約・罠・順序依存・外部仕様との対応（なぜそうしないといけないか）、ライセンス表記、TODO/FIXME、lint の ignore。
- 消す：コードの言い換え、UAT 番号、After Effects / Alight Motion / Cavalry などとの比較・出典・経緯、設計の動機、過去の不具合の話。
- 長い設計説明は `docs/design/<領域>.md` に移し、コードには `// 詳細: docs/design/xxx.md` を 1 行。コードにある表や値を md に写さない（二重に持たない）。

---

確かめ方・後始末：始める前に `git config core.hooksPath .githooks`。組み立て・調査の出力は `engine/out/`・`app/build/`・`docs/internal/` の外に出さない。ビルドは 1 本ずつ（同時だと機械が落ちる）。手を止める前にコミットし、取り込み終わった worktree とブランチはその場で消す。

確かめる順番：

| いつ | コマンド |
|---|---|
| 常時（Dart を触ったら） | `cd app && dart analyze lib` |
| 常時（C++ を触ったら） | `./engine/check_syntax.sh` |
| コミット前 | `cd app && flutter test` |
| 全テストを走らせたい時 | `cd app && flutter test --dart-define=MOTOLII_RUN_EVERY_TEST=yes` |
| フレームレートを測りたい時 | [docs/TESTING.md](docs/TESTING.md) の「Frame timing」 |
| C++ ユニットテスト | `engine/build.sh test`（重い・エンジンビルドを含む） |
| ミューテーション検査 | `cd app && mutation_test -b <xml>` — XML の書き方は下記 |

ミューテーション検査（`pub global activate mutation_test` で入る）：対象ファイルとテストコマンドを XML に書いて走らせる。テストが変異を検出できなければ、テストに穴がある。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<mutations version="1.0">
  <files>
    <file>lib/inspector/inspector_sync.dart</file>
  </files>
  <commands>
    <command group="test" expected-return="0"
            working-directory="/Users/member_ottoto/motolii/app"
            timeout="120">flutter test test/inspector/inspector_sync_report_test.dart test/inspector/inspector_sync_show_test.dart --dart-define=MOTOLII_RUN_EVERY_TEST=yes</command>
  </commands>
</mutations>
```

現在 Quality A のファイル: `inspector_sync.dart`・`inspector_values.dart`・`field_selection.dart`（全ミューテーション検出済み）。
