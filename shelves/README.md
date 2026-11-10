# shelves/ — 見つけた表現を置く所

[English](README.en.md)

Motolii に最初から入っている表現です。フォルダの名前は、アプリの画面に出る名前と同じです。見つけたファイルは、出したい場所の名前のフォルダに置きます。

置くのは利用者のフォルダの中です（Mac は `~/Library/Application Support/Motolii/`、Windows は `%APPDATA%\Motolii\`、`MOTOLII_OWN` で変更可）。そこに下と同じ名前のフォルダを作ってファイルを置くと、再起動なしで同じ所に並びます。同じ名前のファイルなら、利用者の物が勝ちます。

| フォルダ | アプリのどこに出るか | 置くファイル | 出る名前 |
|---|---|---|---|
| `effects/` | Effects タブのタイル（レイヤーの効果・画面全体の効果） | `.fs`（ISF）・`.wgsl`・`.js`（three.js）・`.mjs`・`.json`（Filament の設定） | 1 行目の `// 名前:`、無ければファイル名。`.fs` はファイル名そのまま |
| `aviutl_scripts/` | Effects タブのタイル。パッケージ名がチップになる | AviUtl2 のパッケージ（`.anm2`・`.obj2`・`@` ファイル）をフォルダごと、手を入れずに | スクリプトの名前と `--label:`。パッケージ名はフォルダの `__` の後ろ |
| `create/` | Create タブの Recipes（1 回で絵を作る）。`function each` のある物は Expression に、`--label:Cavalry` など閉じたパックは Program タブに出る | `.js` | 1 行目の `// 名前: 何を作るか`。頭の無い p5 のスケッチはファイル名 |
| `expressions/` | Create タブの Expression（文字やレイヤーの出入りの動き、コピーを順に揺らす波。Cavalry の Animators と oscillator） | `.js`（`function each`） | 1 行目の `// 名前:` |
| `relations/` | プレビューの上と Relations タブのチップ（たくさんのレイヤーを一度に動かす） | `.js` | 1 行目の `// 名前:`、無ければファイル名 |
| `looks/` | Effects タブのルックのタイル（レイヤーの値・効果・キーを名前で取っておいた物） | `.motolii` ＋ タイルの絵 `.png` | ファイル名そのまま（空白も大文字も） |
| `solids/` | レイヤーの効果カードの 3D の形（Alight Motion の Box・Torus など）。タイルはまだ無く、プロジェクトが名指した時に出る | `.js`（three.js の BufferGeometry を返す `export function solid`） | 1 行目の `// 名前:` |
| `ease/` | 下の Ease のタイル（キーとキーの間の動き方） | `.way`（式 1 行） | 1 行目の `// 名前:`、無ければファイル名 |
| `skins/` | View › Skin の一覧（アプリの見た目の着せ替え） | フォルダごと（`theme.xml` と、あれば絵・書体）。作り方は [`skins/README.md`](skins/README.md) | フォルダ名 |
| `extensions/` | 項目としては出ない。Hydra のコードを貼る前に 1 回だけ使う | `hydra/get.sh` | — |

前の名前（`recipes/`・`animators/`・`ways/`）のフォルダに置いた物も、そのまま読みます。

## 下のフォルダ

`effects/` と `create/` は、下のフォルダまで全部読みます。下のフォルダの名前は画面に出ず、置く人が場所を選ぶための物です。書類は効果やレシピをファイル名で探し直すので、下のフォルダを替えても書類は壊れません。

