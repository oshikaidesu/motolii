# 仕様

[English](specifications.md)

Motolii が何を動かし、何を必要とするか：動作環境、読み込める形式と数えた結果、書き出せる形式、速さ。何ができるかは [Motolii の特長](highlights.ja.md)と[ガイド](guide.ja.md)にあります。

## 動作環境

現在は開発途中で、Apple Silicon 搭載 Mac に対応しています。

配布用アプリはまだ用意していないため、試す場合はソースコードからビルドする必要があります。

Windows 版も作る予定です。Filament、ThorVG、GStreamer、Flutter など主な部品は Windows に対応しており、Mac に直接つないでいるのは動画と画面の受け渡しなど一部だけです。Windows でのビルドと動作確認はまだしていません。

対応形式ごとの動作状況、既知の不具合、ビルド手順については以下に記載しています。

## 対応形式と動作状況

| 形式 | 確認した結果 |
|---|---|
| ISF | 327 本中 318 本 |
| Shadertoy | 300 本中 261 本で絵が出て動いた |
| p5.js | 168 作中 97 作で絵が出た |
| AviUtl2 | 594 本中 372 本が最後まで動いた |

※ 検証時点・条件はそれぞれ異なります。p5.js は表示できても元作品と見た目が一致するとは限りません。詳しい条件と制限は[検証記録](../design/sketch_import_test_record.md)に記載します。

### 形式ごとの詳しい様子

