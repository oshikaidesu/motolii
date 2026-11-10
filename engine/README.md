# engine/ — Motolii のエンジン

*Motolii's engine (C++ / Objective-C++). The app (`../app/`) calls it through the C calls in `entry/motolii.h`; `entry/motolii.mm` becomes `out/libmotolii.dylib`. `./build.sh` is the build; start with the four commands below and the folder table; the list of files the build reads is written by a script from the compiler's own dependency output, not by hand.*

アプリ（`../app/`）は、ここが組む `out/libmotolii.dylib` を C の呼び出しで使います。作りの全体は [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)。

## 走らせる物

組み立ては `./build.sh` の 1 つだけ。ここに置くのは人が手で打つ 4 つで、ほかのスクリプトは `build.sh` が呼ぶ部品（`deps/`・`gpu/filament_webgpu.sh`）か、下の表に書いた手で走らせる試し。

| コマンド | 何をする |
|---|---|
| `./build.sh` | **組み立て**。アプリが読む `out/libmotolii.dylib` と、`edit.sh` のシェル `out/edit_wgpu` を、変わった所だけ組む。初回は依存を取ってきて Filament をソースから組む（`deps/filament.sh`、M4 で約 5 分）。`./build.sh lib` は `libmotolii.dylib` だけ（`entry/motolii.mm` を直した後、アプリを開き直す前に） |
| `./edit.sh プロジェクト.motolii` | `build.sh` を通してから、プロジェクトを開いて 1 行ずつ命令を受ける（`help` で一覧） |
| `./check_syntax.sh` | 組まずに `clang++ -fsyntax-only`。錠も要らず何も書かない。`ok: entry/motolii.mm` か、誤りとその行 |
| `./drawings_unchanged.sh <古いコミット>` | 棚のレシピと動きを、古いコミットのエンジンと今のエンジンで同じプロジェクトを描き、絵を `cmp` で比べる（[`../docs/TESTING.md`](../docs/TESTING.md)「今あるプロジェクトの見た目が変わらない」） |

組む物（`build.sh`・`edit.sh`・`drawings_unchanged.sh`）は、機械に 1 つのビルドの錠（`tools/build_lock.sh`）を自分で取る。

**エディタ（VS Code などの clangd）**：`build.sh` で依存を取ってきた後に `./tools/compile_commands.sh` を 1 回（ヘッダーを足した時も）。`compile_commands.json` ができ、「part of X.h」の部品にもそれを読む所までの文脈が付く。

## フォルダ