`effects/` の下は、After Effects の Effects & Presets の分類の名前に合わせています（[Adobe の効果の一覧](https://helpx.adobe.com/after-effects/desktop/apply-effects-and-animation-presets/effects-and-animation-presets/effect-list.html)）。AE に無い物は、なぜ別にしたかを書きます。

| フォルダ | AE の分類 | 置く物 |
|---|---|---|
| `blur/` | Blur & Sharpen | ぼかし・シャープ |
| `color/` | Color Correction | 色・明るさの補正 |
| `distort/` | Distort | 絵を歪める |
| `generate/` | Generate | 絵を作る（波形・模様・切り抜きの形） |
| `stylize/` | Stylize | 絵の見た目を変える（網点・光・縁） |
| `transition/` | Transition | 2 つの絵の切り替え |
| `key/` | Keying と Matte | 色や明るさで抜く・マスク |
| `utility/` | Utility | 見た目より道具の物（アルファ・カラーバー・時刻・タイムコード） |
| `move/` | 無い | 物そのものを時間で動かす（揺れ・繰り返し・回転）。AE では効果でなく式（`wiggle()`・`loopOut()`）でやる事なので、AE の分類に入る先が無い |
| `geometry/` | 無い | 形と 3D の立体・裏返し・回転。AE では Perspective と Generate に分かれる。名前は、ここにある ISF の効果自身が `CATEGORIES` に書く `Geometry Adjustment` から |
| `glitch/` | 無い | 壊れた映像の見た目（データモッシュ・VHS・RGB のずれ）。AE では Stylize と Time に散る。名前は、ここにある ISF の効果自身が `CATEGORIES` に書く `Glitch` から |
| `sources/` | 分類ではない | 効果の出どころ：各パックのライセンス、取り込んだ脚本、タイルを描く見本の写真、AviUtl の効果の対応表。棚の 257 本の効果の頭の出典の行がこの場所を出典として名指すので、名前は替えない |

`create/` の下は、利用者が手にする物の名前です。

| フォルダ | 置く物 |
|---|---|
| `shapes/` | 1 つの形（矢印・ハート・吹き出し…。AbsentMotion の形） |
| `cavalry/` | 点を曲線や立体に並べる配置（Canvalry の Distribution をそのまま） |
| `repeats/` | 1 つの物を何個も並べて、順に動かす模様（AE の Repeater、Cavalry の Duplicator） |
| `over_footage/` | 映像の上に重ねる物（動く物を追う枠・白いフラッシュ・ポスター） |

## 空に見えるフォルダ

- `extensions/hydra/` は `get.sh` しかありません。Hydra（hydra-synth）は AGPL-3.0 なので、このリポジトリにも配る物にも入れません。`get.sh` を走らせると利用者のフォルダの `extensions/hydra/` に取って来て、Motolii はそちらを読みます。消せば元のままです。Hydra のコードを貼る人が取りに来る物なので、ここに置いています。
- `ease/` は見本 1 つ（`snappy.way`）です。プリセットは利用者の持ち物なので、利用者のフォルダの `ease/` に置く物が本体です。

## 名前の決まり

ファイル名を直す前に、上の「出る名前」を見てください。書類は置いた物をファイル名で探すので、一度配ったファイルの名前は、出ない物でも替えません（`create/repeats/ae_grid.js` の `ae_` もそのまま）。

- 1 行目に `// 名前:` がある物（`effects/` の `.js`・`.wgsl`、`create/`、`expressions/`、`relations/`、`solids/`、`ease/`）：ファイル名は出ないので、形は問いません。今あるのは出どころの名前のままです（`solids/` は Alight Motion の名前の空白を `_` にした物、`create/shapes/am_*` は AbsentMotion の形）。
- ファイル名がそのまま出る物（`looks/`、`effects/` の `.fs`、頭の無い p5 のスケッチ `create/repeats/Cube Wave.js` など、`// 名前:` の無い `relations/`）：空白も大文字もそのまま書きます。ISF の `.fs` は配られた時の名前のままです。
- `aviutl_scripts/`：`<作者>__<パッケージ>/` で、AviUtl2 のカタログの作者名とパッケージ名です。中は配られた形のまま、`LICENSE` と `SOURCE.txt` を添えます。
- ここに置くのは 1 つで 1 項目になる物だけです。何かの部品（例：押し出した形の UV を作る `face_uv.js`）は、それを動かすコードの隣（`engine/community/three/`：棚の `solids/` を動かす `solid_three.cpp` の隣）に置きます。`face_uv.js` は Motolii が書いた部品で、持ち込んだ表現ではないので、棚ではなく `engine/` に置きます（AGENTS.md 構成の目標 3）。

## ここに無い物

- 字が足りない時の代わりの書体（Noto Sans JP）と Fonts タブの見本の文、Effects の検索で日本語を英語に引く表（日本語 WordNet）は、置いて増やす物ではなく中身が読むデータなので、ライセンスと一緒に `engine/third_party/` にあります。利用者のフォルダの `fonts/`・`words/` に置いた物は足されます。
- どのフォルダをどのコードが読むかは [`docs/ARCHITECTURE.md` の「棚を読む所」](../docs/ARCHITECTURE.md#棚を読む所)。
- 中身を作る脚本（`effects/sources/`・`create/shapes/absent_shapes.sh`）は手で走らせる物で、組み立ては呼びません。
