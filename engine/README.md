# engine/ — Motolii のエンジン

*Motolii's engine (C++ / Objective-C++). The app (`../app/`) calls it through the C calls in `entry/motolii.h`; `entry/motolii.mm` becomes `out/libmotolii.dylib`. Start with the four commands below and the folder table; the list of files the build reads is written by a script from the compiler's own dependency output, not by hand.*

アプリ（`../app/`）は、ここが組む `out/libmotolii.dylib` を C の呼び出しで使います。作りの全体は [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)。

## 走らせる物

ここに置くのは、人が手で打つ 4 つだけ。ほかのスクリプトは、それが呼ぶ物（`deps/`・`gpu/`）。

| コマンド | 何をする |
|---|---|
| `./edit.sh プロジェクト.motolii` | エンジンを組み（変わった所だけ）、プロジェクトを開いて 1 行ずつ命令を受ける（`help` で一覧）。初回は依存を取ってくる |
| `./build_lib.sh` | `out/libmotolii.dylib` だけ組み直す。`entry/motolii.mm` を直した後、アプリを開き直す前に |
| `./check_syntax.sh` | 組まずに `clang++ -fsyntax-only`。錠も要らず何も書かない。`ok: entry/motolii.mm` か、誤りとその行 |
| `./drawings_unchanged.sh <古いコミット>` | 棚のレシピと動きを、古いコミットのエンジンと今のエンジンで同じプロジェクトを描き、絵を `cmp` で比べる（[`../docs/TESTING.md`](../docs/TESTING.md)「今あるプロジェクトの見た目が変わらない」） |

組む物（`edit.sh`・`build_lib.sh`・`drawings_unchanged.sh`）は、機械に 1 つのビルドの錠（`deps/build_lock.sh`）を自分で取る。

**エディタ（VS Code などの clangd）**：`edit.sh` で依存を取ってきた後に `./deps/compile_commands.sh` を 1 回（ヘッダーを足した時も）。`compile_commands.json` ができ、「part of X.h」の部品にもそれを読む所までの文脈が付く。

## フォルダ

