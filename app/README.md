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
| `skins/` | 同梱のスキン（`theme.xml` と部品の絵。書き方は [`docs/app/skins/`](../docs/app/skins/README.md)） |
| `test/`、`external_test/` | 試験。`external_test/` は実機の窓を動かして測る |
| `tool/flicker.py` | 画面の録画から、ちらついたコマを探す |

## 長い文書（[`docs/app/`](../docs/app/)）

| 文書 | 中身 |
|---|---|
| [`BRIDGE.md`](../docs/app/BRIDGE.md) | 窓と中身の境目の決まり（窓が中身を呼ぶ所） |
| [`DESIGN.md`](../docs/app/DESIGN.md) | 見た目の決まり（値に出所の印つき。`lib/style/tokens.dart` の値はここから） |
| [`skins/README.md`](../docs/app/skins/README.md) | スキンの作り方。名前の一覧は [`ROLES.md`](../docs/app/skins/ROLES.md)（色・形）と [`PARTS.md`](../docs/app/skins/PARTS.md)（絵）、続きを作る人向けは [`HANDOFF.md`](../docs/app/skins/HANDOFF.md) |

## 作り方の決まり
- 新しく作る前に、リポジトリとネットで既存を探す。見つからない時だけ作る。
- 値は `lib/style/tokens.dart`（`DESIGN.md` から）。部品は数値を直書きしない。
