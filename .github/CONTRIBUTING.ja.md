# 関わり方

[English](CONTRIBUTING.md)

## できること

- **Issue**：不具合、組み立てで止まった所、「この表現を使いたい」という見本（URL と、何が良いのか）。ひな型があります。
- **Pull Request**：受けます。Motolii は Apache-2.0 と MIT のダブルライセンスで、送ってもらった物も、特に断りが無ければ同じ二つのライセンスで受けます。
- **同梱した作品の作者の方**：載せ方の直し・外してほしい時は Issue で。すぐ直すか外します（[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)）。

## 組み立て

[`README.ja.md`](../README.ja.md) の「ビルドして動かす」のとおり（手順の詳しい説明は[ガイド](../docs/using/guide.ja.md#使ってみる)）。コミット時に Dart の整形を確かめる hook を入れるなら、クローンした所で一度だけ：

```bash
git config core.hooksPath .githooks
```

コードと文書の言葉は After Effects・Filament・Flutter・Blender と同じです：アプリ、エンジン、レイヤー、プロジェクト、プレビュー（コードでは `Stage`）。左のタブだけ「棚」（Blender の Asset Shelf）。新しい言い方は作りません。

## 確かめ

PR を送る前に手元で回してください。同じ物を push と PR のたびに CI（`.github/workflows/checks.yml`）が回します。

```bash
cd app && dart format . && flutter analyze && flutter test
```

C++ は、`./engine/check_syntax.sh` が組み立てずに構文を見て、`engine/build.sh` が組み立て、`engine/build.sh test` が組み立てて C++ のテストを走らせます。全部の組み立ては GitHub Actions の `.github/workflows/build.yml`（Apple Silicon の Mac。`engine/`・`shelves/`・`app/`・`Brewfile` に触る main への push と PR、そして Actions の画面から手で）。テストのやり方は [`docs/TESTING.md`](../docs/TESTING.md)。

## 考え方

- **自作は負債。** まず既存の実装を探し、作者のやり方のまま使います。無ければ周りの技術やコミュニティまで探します。
- 他の人の作品はなるべく手を入れずに同梱し、隣に作者のライセンスと出所を置きます。手を入れる時は、元に当てる差分（`.patch`）に分けて元は作者の配布元からダウンロードするか、ファイルの 1 行目に元と改変を書きます。
- 今は自分で書いたコードも多くあります（画面の Flutter など）。借りられる物が見つかれば、自分のコードを捨てて取り替えます。
- コミットごとに、何をどこから借りたか（出典）を書きます。

## 決まり

### 1. 作る前に探す
新しく書く前に、ディレクトリ（`engine/` 本体、`app/` アプリ、`docs/` 調べた紙）と、ネットの既存の実装を探してください。作者のやり方のまま使える物があれば、それを使います。

### 2. 1 ファイル 1 役目
役目ごとに名前を付けて分けてください。実験は自分のブランチに置き、main にはアプリが使う物だけを入れます。

### 3. コミットのメッセージ
- **件名**（1 行目）は 72 字まで、何を変えたかを書きます。例：`Remove the unused Foo card`、`Fix Y in Z`。
- 1 行空けて**本文**に、なぜ変えたか、何を確かめて何がまだかを書きます。
- 何かを借りた時は、どこから借りたか（URL・版かコミット）を本文に書きます。例：`git show d46f69cac`。

### 4. 他の人の作品を入れる時
- 作者のフォルダごと、なるべく手を入れずに置く。隣に作者のライセンスの文書（`LICENSE`）と、取ってきた所（`SOURCE.txt`：名前と作者／licence／from／page）。
- 作者がライセンスの文書を出していない物は入れない（入れる代わりに、組み立ての時に作者の所から取る：`engine/deps/midi_roll.sh` が例）。
- 手を入れる物は、元に当てる差分（`.patch`）に分けて、元は組み立ての時に作者の配布元から取る（差分は `engine/deps/patches/<ライブラリ>/`、`engine/deps/thorvg.sh` が例）。
- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) に行を足す。

## 手を付けやすい所

| 何 | どこから | 難しさ |
|---|---|---|
| 配れる `.app`：エンジンが読む Homebrew の部品（GStreamer・glib・SQLite・LuaJIT・QuickJS）を `.app` の中に入れる。[dylibbundler](https://github.com/auriamg/macdylibbundler) か GStreamer の macOS 用フレームワーク | `engine/edit.sh`、`app/macos/` | 中 |
| AviUtl2 のスクリプトで足りない呼び出し（`obj.computeshader`、本体のエフェクトなど）を、手本（AviUtl2 の lua.txt、sashimono-edit）どおりに | `docs/design/aviutl2_converter_plan.md`、`engine/community/aviutl/aviutl.cpp` | 中〜難 |
| TSL の表現を編集の棚に出す | `engine/community/three_shading_language_to_shelf/`、`docs/design/tsl_collection.md` | 中 |

## 知っている穴

- 動くのは macOS（Apple Silicon）だけ。
- エンジン（`libmotolii.dylib`）は Homebrew の GStreamer などを読むので、作った `.app` はそのままでは他の Mac で動きません。
