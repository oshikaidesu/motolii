# app — Motolii のアプリ

*Motolii's app (Flutter, macOS). It draws nothing and holds no project: it calls the engine (`../engine/`) and shows what comes back. Open it with `tool/live.sh`; build it with `flutter build macos --profile`. The table below names every folder, down into `lib/`. Which folder of `lib/` may import which is the second table (「import の向き」), checked by `tool/check_layers.py`.*

Flutter で書いたアプリ。描くのもプロジェクトを持つのもエンジン（[`../engine/`](../engine/)）で、アプリはそれを呼んで見せて操るだけ。開くのは `tool/live.sh`（保存すると開いたアプリにすぐ出る）、組むのは `flutter build macos --profile`。

| 場所 | 中身 |
|---|---|
| `lib/main.dart` | 起動したらアプリのウィンドウを開く |
| `lib/bridge/` | アプリとエンジンの境目（[`docs/app/BRIDGE.md`](../docs/app/BRIDGE.md)）。エンジン（`libmotolii.dylib`）を呼ぶ口：プロジェクト、棚、問い合わせ、書き込み |
| `lib/workspace/` | アプリの画面そのもの。`state/` 画面の状態、`window/` ウィンドウの枠、`top_bar/` 上のバー、`commands/` キーとメニュー、`edits/` まとめて掛ける編集、`inspector_feed/` Inspector へ渡す物、`dock/` 左の棚、`stage/` プレビュー、`timeline/` タイムライン、`tool_panel/` 下のツールパネル、`shelf/` 棚のタイル（地図は [`lib/workspace/README.md`](lib/workspace/README.md)） |
| `lib/inspector/` | 右の Inspector。カードは全部エンジンの宣言（`engine/document/card_table.h` → `lib/workspace/inspector_feed/` の cards が WGSL の構造体に）で、効果もそれ以外も `inspector_card.dart` の `ValuesCard` 1 つが描く。カードごとの Dart は置かない。`controls/` 値の種類ごとの操作部品（数・角度・色・文字・リンク）、`rows/` 行とカードの枠 |
| `lib/widgets/` | **規格**：パネルを組む部品。仕組み 1 つにつき部品 1 つで、ここを直せば全パネルが直る。押し・アイコンボタン・バッジ・チップ（`controls.dart`：`Pressable`・`IconPress`・`Badge`・`Chip`）、数の欄（`number_field.dart`：`NumberField`）、打ち込む欄（`text_gestures.dart`：`TypedField`）、スライダーと関数で描く絵（`media.dart`：`MiniSlider`・`glyph`）、名前の印（`glyphs.dart`：`Glyph`）、トラックパッドの 2 本指（`two_fingers.dart`）、タイムラインの印（`timeline_painters.dart`）。押し・認識・手描きを自前で書いてよいのはここだけ（`.githooks/rules/`） |
| `lib/panel.dart` | 規格の入口。`import 'package:motolii/panel.dart';` の 1 行で、規格の部品・見た目の値（`skin/tokens.dart`）・画面の状態（`WorkspaceController`）・エンジンの読み書き（`bridge/`）・タブ（`Pane`）・エンジンが宣言したカード（`LayerCards`）が全部手に入る |
| `example/` | 見本（pub の置き場）。`my_panel.dart`：規格だけで組んだ自作のパネル。`dart analyze` が一緒に確かめるので、規格を変えて見本が組めなくなれば赤になる |
| `lib/storage/` | アプリが手元に残す小さいファイル。`kept_file.dart` ファイルの書き込みと JSON・リストの読み込み、`window_settings.dart` `~/.motolii/window.xml`（倍率と着ているスキン）、`free_name.dart` 空いている名前（コピーに番号を付ける） |
| `lib/skin/` | 見た目：既定の値と、着ているスキンが差し替える物。`tokens.dart` 色の段と寸法（`docs/app/DESIGN.md` から）、`theme.dart` スキンの theme.xml の色、`skin_parts.dart` スキンの `parts/*.svg`（theme.xml の `<Parts>`）、`forms/` 部品の組み立て方（theme.xml の `<Forms Value="poster"/>` が `poster_forms.dart` を選ぶ。名前の無いスキンは `own_forms.dart`、どのフォームも書かなかった部品は `base_controls.dart`） |
| `assets/` | アプリが読むデータ。`effect_parameter_weights.json`：効果のパラメーターごとの効き（Effects 棚のタイルが読む）。pubspec の `assets:` には載せない：棚と同じく repo の中から `File` で同期に読む（`lib/workspace/shelf/effect_tiles.dart` の `_entry`） |
| `test/` | 試験（`flutter test`）。直下の 2 枚は本物の物を見る：`accessibility_guidelines_test.dart` は本物のアプリの画面が Flutter のアクセシビリティの指針を満たすか（エンジンが要る）、`skin_folders_test.dart` は棚のスキンが View › Skin に並ぶか。`inspector/`・`skin/`・`widgets/`・`workspace/` は `lib/` と同じ並びで、エンジンの要らない関数と状態（Inspector の `Doc`、画面の `WorkspaceController`）が今返す値を留める：コードを移したり分けたりして値が変わると落ちる |
| `integration_test/`、`test_driver/` | 実機の Mac でアプリを動かす試験（`flutter drive`）。`frame_timing_test.dart`：タイムラインを回して 1 コマ 16 ms に収まるか |
| `build/test_output/` | 試験が書く物（タイムライン、ドライバーの記録）。`build/` の残りは Flutter の作業場 |
| `tool/live.sh` | アプリを開き、`lib/` の .dart を保存するたびホットリロードを送る（`flutter run` ＋ SIGUSR1）。開くプロジェクトは `MOTOLII_DOC` |
| `tool/flicker.py` | 手で使う道具。画面の録画（`--record 5 rec.mov`）から、前後と違う 1 コマ（ちらつき）を探して png に書く。要 ffmpeg |
| `tool/check_layers.py` | `lib/` の import が、下の「import の向き」の表どおりかを確かめる（`python3 tool/check_layers.py`）。今まだ表を破っている import の帳簿が `tool/layer_debt.txt` |