| フォルダ | 中身 |
|---|---|
| `entry/` | アプリが呼ぶ入口。`motolii.h`＝C の呼び出しの全部（プロジェクトを開く・レイヤーを足す・値を変える・キー・取り消し・書き出し・フレームを受け取る）、`motolii.mm`＝その実装（`libmotolii.dylib` になる）、`calls*.h`＝呼び出しを役目で分けた部品（探す・地図・音・ファイル・時刻…）、`render_thread*.h`＝プロジェクトと GPU を持つレンダースレッド 1 本、`window.h`＝開く・閉じる、`export.h`＝書き出し、`edit.cpp`＝同じ呼び出しを 1 行ずつ打つシェル |
| `document/` | プロジェクト（SQLite）。`doc.h`＝全部を読む入口、ほかはその部品：`undo.h`＝表と取り消し（変更を SQLite の表に積む）、`values.h`・`keys_put.h`・`layer_edit.h`＝レイヤー・値・キー、`evaluate.h`・`match.h`＝ある時刻の値を出してプレビューへ反映、`presets.h`・`recipes.h`・`folders.h`＝棚を読む。中の関数名の頭 `doc_` はファイル名には付けない（フォルダが言っている） |
| `stage/` | 描く所。`kit/`＝Filament で描く所（Engine・カメラ・光・書き出し、3D ファイル `gltf_model.h`・点群 `point_cloud.h`）、`drawn/`＝ThorVG のキャンバスに描いた 2D の絵をプレビューに板として置く所（パスの演算：`thorvg_path_operators.cpp`・`skia_path_operations.cpp`）、`effects/`＝効果（レイヤーごと `layer_fx.h`・画面全体 `screen_fx.h`・Filament の設定ファイル `viewer_settings.h`）。直下はプレビューから外へ出す物だけ：アプリへ渡すフレーム（`live.h`）・アプリが読むプロジェクトの写し（`picture.h`）・再生用のキャッシュ（`stage_kept.h`） |
| `community/` | ネットのコードをそのまま動かす口：`aviutl/`（AviUtl2）・`shaders/`（ISF・Shadertoy）・`js/`（p5・AE 式・three.js）・`absent_motion/`・`three_tsl/`（three.js の TSL を three.js 自身の組み立て役で WGSL に） |
| `media/` | GStreamer で読む物。名前の頭で分かれる：`video_*`＝動画（`video_layer.h`＝プレビューに置く動画のレイヤー、GPU で解く・`video_frames_for_scripts.h`＝スケッチが CPU で読む小さなフレーム・`video_datamosh.h`・`video_flash_check.cpp`＝点滅の検査（IRIS））、`sound_*`＝音（`sound_level.h`＝大きさ・`sound_playback.h`＝再生中に鳴らす）、`midi_*`＝MIDI、`gstreamer_file_source.h`＝ファイルを渡す口 |
| `motion/` | 動き：イーズは `easing_*.h` だけ（`easing_curves.h`＝キーの間の 9 種・`easing_names.h`＝名前で呼ぶイーズ・`easing_godot.h`）、`lottie_motion.h`＝Lottie の動きを ThorVG が解く |
| `physics/` | 物理：`physics.h`＝口、`jolt.cpp`＝その裏の Jolt |
| `materials/` | Filament の材質（`.mat`）と、それが `#include` する `.glsl`。組むのは `gpu/kit_wgpu.sh` が名を挙げる物。`.glsl` を別のフォルダに分けないのは Filament 自身の置き方（`filament/src/materials/ssao/` は `sao.mat` の隣に `saoImpl.fs`） |
| `gpu/` | Filament・ThorVG を WebGPU（Dawn）で組むスクリプト（`build.sh`・`tvg_on_dawn.sh`・`kit_wgpu.sh`）と、Filament の組み立ての中で組む interop（`*_door.cpp`：Filament・Dawn の公開されていない内側に届く所）。`js_effects.sh`・`tsl_on_dawn.sh` は手で走らせる試し |
| `deps/` | 外のライブラリを取ってきて組むスクリプト、ビルドの錠、エディタ用の `compile_commands.sh`、下の一覧を作る `files_in_build.sh`。`deps/patches/<ライブラリ>/` は人のコードに当てる差分（`.patch`） |
| `third_party/` | 取ってくる依存（git の外）と、同梱の小さな物（`anime/`・`godot_easing/`・`js/`・`midi_roll/`・`qdtsne/`・`rapidfuzz/`・`scipy_lsap/`・`thermion_frame/`） |
| `out/` | 組み立てと描いた物の出力（git の外） |

**adapter と interop**：人のコードとの境目は 1 か所に閉じ込める。Filament の公開されていない内側に手を入れる interop は `gpu/*_door.*` だけ、ネットのコードを形を変えずに動かす adapter は `community/door*.h` と `document/adapter.h` だけ。相手が変わったら、そこだけを直す。

同梱の効果・レシピ・字体などの棚は、リポジトリ直下の [`../shelves/`](../shelves/) にあります。

## 今の組み立てが読むファイル

`edit.sh` と `gpu/build.sh` から呼ばれるスクリプトを辿り、そこに名前が出る `.cpp`/`.mm` を `clang++ -MM` にかけて、読むヘッダーを全部数えた物。手で書き換えず、ファイルを足したり消したりしたら `./deps/files_in_build.sh --write` で書き直す。

<!-- files_in_build.sh -->
129 files of ours (22 units and the headers they read), of the 131 .h/.cpp/.mm git keeps here outside third_party/. Scripts followed: `deps/build_lock.sh`、`deps/curve_fit_nd.sh`、`deps/iris.sh`、`deps/jolt.sh`、`deps/libtess2.sh`、`deps/midi_roll.sh`、`deps/skia.sh`、`deps/tree_sitter.sh`、`edit.sh`、`gpu/CMakeLists.txt`、`gpu/build.sh`、`gpu/kit_wgpu.sh`、`gpu/tvg_on_dawn.sh`. Made by `./deps/files_in_build.sh --write`.