| フォルダ | 中身 |
|---|---|
| `entry/` | アプリが呼ぶ入口。`motolii.h`＝C の呼び出しの全部（プロジェクトを開く・レイヤーを足す・値を変える・キー・取り消し・書き出し・フレームを受け取る）、`motolii.mm`＝その実装（`libmotolii.dylib` になる）、`calls*.h`＝呼び出しを役目で分けた部品（探す・地図・音・ファイル・時刻…）、`render_thread*.h`＝プロジェクトと GPU を持つレンダースレッド 1 本、`window.h`＝開く・閉じる、`export.h`＝書き出し、`snapshot.h`＝アプリが読むプロジェクトの写し、`edit.cpp`＝同じ呼び出しを 1 行ずつ打つシェル |
| `base/` | どこからも使う小さな部品：`json.h`＝rapidjson の入口（Filament に付いてくる 1 つの写しをここだけが名前で指す） |
| `document/` | プロジェクト（SQLite）。`doc.h`＝全部を読む入口、ほかはその部品：`undo.h`＝表と取り消し（変更を SQLite の表に積む）、`values.h`・`keys_put.h`・`layer_edit.h`＝レイヤー・値・キー、`evaluate.h`・`match.h`＝ある時刻の値を出してプレビューへ反映、`presets.h`・`recipes.h`＝棚を読む。中の関数名の頭 `doc_` はファイル名には付けない（フォルダが言っている） |
| `shelf/` | 棚のフォルダを探す所：`shelf_folders.h`＝ライブラリのフォルダと利用者のフォルダ（`doc_folders`）、エンジン内の部品の場所（`doc_engine`）、ファイルが変わったかの数え（`files_changed`） |
| `stage/` | 描く所。`render/`＝Filament で描く所（Engine・カメラ・光・書き出し、3D ファイル `gltf_model.h`・点群 `point_cloud.h`）、`canvas/`＝ThorVG のキャンバスに描いた 2D の絵をプレビューに板として置く所（パスの演算：`thorvg_path_operators.cpp`・`skia_path_operations.cpp`）、`effects/`＝効果（レイヤーごと `layer_fx.h`・画面全体 `screen_fx.h`・Filament の設定ファイル `viewer_settings.h`）。直下はプレビューから外へ出す物だけ：アプリへ渡すフレーム（`live.h`） |
| `preview/` | プロジェクトをステージに置く側：再生用のキャッシュ（`playback_cache.h`） |
| `community/` | ネットのコードをそのまま動かす口。中のフォルダは、動かす相手（コミュニティ）ごとに 1 つ（下の「`community/` の中」） |
| `media/` | GStreamer で読む物。名前の頭で分かれる：`video_*`＝動画（`video_layer.h`＝プレビューに置く動画のレイヤー、GPU で解く・`video_frames_for_scripts.h`＝スケッチが CPU で読む小さなフレーム・`video_datamosh.h`・`video_flash_check.cpp`＝点滅の検査（IRIS））、`sound_*`＝音（`sound_level.h`＝大きさ・`sound_playback.h`＝再生中に鳴らす）、`midi_*`＝MIDI、`gstreamer_file_source.h`＝ファイルを渡す口 |
| `motion/` | 動き：イーズは `easing_*.h` だけ（`easing_curves.h`＝キーの間の 9 種・`easing_names.h`＝名前で呼ぶイーズ・`easing_godot.h`）、`lottie_motion.h`＝Lottie の動きを ThorVG が解く |
| `physics/` | 物理：`physics.h`＝口、`jolt.cpp`＝その裏の Jolt |
| `materials/` | Filament の材質（`.mat`）と、それが `#include` する `.glsl`。組むのは `gpu/filament_webgpu.sh` が名を挙げる物。`.glsl` を別のフォルダに分けないのは Filament 自身の置き方（`filament/src/materials/ssao/` は `sao.mat` の隣に `saoImpl.fs`） |
| `gpu/` | Filament の WebGPU（Dawn）の上の自前：`filament_webgpu.sh`＝材質・ThorVG・リンク（`build.sh` が呼ぶ。手で打たない）、`CMakeLists.txt` と `*_interop.cpp`＝Filament の組み立ての中で組む interop（Filament・Dawn の公開されていない内側に届く所）、`thorvg_on_dawn.cpp`（`deps/thorvg.sh` が組んで走らせる確かめ） |
| `deps/` | 他人の物を取ってきて組む・取り込むスクリプト。1 ライブラリ 1 本（`filament.sh`・`thorvg.sh`・`skia.sh`・`jolt.sh`…、全部 `build.sh` から）と、手で 1 回走らせる物（`likeness_models.py`＝棚の地図の絵の読み手 CLIP・FontCLIP を ONNX に、`wnja_export.py`・`from_gflanguages.py`＝日本語 WordNet と Google Fonts の見本を `third_party/` の形に）。`deps/patches/<ライブラリ>/` は人のコードに当てる差分（`.patch`） |
| `tools/` | 何も取ってこない自前の道具：ビルドの錠 `build_lock.sh`（組むスクリプトが全部読む）、エディタと下の検査が読む `compile_commands.json` を書く `compile_commands.sh`（`.cpp`・`.mm` ごとに、それを組む時のフラグ）・`clangd_context.py`、下の一覧を書く `files_in_build.sh`。組まずに確かめる検査：`check_file.sh`＝ファイル 1 つが、自分で読む物だけで通るか、`function_census.py`＝関数・型・変数・マクロの定義を全部数え、`--diff <コミット>` で、移しただけなら中身が 1 文字も変わっていないことを示す（読むのは ast-grep） |
| `third_party/` | 取ってくる依存（git の外）と、同梱の小さな物（`anime/`・`godot_easing/`・`js/`・`leva/`・`midi_roll/`・`qdtsne/`・`rapidfuzz/`・`scipy_lsap/`・`thermion_frame/`・`ymm4-luascript/` ほか）。`leva/`・`ymm4-luascript/` は、自前のヘッダーにそのまま貼った他人のコード（`community/quickjs/script_leva.h`・`community/aviutl/aviutl_fx.h`）のライセンス文書 |
| `out/` | 組み立てと描いた物の出力（git の外） |