## import の向き

`lib/` の中で、どのフォルダがどのフォルダを import してよいかの表。依存は一方向：画面のパネルから下へ、エンジンを呼ぶ口（`bridge/`）まで。下の物は上の物を知らない。

- 自分のフォルダの中は、いつも import してよい。
- `export` も import と同じに数える。
- 行はサブフォルダも含む。ただし `skin/` は `skin/forms/` を含まず、`workspace/` 直下の .dart はその下のフォルダを含まない（どちらも別の行）。

| フォルダ（`lib/` から） | import してよい物 |
|---|---|
| `bridge/` | 自前の物は何も |
| `storage/` | 自前の物は何も |
| `skin/`（`forms/` を除く） | `bridge/engine_paths.dart`、`storage/` |
| `widgets/` | `skin/` |
| `skin/forms/` | `skin/`、`widgets/` |
| `inspector/` | `skin/`、`skin/forms/`、`widgets/`。`bridge/` も `workspace/` も読まない |
| `workspace/easing/` | `bridge/` |
| `workspace/state/` | `bridge/`、`storage/`、`skin/`、`widgets/glyphs.dart`、`workspace/easing/` |
| `workspace/edits/` | `workspace/state/` と、それが import してよい物 |
| `workspace/commands/` | `workspace/edits/` と、それが import してよい物、`widgets/` |
| `workspace/shelf/` | `workspace/commands/` と、それが import してよい物、`skin/forms/`。`inspector/` は読まない |
| `workspace/inspector_feed/` | `workspace/shelf/` と、それが import してよい物、`inspector/` |
| `workspace/dock/`、`stage/`、`timeline/`、`tool_panel/`、`top_bar/`、`window/` | `workspace/inspector_feed/` と、それが import してよい物。この 6 つは互いを読まない |
| `workspace/` 直下の .dart（画面の全体） | 何でも |
| `panel.dart` | 何でも。書くのは `export` の行だけ |
| `main.dart` | `workspace/` 直下の .dart と `bridge/` |

