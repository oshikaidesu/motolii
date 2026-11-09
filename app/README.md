# app — Motolii の窓

Flutter の窓。描くのも書類を持つのも本体（[`../engine/`](../engine/)）で、窓はそれを呼んで見せて操るだけ。開くのは `./live.sh`（保存すると開いた窓にすぐ出る）、組むのは `flutter build macos --profile`。

| 場所 | 中身 |
|---|---|
| `lib/main.dart` | 起動したら窓を開く |
| `lib/engine/` | 本体（`libmotolii.dylib`）を呼ぶ口：書類、棚、問い合わせ、書き込み |
| `lib/workspace/` | 窓そのもの。`dock/` 左の棚、`stage/` 舞台、`timeline/` タイムライン、`desk/` 下の机、`shelf/` 棚のタイル（地図は [`lib/workspace/README.md`](lib/workspace/README.md)） |
| `lib/inspector/` | 右の Inspector。`controls/` つまみ、`effects/` 効果のカード、`rows/` 行、`transform/` 位置と回転 |
| `lib/parts/` | 席をまたいで使う部品 |
| `lib/forms/` | 窓の形（スキン）ごとの並べ方 |
| `lib/style/` | 色と寸法 |
| `skins/` | 見本のスキン。`~/.motolii/skins/` に写して View › Skin で着る（作り方は [`skins/README.md`](skins/README.md)、部品の名前は `skins/PARTS.md`） |
| `test/` | ウィジェットの試験（`flutter test`）。`accessibility_guidelines_test.dart`：本物の窓が Flutter のアクセシビリティの指針を満たすか |
| `integration_test/`、`test_driver/` | 実機の Mac の窓で動かす試験（`flutter drive`）。`frame_timing_test.dart`：タイムラインを回して 1 コマ 16 ms に収まるか |
| `build/test_output/` | 試験が書く物（タイムライン、ドライバーの記録）。`build/` の残りは Flutter の作業場 |
| `live.sh` | 窓を開き、`lib/` の .dart を保存するたびホットリロードを送る（`flutter run` ＋ SIGUSR1）。開く書類は `MOTOLII_DOC` |
| `tool/flicker.py` | 手で使う道具。画面の録画（`--record 5 rec.mov`）から、前後と違う 1 コマ（ちらつき）を探して png に書く。要 ffmpeg |

見本のスキン：

| スキン | 見た目 |
|---|---|
| `labs` | 白地に黒文字、丸いピル、淡い印。灰色を 1 段ずつ書き、印の絵も差し替えた作り込みの見本 |
| `lighttable` | 光るライトテーブルの上のフィルム。乳白の地、黒い帯、グリースペンシルの橙は触る所だけ |
| `paper` | 3 色と角 0 だけの、いちばん短い見本 |
| `poster` | スイスの幾何学ポスター。平たい赤・黄・青・緑・桃、太いグロテスク体 |
| `sheet` | 紙 1 枚の地と墨の線。赤は今いる所（モード・キー）だけ |
| `streets` | 黒い箱・白文字・お金の緑・角は四角。Render ボタンとカードに専用の枠（`parts/frame.*.svg`） |

試験の走らせ方（どちらも `app/` で）：

```bash
flutter test --no-pub test/
```

```bash
FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
```

見た目の決まりは [`DESIGN.md`](DESIGN.md)。
