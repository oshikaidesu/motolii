# shelves/ — 見つけた表現を置く所

[English](README.en.md)

Motolii に最初から入っている表現です。フォルダの名前は、アプリの画面に出る名前と同じです。見つけたファイルは、出したい場所の名前のフォルダに置きます。

置くのは利用者のフォルダの中です（Mac は `~/Library/Application Support/Motolii/`、Windows は `%APPDATA%\Motolii\`、`MOTOLII_OWN` で変更可）。そこに下と同じ名前のフォルダを作ってファイルを置くと、再起動なしで同じ所に並びます。同じ名前のファイルなら、利用者の物が勝ちます。

| フォルダ | アプリのどこに出るか | 置くファイル | 出る名前 |
|---|---|---|---|
| `effects/` | Effects タブのタイル（レイヤーの効果・画面全体の効果） | `.fs`（ISF）・`.wgsl`・`.js`（three.js）・`.mjs`・`.json`（Filament の設定） | 1 行目の `// 名前:`、無ければファイル名。`.fs` はファイル名そのまま |
| `aviutl_scripts/` | Effects タブのタイル。パッケージ名がチップになる | AviUtl2 のパッケージ（`.anm2`・`.obj2`・`@` ファイル）をフォルダごと、手を入れずに | スクリプトの名前と `--label:`。パッケージ名はフォルダの `__` の後ろ |
| `create/` | Create タブの Recipes（1 回で絵を作る）。`function each` のある物は Expression に、`--label:Cavalry` など閉じたパックは Program タブに出る | `.js` | 1 行目の `// 名前: 何を作るか`。頭の無い p5 のスケッチはファイル名 |
| `expressions/` | Create タブの Expression（文字やレイヤーの出入りの動き。Cavalry の Animators） | `.js`（`function each`） | 1 行目の `// 名前:` |
| `relations/` | プレビューの上と Relations タブのチップ（たくさんのレイヤーを一度に動かす） | `.js` | 1 行目の `// 名前:`、無ければファイル名 |
| `looks/` | Effects タブのルックのタイル（レイヤーの値・効果・キーを名前で取っておいた物） | `.motolii` ＋ タイルの絵 `.png` | ファイル名そのまま（空白も大文字も） |
| `solids/` | レイヤーの効果カードの 3D の形（Alight Motion の Box・Torus など）。タイルはまだ無く、プロジェクトが名指した時に出る | `.js`（three.js の BufferGeometry を返す `export function solid`） | 1 行目の `// 名前:` |
| `ease/` | 下の Ease のタイル（キーとキーの間の動き方） | `.way`（式 1 行） | 1 行目の `// 名前:`、無ければファイル名 |
| `skins/` | View › Skin の一覧（アプリの見た目の着せ替え） | フォルダごと（`theme.xml` と、あれば絵・書体）。作り方は [`skins/README.md`](skins/README.md) | フォルダ名 |
| `extensions/` | 項目としては出ない。Hydra のコードを貼る前に 1 回だけ使う | `hydra/get.sh` | — |

前の名前（`recipes/`・`animators/`・`ways/`）のフォルダに置いた物も、そのまま読みます。

## 空に見えるフォルダ

- `extensions/hydra/` は `get.sh` しかありません。Hydra（hydra-synth）は AGPL-3.0 なので、このリポジトリにも配る物にも入れません。`get.sh` を走らせると利用者のフォルダの `extensions/hydra/` に取って来て、Motolii はそちらを読みます。消せば元のままです。Hydra のコードを貼る人が取りに来る物なので、ここに置いています。
- `ease/` は見本 1 つ（`snappy.way`）です。プリセットは利用者の持ち物なので、利用者のフォルダの `ease/` に置く物が本体です。

## 名前の決まり

ファイル名を直す前に、上の「出る名前」を見てください。

- 1 行目に `// 名前:` がある物（`effects/` の `.js`・`.wgsl`、`create/`、`expressions/`、`relations/`、`solids/`、`ease/`）：ファイル名は出ないので、形は問いません。今あるのは出どころの名前のままです（`solids/` は Alight Motion の名前の空白を `_` にした物、`create/shapes/am_*` は AbsentMotion の形）。
- ファイル名がそのまま出る物（`looks/`、`effects/` の `.fs`、頭の無い p5 のスケッチ `create/copies/Cube Wave.js` など、`// 名前:` の無い `relations/`）：空白も大文字もそのまま書きます。ISF の `.fs` は配られた時の名前のままです。
- `aviutl_scripts/`：`<作者>__<パッケージ>/` で、AviUtl2 のカタログの作者名とパッケージ名です。中は配られた形のまま、`LICENSE` と `SOURCE.txt` を添えます。
- ここに置くのは 1 つで 1 項目になる物だけです。何かの部品（例：押し出した形の UV を作る `face_uv.js`）は、それを動かすコードの隣（`engine/community/js/`）に置きます。

## ここに無い物

- 字が足りない時の代わりの書体（Noto Sans JP）と Fonts タブの見本の文、Effects の検索で日本語を英語に引く表（日本語 WordNet）は、置いて増やす物ではなく中身が読むデータなので、ライセンスと一緒に `engine/third_party/` にあります。利用者のフォルダの `fonts/`・`words/` に置いた物は足されます。
- どのフォルダをどのコードが読むかは [`docs/ARCHITECTURE.md` の「棚を読む所」](../docs/ARCHITECTURE.md#棚を読む所)。
- 中身を作る脚本（`effects/sources/`・`create/shapes/absent_shapes.sh`）は手で走らせる物で、組み立ては呼びません。
