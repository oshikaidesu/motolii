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
| `skins/` | 同梱のスキン（`theme.xml` と部品の絵。名前は `skins/PARTS.md`） |
| `test/`、`external_test/` | 試験。`external_test/` は実機の窓を動かして測る |
| `tool/flicker.py` | 画面の録画から、ちらついたコマを探す |

見た目の決まりは [`DESIGN.md`](DESIGN.md)。
