# Motolii

[English](README.md)

[![build](https://github.com/oshikaidesu/motolii/actions/workflows/build.yml/badge.svg)](https://github.com/oshikaidesu/motolii/actions/workflows/build.yml) [![checks](https://github.com/oshikaidesu/motolii/actions/workflows/checks.yml/badge.svg)](https://github.com/oshikaidesu/motolii/actions/workflows/checks.yml)

**離れていた表現の、交差点。**

Shadertoy のシェーダーが曲のビートに反応する。After Effects の式と CSS アニメーションが同じテキストの上で動く。p5.js のスケッチが Lottie の上に重なる。ネットのコードを貼れば、そのまま動く。

After Effects の式も、Shadertoy も、Cavalry も、p5.js も、CSS も、Lottie も。貼るだけで動く、オープンソースの動画編集ソフト。[全部で 20 以上](#何が動く)。

![Motolii の画面：左に素材と棚、真ん中にプレビュー、下にタイムライン、右に値](docs/pictures/window.jpg)

- **GPU ネイティブ。** 式は GPU シェーダーにコンパイルされる。数千コピーが 60fps で動く。
- **エフェクトはただのファイル。** `.wgsl`、`.fs`、`.js` — 開いて、仕組みを読んで、変えられる。ブラックボックスじゃない。
- **1 レイヤーに複数言語。** CSS アニメーション、After Effects の式、シェーダーエフェクトが同じテキストの上で、重ねた順に動く。

## いまの状態

現在は開発途中で、確かめたのは Apple Silicon の Mac（M4、macOS 15.5）だけで、Windows と Linux はまだ試していません。配布用アプリはまだ用意していないため、試す場合はソースコードからビルドする必要があります。

- **動く**：動画・写真・文字・図形・3D モデル・点群・Lottie アニメーションを同じシーンに置く、キーフレームとイージング、自動保存と取り消し、再生（動画の音も鳴る）、MP4 への書き出し。
- **動く**：ネットのエフェクト。ISF（`.fs`）と WGSL（`.wgsl`）のファイルは、エフェクトのフォルダに置くと、アプリを再起動せずにエフェクト一覧に出ます。p5.js のスケッチと Shadertoy のシェーダーは、貼り付けるとレイヤーになります。対応形式のコードでも、すべてが正しく動作するわけではありません。
- **一部**：AviUtl2 のスクリプト、Alight Motion の機能。
- **まだ**：Windows、配布できる `.app`（エンジンが Homebrew の部品を読むので、ビルドした Mac の外では動かない）、MIDI の音。

形式ごとの動作状況と数、知っている不具合は[仕様の「対応形式と動作状況」](docs/using/specifications.ja.md#対応形式と動作状況)にあります。

## ビルドして動かす

要る物：

- Apple Silicon の Mac（確かめたのは M4、macOS 15.5）。
- App Store の Xcode（Command Line Tools だけでは画面をビルドできません）。入れたら一度開いて追加の部品を入れ、`sudo xcodebuild -license accept`。
- Homebrew：[brew.sh](https://brew.sh/ja/) の 1 行。
- Flutter 3.47.2（stable）を `PATH` に：[ガイドの「Flutter を入れる」](docs/using/guide.ja.md#flutter-を入れる)。
- Python 3：macOS に付いている物（Xcode を入れると入る）でよい。
- 空き容量：Xcode と Flutter のほかに約 10 GB。

そのあと、1 行ずつ：

```bash
git clone https://github.com/oshikaidesu/motolii.git
cd motolii
brew bundle
engine/build.sh
app/tool/live.sh
```

- `brew bundle` で、`Brewfile` の物（GStreamer・SQLite・ffmpeg・cmake など）が入ります。
- `engine/build.sh` がエンジンをビルドします。初回は Filament をソースから組みます（M4 で約 5 分）。`engine/out/libmotolii.dylib` ができれば成功です。
- `app/tool/live.sh` でアプリが開きます。初回はビルドで 1〜3 分止まって見えます。

プロジェクトファイルは `~/Movies/Motolii/Untitled.motolii`（自動で保存）、書き出した動画もその隣にできます。

テストを走らせるには：エンジンは `engine/build.sh test`（CMake の ctest）、アプリは `cd app && flutter test`。詳しくは [Testing](docs/TESTING.md)。

手順の詳しい説明、最初の 1 本、困った時の直し方は[ガイドの「使ってみる」](docs/using/guide.ja.md#使ってみる)にあります。

## 何が動く

コードを貼る（⌘V）かファイルを落とす。言語は自動で判定されます。

| 世界 | 入れ方 | 動かすエンジン |
|---|---|---|
| **Shadertoy** | ⌘V | ISF → WGSL（glslang + Tint） |
| **GLSL Sandbox** | ⌘V | 同上 |
| **twigl** | ⌘V | 同上 |
| **Bonzomatic** | ⌘V | 同上 |
| **ISF (.fs)** | `effects/` に置く | glslang → SPIR-V → WGSL |
| **WGSL (.wgsl)** | `effects/` に置く | そのまま |
| **p5.js / Processing** | ⌘V | QuickJS-ng |
| **Paper.js** | ⌘V | QuickJS-ng |
| **Two.js** | ⌘V | QuickJS-ng |
| **Canvas 2D** | ⌘V | QuickJS-ng |
| **Dwitter** | ⌘V | QuickJS-ng |
| **tixy.land** | ⌘V | QuickJS-ng |
| **Turtletoy** | ⌘V | QuickJS-ng |
| **Hydra** | ⌘V | QuickJS-ng → WGSL |
| **After Effects の式** | ⌘V or 式カード | lottie-web（QuickJS-ng） |
| **Cavalry のスクリプト** | 式カード | QuickJS-ng |
| **CSS @keyframes** | テキストレイヤーで ⌘V | Stylo（Firefox の CSS エンジン） |
| **アニメーション SVG** | ⌘V or D&D | ThorVG + Stylo |
| **three.js TSL** | ⌘V | WGSLNodeBuilder（QuickJS-ng） |
| **AviUtl2 (.anm2, .obj2)** | `aviutl_scripts/` に置く | LuaJIT |
| **Lottie (.json)** | D&D | ThorVG |
| **字幕 (ASS/SRT/LRC/VTT)** | D&D | libass（FFmpeg 経由） |

対応形式のコードでも、すべてが正しく動作するわけではありません。数と詳細は[仕様](docs/using/specifications.ja.md#対応形式と動作状況)にあります。

ファイルの種類ごとの置き場所は [`shelves/README.ja.md`](shelves/README.ja.md) にあります。

## フォルダの並び

| 場所 | 中身 |
|---|---|
| [`app/`](app/README.md) | Flutter のアプリ。画面は操作だけを受けます |
| [`engine/`](engine/README.md) | C++ のエンジン。絵を描き、`libmotolii.dylib` になります |
| [`shelves/`](shelves/README.ja.md) | アプリが動く時に読む、同梱のコミュニティの作品（エフェクト・スクリプト・イージング・スキン） |
| [`docs/`](docs/README.md) | 文書 |

`app/README.md` と `engine/README.md` は英語です。

## 文書

- [Motolii の特長](docs/using/highlights.ja.md)：いま他では手に入れにくいことと、それぞれの限界。
- [仕様](docs/using/specifications.ja.md)：必要な環境、動く形式と数えた結果、書き出せる形式、速さ。
- [ガイド](docs/using/guide.ja.md)：Motolii でできる事、ビルドの手順、最初の 1 本、他のソフトとの違い。
- [タブの紹介](docs/using/screen_tour.ja.md)：画面のタブごとの絵と使い方。
- [作り](docs/ARCHITECTURE.md)：全体の作り：アプリ・エンジン・描画・動画のつながり（英語）。
- [テスト](docs/TESTING.md)：テストの種類ごとの回し方（英語）。
- [関わり方](.github/CONTRIBUTING.ja.md)：ビルド、決まり、手を付けやすい所。

## 開発に加わる

質問・相談は [Discussions](https://github.com/oshikaidesu/motolii/discussions)、不具合は [Issues](https://github.com/oshikaidesu/motolii/issues) へ。日本語・英語のどちらでも。Pull Request も受けます：[`.github/CONTRIBUTING.ja.md`](.github/CONTRIBUTING.ja.md)、行動規範（[`.github/CODE_OF_CONDUCT.md`](.github/CODE_OF_CONDUCT.md)）、脆弱性の知らせ方（[`.github/SECURITY.md`](.github/SECURITY.md)）を見てください。

## ライセンス

Motolii 自身の物は [Apache License 2.0](LICENSE-APACHE) と [MIT](LICENSE-MIT) のどちらでも、使う人が選べます（ダブルライセンス）。送ってもらった貢献も、特に断りが無ければ同じ二つのライセンスで受けます。同梱した他の人の作品は、それぞれのライセンスに従います（[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)）。