**adapter と interop**：人のコードとの境目は 1 か所に閉じ込める。Filament の公開されていない内側に手を入れる interop は `gpu/*_interop.*` だけ、ネットのコードを形を変えずに動かす adapter は `community/sites/adapter*.h`・`community/p5/adapter_p5_shader.h` と `document/scripts/adapter.h` だけ。相手が変わったら、そこだけを直す。

### `community/` の中

C++ の口は、動かす相手ごとに 1 フォルダ。どれも相手のコードを書き換えず、そのまま 1 回組んで動かす（AGENTS.md 原則 1）。

| フォルダ | 動かす物 |
|---|---|
| `quickjs/` | 棚の JavaScript（レシピ・式・関係）を QuickJS-ng で動かす土台：頭のパラメーター（AviUtl2 の書き方と leva の書き方）、`each()`下の p5・three.js・AE 式もこの上で動く |
| `after_effects/` | AE の式（`ae_expr.h`）と、AE から書き出した Lottie の slots（`lottie_slots.h`） |
| `p5/` | p5.js のスケッチを p5.js 自身でページ無しに動かす物と、`shader()` で塗るスケッチを ISF にする `adapter_p5_shader.h` |
| `three/` | three.js：立体の形（`solid_three.cpp`、棚の `solids/` が読む部品 `face_uv.js`）と、画面の効果を ISF にする `three_isf.cpp` |
| `isf/` | ISF の効果（`.fs`）を glslang と Tint で WGSL にする所。シェーダーの口はみなここに行き着く |
| `hydra/` | Hydra のコードを Hydra 自身で GLSL にし、ISF の効果にする |
| `playcanvas/` | PlayCanvas のガウシアンスプラットの効果（点群の見た目、`splatfx.cpp`） |
| `sites/` | サイトに貼られた形のままのコード（Dwitter・tixy.land・Turtletoy・Shadertoy・GLSL Sandbox・OpenProcessing…）を見分けて、上の口のどれかに渡す（`adapter*.h`） |
| `aviutl/` | AviUtl2 のスクリプト（Lua と HLSL） |
| `absent_motion/` | AbsentMotion の動きと文字の効果（C++ のまま） |
| `three_shading_language_to_shelf/` | **C++ ではない Node の道具**（`package.json`）。ネットの TSL（three.js Shading Language）の作品集を `fetch.sh` で取り、three.js 自身の変換器で WGSL にし（`convert.ts`）、`write_shelf_*.ts` が `shelves/effects/` のファイルに書く。組み立ては読まない |

同梱の効果・レシピ・字体などの棚は、リポジトリ直下の [`../shelves/`](../shelves/) にあります。

## 今の組み立てが読むファイル

`build.sh` から呼ばれるスクリプトを辿り、そこに名前が出る `.cpp`/`.mm` を `clang++ -MM` にかけて、読むヘッダーを全部数えた物。手で書き換えず、ファイルを足したり消したりしたら `./tools/files_in_build.sh --write` で書き直す。

<!-- files_in_build.sh -->
128 files of ours (21 units and the headers they read), of the 128 .h/.cpp/.mm git keeps here outside third_party/. Scripts followed: `build.sh`、`deps/curve_fit_nd.sh`、`deps/filament.sh`、`deps/iris.sh`、`deps/jolt.sh`、`deps/libtess2.sh`、`deps/midi_roll.sh`、`deps/skia.sh`、`deps/thorvg.sh`、`gpu/CMakeLists.txt`、`gpu/filament_webgpu.sh`、`tools/build_lock.sh`. Made by `./tools/files_in_build.sh --write`.

