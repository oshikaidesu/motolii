# 関わり方

*English version: [.github/CONTRIBUTING.en.md](CONTRIBUTING.en.md). English is fine for issues and pull requests. Contributions are dual licensed under Apache-2.0 or MIT, as the project is. Short version: build with the README, run the checks below, and say in your pull request what you borrowed from where. If adding a line to ASSETS.md is too much, say so in the pull request and the maintainer will add it.*

## できること

- **Issue**：不具合、組み立てで止まった所、「この表現を使いたい」という見本（URL と、何が良いのか）。ひな型があります。
- **Pull Request**：受けます。Motolii は Apache-2.0 と MIT のダブルライセンスで、送ってもらった物も、特に断りが無ければ同じ二つのライセンスで受けます。
- **同梱した作品の作者の方**：載せ方の直し・外してほしい時は Issue で。すぐ直すか外します（[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md)）。

## 組み立て

[`README.md`](../README.md) の「使ってみる」のとおり。コミットする人は、クローンした所で一度だけ：

```bash
git config core.hooksPath .githooks
```

コードと台帳の言葉：画面（アプリ）を「窓」、エンジンを「中身」、レイヤーを「物」、プロジェクトファイルを「書類」、プレビュー（Stage）を「場面」、左のタブを「棚」と呼んでいます。

## 確かめ方

| 何を | コマンド | 通った時 |
|---|---|---|
| 台帳（下の決まり 2） | `python3 .githooks/assets_check.py` | `ASSETS.md covers all … files` |
| 窓の書き方 | `cd skin/book && flutter analyze lib` | エラー 0（今ある注意は 100） |

GitHub の Actions は、台帳の確かめを毎回走らせます（`.github/workflows/assets.yml`、知らせるだけで PR は止めない）。組み立て全部は `.github/workflows/build.yml`（Apple Silicon の Mac で、README の手順どおり組んで `flutter analyze`。コードに触る PR と、Actions の画面から手で）。自分で書いた試験はありません（コードと試験を同じ手が書いていたので、2026-11-08 に全部消しました）。外から求める条件は [`docs/TESTING.md`](../docs/TESTING.md)。作りは [`docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md) と [`engine/README.md`](../engine/README.md)。行動規範は [`.github/CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)、脆弱性は [`.github/SECURITY.md`](SECURITY.md)。

## 決まり

### 1. 作る前に探す
新しく書く前に、[`ASSETS.md`](../ASSETS.md)（手元に在る物の台帳）と、ネットの既存の実装を探してください。作者のやり方のまま使える物があれば、それを使います。

### 2. 新しいファイルは台帳に 1 行
`ASSETS.md` は「何が在って、どこまで確かめたか」の表です。コミットの前に `.githooks/assets_check.py` が走り、台帳に場所の無いファイルがあると止まります。新しい物は行を足すか、在る行に場所を足してください（場所は `` ` `` で囲む。フォルダを書けば中身は全部）。**難しければ `git commit --no-verify` で進めて、PR にそう書いてください。取り込む時に足します。**

### 3. コミット（PR）の本文に出典
何をどこから借りたか（URL・版かコミット）と、何を確かめて何がまだかを書きます。例：`git show d46f69cac`。1 行目（見出し）は 72 字くらいまでに短く、詳しい事は 1 行空けて本文に（git の慣習。今までの履歴は見出しが長い物が多いが、これからは）。

### 4. 他の人の作品を入れる時
- 作者のフォルダごと、なるべく手を入れずに置く。隣に作者のライセンスの文書（`LICENSE`）と、取ってきた所（`SOURCE.txt`：名前と作者／licence／from／page）。
- 作者がライセンスの文書を出していない物は入れない（入れる代わりに、組み立ての時に作者の所から取る：`engine/midi_roll.sh` が例）。
- 手を入れる物は、元に当てる差分（`.patch`）に分けて、元は組み立ての時に作者の配布元から取る（`engine/dawn_probe/tvg_on_dawn.sh` が例）。
- [`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) に行を足す。

## 手を付けやすい所

| 何 | どこから | 難しさ |
|---|---|---|
| 配れる `.app`：中身が読む Homebrew の部品（GStreamer・glib・SQLite・LuaJIT・QuickJS）を `.app` の中に入れる。[dylibbundler](https://github.com/auriamg/macdylibbundler) か GStreamer の macOS 用フレームワーク | `engine/edit.sh`、`skin/book/macos/` | 中 |
| AviUtl2 のスクリプトで足りない呼び出し（`obj.computeshader`、本体のエフェクトなど）を、手本（AviUtl2 の lua.txt、sashimono-edit）どおりに | `reports/aviutl2/converter_plan.md`、`engine/aviutl.cpp` | 中〜難 |
| TSL の表現を編集の棚に出す | `engine/tsl/`、`reports/tsl_collection.md` | 中 |
| 台帳 `ASSETS.md` の見出しに英語を添える | `ASSETS.md` | 易 |

## 知っている穴

- 動くのは macOS（Apple Silicon）だけ。
- 中身（`libmotolii.dylib`）は Homebrew の GStreamer などを読むので、作った `.app` はそのままでは他の Mac で動きません。
- `engine/` の直下には、今の中身と前の試しのファイルが並んでいます（前の試しのスクリプトは `engine/sdk.sh` が取る組み立て済みの Filament を使う）。
