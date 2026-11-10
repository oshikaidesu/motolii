# app — Motolii のアプリ

*Motolii's app (Flutter, macOS). It draws nothing and holds no project: it calls the engine (`../engine/`) and shows what comes back. Open it with `tool/live.sh`; build it with `flutter build macos --profile`. The table below names every folder, down into `lib/`.*

Flutter で書いたアプリ。描くのもプロジェクトを持つのもエンジン（[`../engine/`](../engine/)）で、アプリはそれを呼んで見せて操るだけ。開くのは `tool/live.sh`（保存すると開いたアプリにすぐ出る）、組むのは `flutter build macos --profile`。

| 場所 | 中身 |
|---|---|
| `lib/main.dart` | 起動したらアプリのウィンドウを開く |
| `lib/bridge/` | アプリとエンジンの境目（[`docs/app/BRIDGE.md`](../docs/app/BRIDGE.md)）。エンジン（`libmotolii.dylib`）を呼ぶ口：プロジェクト、棚、問い合わせ、書き込み |
| `lib/workspace/` | アプリの画面そのもの。`state/` 画面の状態、`window/` ウィンドウの枠、`top_bar/` 上のバー、`commands/` キーとメニュー、`edits/` まとめて掛ける編集、`inspector_feed/` Inspector へ渡す物、`dock/` 左の棚、`stage/` プレビュー、`timeline/` タイムライン、`tool_panel/` 下のツールパネル、`shelf/` 棚のタイル（地図は [`lib/workspace/README.md`](lib/workspace/README.md)） |
| `lib/inspector/` | 右の Inspector。カードは全部エンジンの宣言（`engine/document/card_table.h` → `lib/workspace/inspector_feed/` の cards が WGSL の構造体に）で、効果もそれ以外も `inspector_card.dart` の `ValuesCard` 1 つが描く。カードごとの Dart は置かない。`controls/` 値の種類ごとの操作部品（数・角度・色・文字・リンク）、`rows/` 行とカードの枠 |
| `lib/widgets/` | **規格**：パネルを組む部品。仕組み 1 つにつき部品 1 つで、ここを直せば全パネルが直る。押し・アイコンボタン・バッジ・チップ（`controls.dart`：`Hov`・`IconPress`・`Badge`・`Chip`）、数の欄（`number_field.dart`：`NumberField`）、打ち込む欄（`text_gestures.dart`：`TypedField`）、スライダーと関数で描く絵（`media.dart`：`MiniSlider`・`glyph`）、名前の印（`glyphs.dart`：`Glyph`）、トラックパッドの 2 本指（`two_fingers.dart`）、タイムラインの印（`timeline_painters.dart`）。押し・認識・手描きを自前で書いてよいのはここだけ（`.githooks/rules/`） |
| `lib/panel.dart` | 規格の入口。`import 'package:motolii/panel.dart';` の 1 行で、規格の部品・見た目の値（`skin/tokens.dart`）・画面の状態（`Ws`）・エンジンの読み書き（`bridge/`）・タブ（`WsPane`）・エンジンが宣言したカード（`LayerCards`）が全部手に入る |
| `example/` | 見本（pub の置き場）。`my_panel.dart`：規格だけで組んだ自作のパネル。`dart analyze` が一緒に確かめるので、規格を変えて見本が組めなくなれば赤になる |
| `lib/skin/` | 見た目：既定の値と、着ているスキンが差し替える物。`tokens.dart` 色の段と寸法（`docs/app/DESIGN.md` から）、`theme.dart` スキンの theme.xml の色、`svg_parts.dart` スキンの `parts/*.svg`（theme.xml の `<Parts>`）、`forms/` 部品の組み立て方（theme.xml の `<Forms Value="poster"/>` が `poster_forms.dart` を選ぶ。名前の無いスキンは `own_forms.dart`、どのフォームも書かなかった部品は `base_controls.dart`） |
| `assets/` | アプリが読むデータ。`effect_parameter_weights.json`：効果のパラメーターごとの効き（Effects 棚のタイルが読む）。pubspec の `assets:` には載せない：棚と同じく repo の中から `File` で同期に読む（`lib/workspace/shelf/effect_tiles.dart` の `_entry`） |
| `test/` | ウィジェットの試験（`flutter test`）。`accessibility_guidelines_test.dart`：本物のアプリの画面が Flutter のアクセシビリティの指針を満たすか |
| `integration_test/`、`test_driver/` | 実機の Mac でアプリを動かす試験（`flutter drive`）。`frame_timing_test.dart`：タイムラインを回して 1 コマ 16 ms に収まるか |
| `build/test_output/` | 試験が書く物（タイムライン、ドライバーの記録）。`build/` の残りは Flutter の作業場 |
| `tool/live.sh` | アプリを開き、`lib/` の .dart を保存するたびホットリロードを送る（`flutter run` ＋ SIGUSR1）。開くプロジェクトは `MOTOLII_DOC` |
| `tool/flicker.py` | 手で使う道具。画面の録画（`--record 5 rec.mov`）から、前後と違う 1 コマ（ちらつき）を探して png に書く。要 ffmpeg |