| できる事 | 使う形式 | いまの様子 |
|---|---|---|
| VJ ソフト向けに配られているエフェクトをかける | ISF（`.fs`。[ISF-Files](https://github.com/Vidvox/ISF-Files) など） | エフェクトのフォルダに置くと一覧に出ます。ISF-Files の 327 本中 318 本が動きます（数えた検査は、消しました）。同梱 419 本 |
| WebGPU のシェーダーをかける | WGSL（`.wgsl`。three.js などの画面効果を移した物を含む） | シーン全体にかかります。同梱 266 本 |
| p5.js のスケッチを貼る | p5.js（コードをコピーして、アプリで ⌘V） | レイヤーになり、Program タブに残ります。キーフレームを打てて、Time Remap で時間の速さも変えられます。OpenProcessing の 168 作中 97 作で絵が出ました（11/1 の数え。元と見た目が一致したのは、最初の 42 作を目で見て約 16 作） |
| Shadertoy のシェーダーを貼る | GLSL（コードをコピーして、アプリで ⌘V） | 自分で描く作品はレイヤーになり、`iChannel` を読む作品は選んだレイヤーにかかります。どちらも Program タブに残ります。API の写し 36,668 本から無作為に選んだ 300 本中 261 本で絵が出て動きました（2026-11 初めの数え）。黒かった 30 本のうち 26 本はマウスなどの入力待ち。読み込めなかったのが 9 本。Time Remap はまだ p5.js だけです |
| AviUtl2（日本の動画編集ソフト）のスクリプトを使う | `.anm2`・`.obj2`（中の HLSL を WGSL に変換） | 同梱 172 パッケージ。10/26 の数えで、当時同梱の 594 本中 372 本が最後まで動きました（[`docs/design/aviutl2_catalogue.md`](../design/aviutl2_catalogue.md)）。DLL が要る物はまだ動きません |
| ネットの TSL（three.js のシェーダー言語）の表現を使う | three.js 自身の変換器で WGSL に | [Shader Lab](https://github.com/basementstudio/shader-lab) の 19 本はエフェクト一覧にあります。ほかは WGSL への変換まで |
| 動画・写真・文字・図形・3D モデル・点群を置く | 動画（GStreamer）、文字と図形（ThorVG）、glTF・`.ply`（Filament） | 動きます |
| After Effects のアニメーションを置く | Lottie の `.json`（ThorVG） | 動きます |
| MIDI をアニメーションに使う | MIDI（`.mid`）：ピアノロール、音に合わせて値にキーフレーム | 動きます。MIDI の音はまだ鳴りません（動画の音は鳴ります） |
| 図形を作る・出入りの動きを付ける | 自分のスクリプト（`.js`） | 置くと一覧に出ます。同梱のレシピ（動く作例）101 本、出入りの動き 13 本 |
| 複数のレイヤーをまとめて動かす（並べる・追う・群れ・ばね・ぶつかり合い） | 関係のスクリプト（`.js`） | `relations/` に置くと Relations タブに出ます。同梱 9 本と、組み込み 5 つ |

作品の権利は作者のものです。Shadertoy や OpenProcessing の作品には非営利の条件が付いた物が多いので、仕事に使う時は作者に確かめてください。

ほかに：キーフレームとイージング（anime.js のイージングもそのまま使えます）、物理演算（Jolt）、ガラスの屈折、カメラ（焦点距離・絞り・ピント）、MP4 への書き出し。

**ビルドの確認**：GitHub の Apple Silicon の Mac（macos-15）で、このガイドの手順どおりに新しくビルドし、画面のコードの検査（`flutter analyze`）を走らせています（[README](../../README.ja.md) の build バッジ）。アプリのテストと、整形・解析の確かめは push のたびに走ります（checks バッジ）。手元での走らせ方は [`docs/TESTING.md`](../TESTING.md)。

**速さ**（M4、上の 8 秒の作例、1080×1920）：1 フレーム約 4 ms で、毎秒 240 フレームでも落ちません。8 秒の書き出しは約 5 秒（ffmpeg のエンコードを含む）。測り直すには、作例を作ってから `printf 'time 240\n' | engine/edit.sh ~/Movies/Motolii/mv.motolii`。

## 書き出し

| 出力 | 形式 | いまの様子 |
|---|---|---|
| 動画 | MP4（H.264 + AAC） | エンコーダーは、そのシステムの FFmpeg が挙げる物のうち、Apple、NVIDIA、Intel、AMD、Windows Media Foundation、VA-API、OpenH264、x264 の順で最初の 1 つです。Mac では Apple の物で、1080×1920・480 フレームの作例は以前と同じに書き出せます。画質を測った（VMAF）のは Apple の物と x264 だけで、ほかはビットレートを決めただけで、動かしていません。H.264 のエンコーダーが 1 つも無いときは、メッセージを出して書き出しを止めます |
| 透明つきの動画 | `.mov`（ProRes 4444） | 他の編集ソフトが読めるので選びました。同じシーン（文字 480 フレーム）の PNG 連番と比べて、色は 84.4 dB、透明は 71.5 dB で一致します。ファイルは大きく、そのシーンで 64.5 MB です（以前の HEVC＋透明の約 85 倍）。QuickTime・Final Cut・Premiere・Resolve で開く確認はまだです |
| 透明なしの動画 | `.mov`（HEVC） | Apple のエンコーダーだけなので、Mac のみです |

## 頼っている部品

- **FFmpeg**：LGPL だけのビルド（x264 なし）。`engine/tools/bundle_ffmpeg.sh` で、どのフォルダからでも動く 21 MB のフォルダにできます。ライセンスの文と、ソースの URL・SHA-256 を横に置きます。Finder から開いても見つけ、About パネルに FFmpeg の表示が出ます。
- **ONNX Runtime 1.31.1**（MIT）：Microsoft 自身の配布物を、SHA-256 を確かめて使います。エフェクトの地図を描くのに使います。エンジンが Homebrew から引くライブラリは、113 から 22 に減りました。
- **まだ配れない理由**：エンジンは Homebrew の GStreamer・SQLite・LuaJIT などをまだ読み込むので、ビルドは作った Mac でしか動きません。Developer ID の署名と公証は、持ち主の Apple の証明書が要るので、していません。
- **Windows と Linux**：各部品が使う人にどう届くかは、各プロジェクトの文書をもとに [`docs/engine/PACKAGING.md`](../engine/PACKAGING.md) に書きました。この 2 つの上では何も動かしていません。
