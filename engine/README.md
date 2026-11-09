# engine/ — Motolii の中身（エンジン）

*Motolii's engine (C++ / Objective-C++). Google's Filament is fetched into `third_party/` at build time. The entry points are `motolii.h` (the C calls the window uses), `motolii_hand.h` (the thread that owns the document and draws) and `edit.cpp` (a shell that takes one call per line). Of the ~300 files at this level, 63 are what the current build reaches (listed below); the rest are earlier probes kept as they were.*

窓（`../app/`）は、ここが組む `out/libmotolii.dylib` を C の呼び出しで使います。作りの全体は [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md)。

**door（扉）**：人のコードとの境目を 1 か所に閉じ込めたファイル。Filament の公開されていない中身に手を入れるのは `gpu/*_door.*` だけ、ネットのコードをそのまま入れるのは `community/door*.h` と `document/doc_door.h` だけで、相手が変わったら扉だけを直す。

## 入口

| ファイル | 何か |
|---|---|
| `motolii.h` | 窓が使う C の呼び出しの全部（書類を開く・物を足す・値を変える・キー・取り消し・書き出し・絵を受け取る） |
| `motolii.mm` | その実装（`libmotolii.dylib` になる）。中で `motolii_hand.h`（書類を持って描くスレッド）と `motolii_calls.h` を読む |
| `edit.cpp` | 1 行ずつの命令で書類をいじるシェル。`./edit.sh 書類.motolii` で組んで開く（`help` で一覧） |
| `doc.h` と `doc_*.h` | 書類（SQLite）：物・値・キー・取り消し（変更を SQLite の表に積む）・場面への反映 |
| `kit.h`・`kit_*.h`・`drawn*.h` | Filament と ThorVG で描く所 |

## 今の組み立てが使う物

`edit.sh` → `gpu/kit_wgpu.sh` が組む物。`#include` を辿ると、この階層では次の 63 本です。

- 書類：`doc.h`、`doc_edit.h`、`doc_kinds.h`、`doc_looks.h`、`doc_match.h`、`doc_moment.h`、`doc_moment_fx.h`、`doc_paths.h`、`doc_place.h`、`doc_recipes.h`、`doc_relations.h`、`doc_values.h`、`interp.h`、`ways.h`
- 描く：`kit.h`、`kit_draw.h`、`kit_stage.h`、`kit_things.h`、`drawn.h`、`drawn_flat.h`、`drawn_kept.h`、`drawn_made.h`、`screen.h`、`stage_kept.h`、`picture.h`、`points.h`、`solid.h`、`live.h`、`lottie_slots.h`、`bend.cpp`、`skpath.cpp`
- 効果：`thing_fx.h`、`isf.cpp`・`isf.h`（ISF）、`aviutl.cpp`・`aviutl.h`・`aviutl_fx.h`（AviUtl2）、`splatfx.cpp`・`splatfx.h`（点群）、`three_isf.cpp`・`three_isf.h`、`solid_three.cpp`・`solid_three.h`（three.js の形）、`mosh.h`
- 動き・音・動画：`motion.h`、`physics.cpp`・`physics.h`（Jolt）、`script.cpp`・`script.h`（QuickJS のレシピ）、`godot_easing.h`、`video.h`、`gst_read.h`、`sound.h`、`heard.h`、`midi.h`、`midi_roll.cpp`・`midi_roll.h`
- 入口：`motolii.h`、`motolii.mm`、`motolii_calls.h`、`motolii_hand.h`、`motolii_write.h`、`edit.cpp`

材質（`.mat`）は `kit_wgpu.sh` の一覧の 22 本（`paper`・`flat`・`floor_lit`・`solid_image` など）と、それが読む `.glsl`。

## それ以外

本体が使わない試し（ガラスや光、Dawn、プローブ、Widgetbook など）は main から外しました。履歴はタグ `lab-archive-2026-11-09` に残っています（`git show lab-archive-2026-11-09:lab/`）。

## フォルダ

| フォルダ | 中身 |
|---|---|
| `library/` | 窓が呼ぶ本体：`motolii.h`（C の呼び出し）・`motolii.mm`（`libmotolii.dylib` になる）・`edit.cpp`（1 行ずつの命令のシェル） |
| `document/` | 書類（SQLite）：`doc_*.h`。物・値・キー・取り消し・場面への反映 |
| `stage/` | 描く所：Filament と ThorVG（`kit*.h`・`drawn*.h`・`live.h`） |
| `community/` | ネットのコードをそのまま動かす口：`aviutl/`（AviUtl2）・`shaders/`（ISF・Shadertoy）・`js/`（p5・AE 式・three.js）・`absent_motion/`・`three_tsl/`（three.js の TSL を three.js 自身の組み立て役で WGSL に） |
| `media/` | 動画（GStreamer）・音・MIDI |
| `motion/` | 動き：キーの間・イーズ・物理（Jolt） |
| `materials/` | Filament の材質（`.mat`）と、それが読む `.glsl` |
| `gpu/` | Filament・ThorVG を WebGPU（Dawn）で組むスクリプト（`build.sh`・`tvg_on_dawn.sh`・`kit_wgpu.sh`）と、Filament の組み立ての中で組む口（`*_door.cpp`） |
| `deps/` | 外のライブラリを取ってきて組むスクリプト。`deps/patches/<ライブラリ>/` は人のコードに当てる差分（`.patch`） |
| `third_party/` | 取ってくる依存（git の外）と、同梱の小さな物 |
| `out/` | 組み立てと描いた物の出力（git の外）。`out/gpu/`・`out/tsl/` もここ |

同梱の効果・レシピ・字体などの棚は、リポジトリ直下の [`../shelves/`](../shelves/) にあります。