## 自作のパネルを作る

1. Dart のファイルを 1 枚書く。`import 'package:flutter/widgets.dart';` と `import 'package:motolii/panel.dart';` の 2 行だけで足りる（見本：[`example/my_panel.dart`](example/my_panel.dart)）。
2. 値を並べるだけなら Dart は要らない：`LayerCards(layer: ..., only: ['Transform'])` が、エンジンの宣言（`engine/document/card_table.h`）どおりのカードを出す。自前の絵や操作を持つ所だけ、規格の部品（`NumberField`・`MiniSlider`・`Chip`・`IconPress`・`Glyph` …）で書く。
3. `lib/main.dart` の `Workspace` に 1 行足す：`Workspace(document: motoliiDoc, extra: const [WsPane('Mine', null, MyPanel.new)])`。印は `null` なら頭文字、`GlyphKind` を渡せば自前の印（スキンに同じ名前の SVG があればそれが勝つ）。
4. パネルの中で、押し（`GestureDetector`・`NakedButton` …）・打ち込み欄（`EditableText`）・手描き（`CustomPainter`）を自分で書くと、コミットで断られる（[`.githooks/README.md`](../.githooks/README.md) の shape_check）。足りない部品は規格（`lib/widgets/`）に足す：そうすれば全パネルが同じ物を使える。


見本のスキンは [`../shelves/skins/`](../shelves/skins/)（作り方も同じ所）。アプリの側で、theme.xml の色・寸法は `lib/skin/theme.dart`、`<Parts>` の絵は `lib/skin/svg_parts.dart`、`<Forms>` の組み立て方は `lib/skin/forms/<名前>_forms.dart` が読む。

試験の走らせ方（どちらも `app/` で）：

```bash
flutter test --no-pub test/
```

```bash
FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
```

## 長い文書（[`docs/app/`](../docs/app/)）

| 文書 | 中身 |
|---|---|
| [`BRIDGE.md`](../docs/app/BRIDGE.md) | アプリとエンジンの境目の決まり（アプリがエンジンを呼ぶ所） |
| [`DESIGN.md`](../docs/app/DESIGN.md) | 見た目の決まり（値に出所の印つき。`lib/skin/tokens.dart` の値はここから） |
| [`skins/HANDOFF.md`](../docs/app/skins/HANDOFF.md) | スキンの続き（フォーム）を作る人向け。スキンの作り方は [`shelves/skins/README.md`](../shelves/skins/README.md) |

## 作り方の決まり
- 新しく作る前に、リポジトリとネットで既存を探す。見つからない時だけ作る。
- 値は `lib/skin/tokens.dart`（`DESIGN.md` から）。部品は数値を直書きしない。
