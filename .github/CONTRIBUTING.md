# 関わり方

*English version: [.github/CONTRIBUTING.en.md](CONTRIBUTING.en.md). English is fine for issues and pull requests. Contributions are dual licensed under Apache-2.0 or MIT, as the project is. Short version: build with the README, run the checks below, and say in your pull request what you borrowed from where.*

## できること

- **Issue**：不具合、組み立てで止まった所、「この表現を使いたい」という見本（URL と、何が良いのか）。ひな型があります。
- **Pull Request**：受けます。Motolii は Apache-2.0 と MIT のダブルライセンスで、送ってもらった物も、特に断りが無ければ同じ二つのライセンスで受けます。
- **同梱した作品の作者の方**：載せ方の直し・外してほしい時は Issue で。すぐ直すか外します（[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)）。

## 組み立て

[`README.md`](../README.md) の「使ってみる」のとおり。コミットする人は、クローンした所で一度だけ：

```bash
git config core.hooksPath .githooks
```

入れなくても、ほぼ同じ検査が push と PR のたびに GitHub（`.github/workflows/checks.yml`）で回ります。入れておくと、GitHub で落ちる前に手元で止まります。

コードと文書の言葉は After Effects・Filament・Flutter・Blender と同じです：アプリ、エンジン、レイヤー、プロジェクト、プレビュー（コードでは `Stage`）。左のタブだけ「棚」（Blender の Asset Shelf）。新しい言い方は作りません。

## コミットで走る検査

コミットのたびに `.githooks/pre-commit`（マージのコミットは `pre-merge-commit` が同じ物）と `.githooks/commit-msg` が走り、断られたら最後の行に `refused by .githooks/<ファイル>` と出ます。各検査の詳しい直し方は [`.githooks/README.md`](../.githooks/README.md)。手で走らせるには、リポジトリの直下で `python3 .githooks/<ファイル>.py`。

| 検査 | 断る物 | コミット | GitHub（checks.yml） |
|---|---|---|---|
| `layout_check.py` | 置き場（AGENTS.md「構成の目標」）：直下の余計な物、入口の README の表に無いフォルダ、`out/`・`build/` が git に入る、番号や「文字＋数字」の名前、1 フォルダに自前のファイル 40 本を超える。日本語の `.md` に `.en.md` が無い、または英語の要約が無い | ステージした物 | 全部 |
| `path_check.py` | 棚のファイルと自前の `.md` が書いている道（`import`・画像・リンク）の先が無い | ステージした棚のファイル（何かを消す・動かす時は全部） | 全部 |
| `card_check.py` | Inspector のカードを Dart で手描きする（値の名前を文字列で書く）。カードはエンジンの `card_table.h` に宣言する | ステージした物 | 全部 |
| `reach_check.py` | アプリが届かない物：どこからも呼ばれない `motolii_*` の C の呼び出し、`app/lib` の公開クラス | ステージした物 | 全部 |
| `format_check.py` | `dart format` のままでない Dart | ステージした Dart。`dart` が無ければ飛ばす | **走らない** |
| `shape_check.sh` | [ast-grep](https://ast-grep.github.io/) が `.githooks/rules/` の形を断る：Dart の手書きの押し・ホバー・重ね・手描き、C++ のレイヤーの種類を名前で比べる枝。ステージしたファイルは、HEAD より断られる形を増やせません | ステージした物。ast-grep が無ければ飛ばす | 全部（ast-grep を入れて走る） |
| `subject_check.py` | 件名（1 行目）が 72 字を超える | 書いているコミット | PR・push が持ち込む全コミット |


`git commit --no-verify` で手元の検査は飛ばせますが、GitHub で同じ検査が落ちます（`format_check.py` は GitHub に無いので落ちません）。

自分で試すとき：

- Dart：`cd app && dart analyze lib`
- C++：`./engine/check_syntax.sh`（組み立てずに構文だけ見る。何も書かない）

GitHub の Actions で全部を組み立てるのは `.github/workflows/build.yml`（Apple Silicon の Mac で、README の手順どおり組んで `flutter analyze`。`engine/`・`shelves/`・`app/`・`Brewfile` に触る main への push と PR、そして Actions の画面から手で）。自分で書いた試験はありません（コードと試験を同じ手が書いていたので、2026-11-08 に全部消しました）。外から求める条件は [`docs/TESTING.md`](../docs/TESTING.md)。作りは [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) と [`engine/README.md`](../engine/README.md)。行動規範は [`.github/CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)、脆弱性は [`.github/SECURITY.md`](SECURITY.md)。


## 決まり

### 1. 作る前に探す
新しく書く前に、ディレクトリ（`engine/` 本体、`app/` アプリ、`docs/` 調べた紙）と、ネットの既存の実装を探してください。作者のやり方のまま使える物があれば、それを使います。既にある物を言葉で引く道具：`python3 .githooks/what_exists.py wave copies`。

### 2. 1 ファイル 1 役目、500 行まで
超えそうなら、役目ごとに名前を付けて分けてください（`_2` のような番号の名前は止まります）。実験は自分のブランチに置き、main にはアプリが使う物だけを入れます。

### 3. コミットのメッセージ
- **件名**（1 行目）は 72 字まで、何を変えたかを書きます。例：`Remove the unused Foo card`、`Fix Y in Z`。
- 1 行空けて**本文**に、なぜ変えたか、何を確かめて何がまだかを書きます。
- 何かを借りた時は、どこから借りたか（URL・版かコミット）を本文に書きます。例：`git show d46f69cac`。
- 件名が 72 字を超えると `.githooks/commit-msg` がコミットを止め、GitHub も PR を落とします。書いた文は `git commit -e -F <ファイル>` で戻ります。

### 4. 他の人の作品を入れる時
- 作者のフォルダごと、なるべく手を入れずに置く。隣に作者のライセンスの文書（`LICENSE`）と、取ってきた所（`SOURCE.txt`：名前と作者／licence／from／page）。
- 作者がライセンスの文書を出していない物は入れない（入れる代わりに、組み立ての時に作者の所から取る：`engine/deps/midi_roll.sh` が例）。
- 手を入れる物は、元に当てる差分（`.patch`）に分けて、元は組み立ての時に作者の配布元から取る（差分は `engine/deps/patches/<ライブラリ>/`、`engine/deps/thorvg.sh` が例）。
- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) に行を足す。

## 手を付けやすい所

| 何 | どこから | 難しさ |
|---|---|---|
| 配れる `.app`：エンジンが読む Homebrew の部品（GStreamer・glib・SQLite・LuaJIT・QuickJS）を `.app` の中に入れる。[dylibbundler](https://github.com/auriamg/macdylibbundler) か GStreamer の macOS 用フレームワーク | `engine/edit.sh`、`app/macos/` | 中 |
| AviUtl2 のスクリプトで足りない呼び出し（`obj.computeshader`、本体のエフェクトなど）を、手本（AviUtl2 の lua.txt、sashimono-edit）どおりに | `docs/internal/reports/aviutl/aviutl2/converter_plan.md`、`engine/community/aviutl/aviutl.cpp` | 中〜難 |
| TSL の表現を編集の棚に出す | `engine/community/three_shading_language_to_shelf/`、`docs/internal/reports/effects/tsl_collection.md` | 中 |

## 知っている穴

- 動くのは macOS（Apple Silicon）だけ。
- エンジン（`libmotolii.dylib`）は Homebrew の GStreamer などを読むので、作った `.app` はそのままでは他の Mac で動きません。