- `community/absent_motion/` (4): `absent_drawing.cpp`、`absent_ends.cpp`、`absent_motion.cpp`、`absent_motion.h`
- `community/after_effects/` (2): `ae_expr.h`、`lottie_slots.h`
- `community/aviutl/` (9): `aviutl.cpp`、`aviutl.h`、`aviutl_fx.h`、`aviutl_load.h`、`aviutl_obj.h`、`aviutl_obj_draw.h`、`aviutl_obj_effect.h`、`aviutl_pixels.h`、`aviutl_run.h`
- `community/hydra/` (2): `hydra_isf.cpp`、`hydra_isf.h`
- `community/isf/` (2): `isf.cpp`、`isf.h`
- `community/p5/` (4): `adapter_p5_shader.h`、`p5_mesh.h`、`p5_stand.h`、`p5_three.h`
- `community/playcanvas/` (2): `splatfx.cpp`、`splatfx.h`
- `community/quickjs/` (3): `script.cpp`、`script.h`、`script_leva.h`
- `community/sites/` (4): `adapter.h`、`adapter_net.h`、`adapter_shadertoy.h`、`adapter_shadertoy_json.h`
- `community/three/` (4): `solid_three.cpp`、`solid_three.h`、`three_isf.cpp`、`three_isf.h`
- `document/` (34): `adapter.h`、`arrange.h`、`camera.h`、`card_table.h`、`cards.h`、`doc.h`、`easings_put.h`、`evaluate.h`、`expressions.h`、`fx_list.h`、`fx_put.h`、`hold.h`、`keys_put.h`、`kinds.h`、`layer_edit.h`、`marks.h`、`match.h`、`material.h`、`moment_fx.h`、`parent.h`、`paths.h`、`place.h`、`presets.h`、`recipes.h`、`relate.h`、`relations.h`、`scripts.h`、`shown.h`、`sketch.h`、`time_edit.h`、`undo.h`、`value_at.h`、`values.h`、`world.h`
- `entry/` (15): `calls.h`、`calls_files.h`、`calls_find.h`、`calls_later.h`、`calls_map.h`、`calls_sound.h`、`calls_time.h`、`edit.cpp`、`export.h`、`motolii.h`、`motolii.mm`、`render_thread.h`、`render_thread_loop.h`、`snapshot.h`、`window.h`
- `gpu/` (7): `compute_interop.cpp`、`compute_interop.h`、`gpu_interop.cpp`、`gpu_interop.h`、`screen_interop.cpp`、`screen_interop.h`、`thorvg_on_dawn.cpp`
- `media/` (10): `gstreamer_file_source.h`、`midi_notes.h`、`midi_roll.cpp`、`midi_roll.h`、`sound_level.h`、`sound_playback.h`、`video_datamosh.h`、`video_flash_check.cpp`、`video_frames_for_scripts.h`、`video_layer.h`
- `motion/` (4): `easing_curves.h`、`easing_godot.h`、`easing_names.h`、`lottie_motion.h`
- `physics/` (2): `jolt.cpp`、`physics.h`
- `preview/` (1): `playback_cache.h`
- `shelf/` (2): `shelf_folders.cpp`、`shelf_folders.h`
- `stage/` (1): `live.h`
- `stage/canvas/` (8): `canvas.h`、`canvas_cache.h`、`canvas_edge.h`、`canvas_flat.h`、`canvas_renderables.h`、`canvas_sketch.h`、`skia_path_operations.cpp`、`thorvg_path_operators.cpp`
- `stage/effects/` (3): `layer_fx.h`、`screen_fx.h`、`viewer_settings.h`
- `stage/render/` (6): `gltf_model.h`、`point_cloud.h`、`render.h`、`render_draw.h`、`render_layers.h`、`render_stage.h`

<!-- /files_in_build.sh -->

本体が使わない試し（ガラスや光、Dawn、プローブ、Widgetbook など）は main から外しました。履歴はタグ `lab-archive-2026-11-09` に残っています（`git show lab-archive-2026-11-09:lab/`）。アプリから届かない C 関数・部品・スクリプトは、切る前の main をタグ `noise-archive-2026-11-09` に残して外しました（一覧は [`../docs/internal/notes/noise_cut.md`](../docs/internal/notes/noise_cut.md)）。
