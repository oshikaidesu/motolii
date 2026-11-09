# app — Motolii の窓

Flutter の窓。描くのも書類を持つのも本体（[`../engine/`](../engine/)）で、窓はそれを呼んで見せて操るだけ。開くのは `./live.sh`（保存すると開いた窓にすぐ出る）、組むのは `flutter build macos --profile`。

コードの言葉（thing と layer、fact、picture、seat、kit…）を AE・Flutter の言葉に引き直す表は [`../docs/ARCHITECTURE.md` の「言葉」](../docs/ARCHITECTURE.md#言葉words)。

| 場所 | 中身 |
|---|---|
| `lib/main.dart` | 起動したら窓を開く |
| `lib/bridge/` | 窓と中身の境目（[`docs/app/BRIDGE.md`](../docs/app/BRIDGE.md)）。本体（`libmotolii.dylib`）を呼ぶ口：書類、棚、問い合わせ、書き込み |
| `lib/workspace/` | 窓そのもの。`dock/` 左の棚、`stage/` 舞台、`timeline/` タイムライン、`desk/` 下の机、`shelf/` 棚のタイル（地図は [`lib/workspace/README.md`](lib/workspace/README.md)） |
| `lib/inspector/` | 右の Inspector。`controls/` つまみ、`effects/` 効果のカード、`rows/` 行、`transform/` 位置と回転 |
| `lib/parts/` | 席をまたいで使う部品。`skin_parts.dart` はスキンの `parts/*.svg`（theme.xml の `<Parts>`）を窓の印の代わりに描く |
| `lib/forms/` | スキンの Dart の側：ボタン・札など部品 1 つずつの組み立て方。スキンの theme.xml が `<Forms Value="poster"/>` で選ぶ（`own.dart` が窓のいつもの形） |
| `lib/style/` | 色と寸法。`theme.dart` は着ているスキンの theme.xml から色を読み、`tokens.dart` の寸法は `docs/app/DESIGN.md` から |
| `test/` | ウィジェットの試験（`flutter test`）。`accessibility_guidelines_test.dart`：本物の窓が Flutter のアクセシビリティの指針を満たすか |
| `integration_test/`、`test_driver/` | 実機の Mac の窓で動かす試験（`flutter drive`）。`frame_timing_test.dart`：タイムラインを回して 1 コマ 16 ms に収まるか |
| `build/test_output/` | 試験が書く物（タイムライン、ドライバーの記録）。`build/` の残りは Flutter の作業場 |
| `live.sh` | 窓を開き、`lib/` の .dart を保存するたびホットリロードを送る（`flutter run` ＋ SIGUSR1）。開く書類は `MOTOLII_DOC` |
| `tool/flicker.py` | 手で使う道具。画面の録画（`--record 5 rec.mov`）から、前後と違う 1 コマ（ちらつき）を探して png に書く。要 ffmpeg |

見本のスキンは [`../shelves/skins/`](../shelves/skins/)（作り方も同じ所）。窓の側で、theme.xml の色・寸法は `lib/style/`、`<Parts>` の絵は `lib/parts/skin_parts.dart`、`<Forms>` の組み立て方は `lib/forms/<名前>.dart` が読む。

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
| [`BRIDGE.md`](../docs/app/BRIDGE.md) | 窓と中身の境目の決まり（窓が中身を呼ぶ所） |
| [`DESIGN.md`](../docs/app/DESIGN.md) | 見た目の決まり（値に出所の印つき。`lib/style/tokens.dart` の値はここから） |
| [`skins/HANDOFF.md`](../docs/app/skins/HANDOFF.md) | スキンの続き（フォーム）を作る人向け。スキンの作り方は [`shelves/skins/README.md`](../shelves/skins/README.md) |

## 作り方の決まり
- 新しく作る前に、リポジトリとネットで既存を探す。見つからない時だけ作る。
- 値は `lib/style/tokens.dart`（`DESIGN.md` から）。部品は数値を直書きしない。
