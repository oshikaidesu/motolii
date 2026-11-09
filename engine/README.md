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
| `entry/` | アプリが呼ぶ入口。`motolii.h`＝C の呼び出しの全部（プロジェクトを開く・レイヤーを足す・値を変える・キー・取り消し・書き出し・フレームを受け取る）、`motolii.mm`＝その実装（`libmotolii.dylib` になる）、`motolii_calls_*.h`＝呼び出しを役目で分けた部品（探す・地図・音・ファイル・時刻…）、`motolii_hand*.h`＝プロジェクトと GPU を持つレンダースレッド 1 本、`edit.cpp`＝同じ呼び出しを 1 行ずつ打つシェル |
| `document/` | プロジェクト（SQLite）：`doc_*.h`。レイヤー・値・キー・取り消し（変更を SQLite の表に積む）・プレビューへの反映 |
| `stage/` | 描く所。`kit/`＝Filament で描く所（Engine・カメラ・光・立体・書き出し）、`drawn/`＝ThorVG のキャンバスに描いた 2D の絵をプレビューに板として置く所、ほかは効果（`thing_fx.h`・`screen.h`）・アプリへ渡すフレーム（`live.h`）・再生用のキャッシュ（`stage_kept.h`） |
| `community/` | ネットのコードをそのまま動かす口：`aviutl/`（AviUtl2）・`shaders/`（ISF・Shadertoy）・`js/`（p5・AE 式・three.js）・`absent_motion/`・`three_tsl/`（three.js の TSL を three.js 自身の組み立て役で WGSL に） |
| `media/` | 動画（GStreamer）・音・MIDI・点滅の検査（IRIS） |
| `motion/` | 動き：キーの間・イーズ・物理（Jolt） |
| `materials/` | Filament の材質（`.mat`）と、それが読む `.glsl`。組むのは `gpu/kit_wgpu.sh` が名を挙げる物 |
| `gpu/` | Filament・ThorVG を WebGPU（Dawn）で組むスクリプト（`build.sh`・`tvg_on_dawn.sh`・`kit_wgpu.sh`）と、Filament の組み立ての中で組む interop（`*_door.cpp`：Filament・Dawn の公開されていない内側に届く所）。`js_effects.sh`・`tsl_on_dawn.sh` は手で走らせる試し |
| `deps/` | 外のライブラリを取ってきて組むスクリプト、ビルドの錠、エディタ用の `compile_commands.sh`、下の一覧を作る `files_in_build.sh`。`deps/patches/<ライブラリ>/` は人のコードに当てる差分（`.patch`） |
| `third_party/` | 取ってくる依存（git の外）と、同梱の小さな物（`anime/`・`godot_easing/`・`js/`・`midi_roll/`・`qdtsne/`・`rapidfuzz/`・`scipy_lsap/`・`thermion_frame/`） |
| `out/` | 組み立てと描いた物の出力（git の外） |

**adapter と interop**：人のコードとの境目は 1 か所に閉じ込める。Filament の公開されていない内側に手を入れる interop は `gpu/*_door.*` だけ、ネットのコードを形を変えずに動かす adapter は `community/door*.h` と `document/doc_door.h` だけ。相手が変わったら、そこだけを直す。

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
- `document/` (35): `doc.h`、`doc_arrange.h`、`doc_card_table.h`、`doc_cards.h`、`doc_door.h`、`doc_edit.h`、`doc_expressions.h`、`doc_eye.h`、`doc_folders.h`、`doc_fx_list.h`、`doc_fx_put.h`、`doc_hold.h`、`doc_keys_put.h`、`doc_kinds.h`、`doc_looks.h`、`doc_marks.h`、`doc_match.h`、`doc_moment.h`、`doc_moment_fx.h`、`doc_parent.h`、`doc_paths.h`、`doc_place.h`、`doc_recipes.h`、`doc_relate.h`、`doc_relations.h`、`doc_scripts.h`、`doc_shown.h`、`doc_sketch.h`、`doc_steps.h`、`doc_time_edit.h`、`doc_value_at.h`、`doc_values.h`、`doc_ways_put.h`、`doc_wear.h`、`doc_world.h`
- `entry/` (14): `edit.cpp`、`motolii.h`、`motolii.mm`、`motolii_calls.h`、`motolii_calls_files.h`、`motolii_calls_find.h`、`motolii_calls_later.h`、`motolii_calls_map.h`、`motolii_calls_moment.h`、`motolii_calls_sound.h`、`motolii_hand.h`、`motolii_hand_loop.h`、`motolii_window.h`、`motolii_write.h`
- `gpu/` (7): `compute_door.cpp`、`compute_door.h`、`gpu_door.cpp`、`gpu_door.h`、`screen_door.cpp`、`screen_door.h`、`tvg_on_dawn.cpp`
- `media/` (10): `video_frames_for_scripts.h`、`video_flash_check.cpp`、`gstreamer_file_source.h`、`sound_playback.h`、`midi_notes.h`、`midi_roll.cpp`、`midi_roll.h`、`video_datamosh.h`、`sound_level.h`、`video_layer.h`
- `motion/` (6): `godot_easing.h`、`interp.h`、`motion.h`、`physics.cpp`、`physics.h`、`ways.h`
- `stage/` (10): `bend.cpp`、`live.h`、`picture.h`、`points.h`、`screen.h`、`skpath.cpp`、`solid.h`、`stage_kept.h`、`thing_fx.h`、`viewer_settings.h`
- `stage/drawn/` (6): `drawn.h`、`drawn_edge.h`、`drawn_flat.h`、`drawn_kept.h`、`drawn_made.h`、`drawn_sketch.h`
- `stage/kit/` (4): `kit.h`、`kit_draw.h`、`kit_stage.h`、`kit_things.h`

Not read by the build (2): `gpu/js_effects.cpp`、`gpu/tsl_on_dawn.cpp`
<!-- /files_in_build.sh -->

本体が使わない試し（ガラスや光、Dawn、プローブ、Widgetbook など）は main から外しました。履歴はタグ `lab-archive-2026-11-09` に残っています（`git show lab-archive-2026-11-09:lab/`）。
