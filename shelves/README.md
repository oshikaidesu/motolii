# shelves/ — 同梱の表現の棚

[English](README.en.md)

Motolii に最初から入っている表現です。棚ごとにフォルダが 1 つあり、利用者のフォルダ（Mac は `~/Library/Application Support/Motolii/`、Windows は `%APPDATA%\Motolii\`、`MOTOLII_OWN` で変更可）に同じ名前のフォルダを作ってファイルを置くと、再起動なしで同じ棚に並びます。同じ名前のファイルは利用者の物が勝ちます（`engine/document/doc_folders.h` の `doc_folders`）。

| 棚 | アプリでの見え方 | ファイル | 表示名はどこから | 読む所 |
|---|---|---|---|---|
| `effects/` | Effects ドックのタイル（物の効果・画面全体の効果） | `.fs`（ISF）・`.wgsl`・`.js`（three.js）・`.mjs`・`.json`（Filament の設定） | 1 行目の `// 名前:`、無ければファイル名。`.fs` はファイル名そのまま | `doc_recipes.h` `doc_folder_names`、`effect_tiles.dart` |
| `aviutl_scripts/` | Effects ドックのタイル。パッケージ名がチップになる | AviUtl2 の `.anm2`・`.obj2`・`@` ファイル（パッケージを手を入れずに） | スクリプトの名前と `--label:`。パッケージ名はフォルダの `__` の後ろ | `doc_recipes.h` `doc_aviutl_names`、`effect_decks.dart` `effectPack` |
| `recipes/` | Make ドックの Create のタイル（1 回で絵を作る）。`--label:Cavalry` など閉じたパックは Program 棚 | `.js` | 1 行目の `// 名前: 何を作るか`。頭の無い p5 のスケッチはファイル名 | `doc_recipes.h` `doc_recipes_read`、`dock_make_expressions.dart` `_expressionRecipes` |
| `animators/` | Make ドックの Expression のタイル（文字や物の出入りの動き。Cavalry の Animators） | `.js` | 1 行目の `// 名前:` | `motolii_calls.h` `motolii_animators` |
| `relations/` | 舞台の上と関係タブのチップ（たくさんの物を一度に動かす関係） | `.js` | 1 行目の `// 名前:`、無ければファイル名 | `motolii_calls.h` `motolii_relations`、`relate.dart` |
| `looks/` | Effects ドックのルックのタイル（物の値・効果・キーを名前で取っておいた物） | `.motolii`（SQLite）＋ タイルの絵 `.png` | ファイル名そのまま（利用者が保存時に打った名前なので、空白も大文字もそのまま） | `doc_looks.h` `doc_look_names` |
| `solids/` | 物の効果カード（絵を貼る 3D の形。Alight Motion の Box・Torus など）。棚のタイルはまだ無く、書類の fx が名指した時に出る | `.js`（three.js の BufferGeometry を返す `export function solid`） | 1 行目の `// 名前:` | `solid_three.cpp`、`doc_moment_fx.h` |
| `ways/` | Ease の desk のタイル（区間の動き方のプリセット） | `.way`（式 1 行） | 1 行目の `// 名前:`、無ければファイル名 | `doc_recipes.h`（`doc_folders("ways")`）、`desk_ease_shelf.dart` |
| `words/` | 項目としては出ない。Effects ドックの検索欄に日本語で打つと、英語名の効果が出る（言葉の橋） | `ja_en.tsv`（日本語 WordNet から作った表）、その出典と作り方 | — | `engine/library/find.h` `find_english` |
| `fonts/` | 項目としては出ない。字が足りない時の代わりの書体と、Fonts ドックの見本の文 | `.otf`・`samples.json`（言語ごとの見本の文） | — | `drawn_made.h`、`dock_fonts.dart` |
| `extensions/` | 項目としては出ない。Hydra のコードを貼ると動く | `hydra/get.sh` だけ | — | `doc_door.h`、`hydra_isf.cpp` |

## 空に見える棚

- `extensions/hydra/` は `get.sh` しかありません。Hydra（hydra-synth）は AGPL-3.0 なので、このリポジトリにも配る物にも入れません。`get.sh` を走らせると利用者のフォルダの `extensions/hydra/` に取って来て、本体はそちらを読みます。消せば Motolii は元のままです。
- `ways/` は見本 1 つ（`snappy.way`）です。プリセットは利用者の持ち物なので、利用者のフォルダの `ways/` に置く物が本体です。

## 名前の決まり

ファイル名を直す前に、上の「表示名はどこから」を見てください。

- 1 行目に `// 名前:` がある物（`effects/` の `.js`・`.wgsl`、`recipes/`、`animators/`、`relations/`、`solids/`、`ways/`）：ファイル名は表示されないので、形は問いません。今あるのは出どころの名前のままです（`solids/` は Alight Motion の名前の空白を `_` にした物、`recipes/shapes/am_*` は AbsentMotion の形）。
- ファイル名がそのまま表示名になる物（`looks/`、`effects/` の `.fs`、頭の無い p5 のスケッチ `recipes/copies/Cube Wave.js` など、`// 名前:` の無い `relations/`）：ファイル名が利用者に見える名前です。空白も大文字もそのまま書きます。ISF の `.fs` は配られた時の名前のままです。
- `aviutl_scripts/`：`<作者>__<パッケージ>/` で、AviUtl2 のカタログの作者名とパッケージ名です（`__` の後ろがパック名として出ます）。中は配られた形のまま、`LICENSE` と `SOURCE.txt` を添えます。
- 棚に置くのは 1 つで 1 項目になる物だけです。何かの部品（例：押し出した形の UV を作る `face_uv.js`）は、それを動かすコードの隣（`engine/community/js/`）に置きます。

## 棚と口

- `shelves/aviutl_scripts/` は**棚**：利用者に配る AviUtl2 のスクリプトそのもの。
- `engine/community/aviutl/` は**口**：そのスクリプトを Motolii の中で動かすコード（Lua の実行、HLSL を WGSL に直す所）。

ほかの棚も同じで、ネットのコードを動かす口は `engine/community/`（ISF・three.js・p5・AE の式・Shadertoy）にあります。

## ここに無い物

- 効果のつまみの重み（`knob_weights.json`）は棚ではなく、Effects ドックのタイルが読む表なので、読む `effect_tiles.dart` の隣（`app/lib/workspace/shelf/`）に置いています。
- Make ドックの Elements（Alight Motion の My Elements）は利用者のフォルダの `elements/` だけにあり、同梱の物はありません（`doc_looks.h`）。