- `community/` (2): `door.h`、`door_net.h`
- `community/absent_motion/` (4): `absent_drawing.cpp`、`absent_ends.cpp`、`absent_motion.cpp`、`absent_motion.h`
- `community/aviutl/` (9): `aviutl.cpp`、`aviutl.h`、`aviutl_fx.h`、`aviutl_load.h`、`aviutl_obj.h`、`aviutl_obj_draw.h`、`aviutl_obj_effect.h`、`aviutl_pixels.h`、`aviutl_run.h`
- `community/js/` (11): `ae_expr.h`、`js_returned.cpp`、`lottie_slots.h`、`p5_mesh.h`、`p5_stand.h`、`p5_three.h`、`script.cpp`、`script.h`、`script_leva.h`、`solid_three.cpp`、`solid_three.h`
- `community/shaders/` (11): `door_p5_shader.h`、`door_shadertoy.h`、`door_shadertoy_json.h`、`hydra_isf.cpp`、`hydra_isf.h`、`isf.cpp`、`isf.h`、`splatfx.cpp`、`splatfx.h`、`three_isf.cpp`、`three_isf.h`
- `document/` (35): `adapter.h`、`arrange.h`、`camera.h`、`card_table.h`、`cards.h`、`doc.h`、`easings_put.h`、`evaluate.h`、`expressions.h`、`folders.h`、`fx_list.h`、`fx_put.h`、`hold.h`、`keys_put.h`、`kinds.h`、`layer_edit.h`、`marks.h`、`match.h`、`material.h`、`moment_fx.h`、`parent.h`、`paths.h`、`place.h`、`presets.h`、`recipes.h`、`relate.h`、`relations.h`、`scripts.h`、`shown.h`、`sketch.h`、`time_edit.h`、`undo.h`、`value_at.h`、`values.h`、`world.h`
- `entry/` (14): `calls.h`、`calls_files.h`、`calls_find.h`、`calls_later.h`、`calls_map.h`、`calls_sound.h`、`calls_time.h`、`edit.cpp`、`export.h`、`motolii.h`、`motolii.mm`、`render_thread.h`、`render_thread_loop.h`、`window.h`
- `gpu/` (7): `compute_door.cpp`、`compute_door.h`、`gpu_door.cpp`、`gpu_door.h`、`screen_door.cpp`、`screen_door.h`、`tvg_on_dawn.cpp`
- `media/` (10): `gstreamer_file_source.h`、`midi_notes.h`、`midi_roll.cpp`、`midi_roll.h`、`sound_level.h`、`sound_playback.h`、`video_datamosh.h`、`video_flash_check.cpp`、`video_frames_for_scripts.h`、`video_layer.h`
- `motion/` (4): `easing_curves.h`、`easing_godot.h`、`easing_names.h`、`lottie_motion.h`
- `physics/` (2): `jolt.cpp`、`physics.h`
- `stage/` (3): `live.h`、`snapshot.h`、`stage_kept.h`
- `stage/drawn/` (8): `drawn.h`、`drawn_edge.h`、`drawn_flat.h`、`drawn_kept.h`、`drawn_made.h`、`drawn_sketch.h`、`skia_path_operations.cpp`、`thorvg_path_operators.cpp`
- `stage/effects/` (3): `layer_fx.h`、`screen_fx.h`、`viewer_settings.h`
- `stage/kit/` (6): `gltf_model.h`、`kit.h`、`kit_draw.h`、`kit_stage.h`、`kit_things.h`、`point_cloud.h`

Not read by the build (2): `gpu/js_effects.cpp`、`gpu/tsl_on_dawn.cpp`
<!-- /files_in_build.sh -->

本体が使わない試し（ガラスや光、Dawn、プローブ、Widgetbook など）は main から外しました。履歴はタグ `lab-archive-2026-11-09` に残っています（`git show lab-archive-2026-11-09:lab/`）。