どのフォルダにも掛かる決まりが 3 つ：`part` を使わない。`export` を書くのは `panel.dart` だけ。自前のファイルは `package:motolii/…` で import する。

表は向かう先で、今のコードはまだ途中にある。

- 表を破っている import は [`tool/layer_debt.txt`](tool/layer_debt.txt) に 1 行ずつ載っている。この帳簿は減るだけ。
- 2 つの決まりを破る物（`part`、`panel.dart` の外の `export`）もまだ残っている。`check_layers.py` はこの 2 つを測らない。相対の import は無くなり、`analysis_options.yaml` の `always_use_package_imports` が見張る。

確かめ方（`app/` で）：

```bash
python3 tool/check_layers.py            # 表と帳簿に照らす：帳簿に無い import と、もう無い import の行を言う
python3 tool/check_layers.py --write    # import を切った後に、帳簿を書き直す
```

`lib/` にフォルダを足したら、この表と `tool/check_layers.py` の `MAY_IMPORT` に 1 行ずつ足す（どの行にも入らないフォルダは断られる）。

## 自作のパネルを作る

1. Dart のファイルを 1 枚書く。`import 'package:flutter/widgets.dart';` と `import 'package:motolii/panel.dart';` の 2 行だけで足りる（見本：[`example/my_panel.dart`](example/my_panel.dart)）。
2. 値を並べるだけなら Dart は要らない：`LayerCards(layer: ..., only: ['Transform'])` が、エンジンの宣言（`engine/document/card_table.h`）どおりのカードを出す。自前の絵や操作を持つ所だけ、規格の部品（`NumberField`・`MiniSlider`・`Chip`・`IconPress`・`Glyph` …）で書く。
3. `lib/main.dart` の `Workspace` に 1 行足す：`Workspace(document: motoliiDoc, extra: const [Pane('Mine', null, MyPanel.new)])`。印は `null` なら頭文字、`GlyphKind` を渡せば自前の印（スキンに同じ名前の SVG があればそれが勝つ）。
4. パネルの中で、押し（`GestureDetector`・`NakedButton` …）・打ち込み欄（`EditableText`）・手描き（`CustomPainter`）は自分で書かない。足りない部品は規格（`lib/widgets/`）に足す：そうすれば全パネルが同じ物を使える。


見本のスキンは [`../shelves/skins/`](../shelves/skins/)（作り方も同じ所）。アプリの側で、theme.xml の色・寸法は `lib/skin/theme.dart`、`<Parts>` の絵は `lib/skin/skin_parts.dart`、`<Forms>` の組み立て方は `lib/skin/forms/<名前>_forms.dart` が読む。

試験の走らせ方（どれも `app/` で）：

```bash
flutter test --no-pub test/
```

```bash
flutter test --no-pub test/inspector test/skin test/widgets test/workspace   # エンジンの要らない試験だけ
```

```bash
FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
```

## 長い文書（[`docs/app/`](../docs/app/)）

| 文書 | 中身 |
|---|---|
| [`BRIDGE.md`](../docs/app/BRIDGE.md) | アプリとエンジンの境目の決まり（アプリがエンジンを呼ぶ所） |
| [`DESIGN.md`](../docs/app/DESIGN.md) | 見た目の決まり（値に出所の印つき。`lib/skin/tokens.dart` の値はここから） |
| [`GESTURES.md`](../docs/app/GESTURES.md) | 操作の決まり（押し・ドラッグ・キーが、同じ種類の部品のどこでも同じ意味と同じ数で働く。出所の印つき。数は `lib/widgets/gestures.dart` の `Gestures`、立っている例外は理由つき）。パネルを作る前に読む |
| [`skins/HANDOFF.md`](../docs/app/skins/HANDOFF.md) | スキンの続き（フォーム）を作る人向け。スキンの作り方は [`shelves/skins/README.md`](../shelves/skins/README.md) |

## 作り方の決まり
- 新しく作る前に、リポジトリとネットで既存を探す。見つからない時だけ作る。
- 値は `lib/skin/tokens.dart`（`DESIGN.md` から）。部品は数値を直書きしない。
