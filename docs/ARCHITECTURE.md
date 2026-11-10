# 作り（Architecture）

*How Motolii is built, for someone about to read or change the code. A Flutter app drives a C++ engine through a small C API (`engine/entry/motolii.h`). One render thread owns the project (SQLite) and the GPU: Filament, built from source with its WebGPU (Dawn) backend and a few patches, draws the 3D scene and composites; ThorVG's WebGPU engine draws 2D and text on the same Dawn device; GStreamer reads videos and ffmpeg writes them. Shared effects are compiled to WGSL with the toolchain Filament already ships (glslang → SPIR-V → Tint). The finished frame reaches the app without a copy through IOSurface-backed CVPixelBuffers.*

コードの名前は After Effects・Filament・Flutter・Blender の言葉に揃えている途中。古い名前がまだ残るコードの読み替えは [`rename_words.md` の §1](internal/notes/rename_words.md)。

## 全体

```mermaid
flowchart TB
  subgraph Window["アプリ（app/、Flutter・macOS）"]
    UI["Timeline・Inspector・棚"]
    FFI["motolii.dart（dart:ffi）"]
  end
  subgraph Inside["エンジン（engine/、libmotolii.dylib）"]
    API["motolii.h：C の呼び出し"]
    Hand["entry/render_thread.h：プロジェクトと GPU を持つレンダースレッド 1 本"]
    Doc["doc*.h：プロジェクト（SQLite）、取り消し"]
    Render["render*.h・canvas*.h：フレームを描く"]
    FX["isf.cpp・aviutl*.h・layer_fx.h：効果"]
    Script["script.cpp：QuickJS-ng（レシピ・three.js）、LuaJIT（AviUtl2）"]
  end
  subgraph Libs["借りている物"]
    Filament["Filament 1.77.2（WebGPU で組み直し、差分つき）"]
    ThorVG["ThorVG（WebGPU のエンジン、差分つき）"]
    Dawn["Dawn（WebGPU）"]
    Gst["GStreamer（動画・音を読む）"]
    FF["ffmpeg（mp4 を書く）"]
    SQLite["SQLite"]
    Jolt["Jolt（物理）"]
  end
  UI --> FFI --> API --> Hand
  Hand --> Doc --> SQLite
  Hand --> Render --> Filament --> Dawn
  Render --> ThorVG --> Dawn
  Hand --> FX
  Hand --> Script
  Render --> Gst
  Render --> FF
  Render --> Jolt
  Render -- "CVPixelBuffer（IOSurface）3 枚、コピーなし" --> UI
```

## 境目

| 境目 | どこ | 決まり |
|---|---|---|
| アプリの入口 | `app/lib/main.dart` → `app/lib/workspace/workspace.dart`（`Workspace`：アプリの画面全体、プロジェクトを開く、メニュー）。アプリの状態は `app/lib/workspace/state/window.dart`（`Ws`） | アプリのファイルの地図は [`app/README.md`](../app/README.md)。パネルを足すのは `Workspace` の `extra`（`WsPane` の並び） |
| アプリ → エンジン | `engine/entry/motolii.h`（約 260 行）、Dart 側は `app/lib/bridge/motolii.dart` と ffigen が作る `motolii_bindings.dart` | アプリは値を持たない。読むのも変えるのも C の呼び出しで、プロジェクトが正（アプリとエンジンの境目の決まりは [`docs/app/BRIDGE.md`](../docs/app/BRIDGE.md)） |
| エンジンの中 | `engine/entry/render_thread.h` | プロジェクトと GPU に触るのはレンダースレッド 1 本だけ。アプリはこのスレッドを待たない：書きは列に積んで戻り、読むのはこのスレッドが作ったスナップショット（[`docs/app/BRIDGE.md`](app/BRIDGE.md) の決まり 1・3・6）。待つ呼び出し（`by_hand`）は試験と C の確かめの道具だけ |
| エンジン → アプリ（フレーム） | `engine/stage/live.h` | プレビューは IOSurface の上の CVPixelBuffer 3 枚に描き、それを Dawn のテクスチャとして Filament の描き先にする。アプリ（Flutter の外部テクスチャ、`app/macos/Runner/MainFlutterWindow.swift`）は同じ物を読む |
| 借りた物 | `engine/deps/patches/<ライブラリ>/` | 人のコードは直接いじらず、版を固定して取ってきて差分を当てる（[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) の 2 節） |

## 描く

- **Filament** を v1.77.2 のソースから WebGPU（Dawn）の口で組む（`engine/deps/filament.sh`）。配られている SDK には WebGPU が無いため。当てる差分：計算（compute）の口、Dawn の装置を外に貸す口、外のテクスチャを受ける `Texture::Builder::import`（`filament_dawn_compute.patch`）、AviUtl2 の HLSL のために glslang の HLSL の読み手を入れる（`glslang_hlsl.patch`）。
- **ThorVG** は WebGPU のエンジンを、Filament と同じ Dawn の装置の上で動かす（`engine/deps/thorvg.sh`、`canvas.h`）。描いた絵は Filament のシーンの中の板になる（切り抜き・ガラス越し・キーが効く）。
- 形の足し引きは **Skia** のパスの部分だけ（`engine/deps/skia.sh`）、平らな形の三角形分けは **libtess2**。
- 画面の拍子は Thermion の FrameScheduler（CVDisplayLink、`engine/third_party/thermion_frame/`）。

## 効果の道

| 置く物 | 道 | どこ |
|---|---|---|
| ISF（`.fs`、GLSL） | glslang → SPIR-V → Tint → WGSL。Filament の組み立てに入っている物をそのまま使う | `engine/community/isf/isf.cpp` |
| WGSL（`.wgsl`） | そのまま。頭に AviUtl2 式のパラメーターの行。横に置いた絵は `--image@名前:ファイル` で ThorVG が 1 回読む | `engine/stage/effects/screen_fx.h`、`layer_fx.h` |
| AviUtl2（`.anm2`・`.obj2`） | Lua は LuaJIT（AviUtl2 と同じ）で走らせ、`obj` の呼び出しをエンジンの関数で受ける。中の HLSL は glslang の HLSL の読み手 → SPIR-V → Tint → WGSL | `engine/community/aviutl/aviutl.cpp`、`aviutl_fx.h` |
| three.js の形（`shelves/solids/*.js`） | QuickJS-ng で three.js を動かし、BufferGeometry を受け取る | `engine/community/three/solid_three.cpp` |
| レシピ（`shelves/create/*/*.js`） | QuickJS-ng。1 回でレイヤーと値を作る | `engine/community/quickjs/script.cpp` |
| TSL | three.js 自身の WGSLNodeBuilder を QuickJS で（道具。棚に載せるのは出来上がった `.wgsl` だけ） | `engine/community/three_shading_language_to_shelf/`、`shelves/effects/<傾向>/` の `sl_*.wgsl`・`tt_*.wgsl`・`nf_*.wgsl`・`tf_*.wgsl` |

## プロジェクト

- 1 つの `.motolii` は SQLite のファイル。レイヤー・値・キー・キーの間のイージング（式、SQLite の関数 `bezier()`・`anime()`）を表に持つ（`engine/document/doc*.h`）。
- 取り消しは、変更を `step` の表に積む（`document/undo.h`）。
- レイヤーの種類：video・image・text・solid・shape・camera・light・behaviour（`edit.cpp` の `help`）。

## 動画・音・書き出し

- 動画は **GStreamer** が読み（何の形式でも、GStreamer が部品を選ぶ）、絵を板に貼る（`engine/media/video_layer.h`、`gstreamer_file_source.h`）。
- 作業中の音は GStreamer の playbin（`sound_playback.h`）。
- 書き出しは、1 秒 60 フレーム描いて **ffmpeg** に渡し、レイヤーの音も ffmpeg で混ぜる（`engine/stage/render/render_draw.h` の `film`）。

## 棚を読む所

`shelves/` のフォルダ（と利用者のフォルダの同じ名前のフォルダ）を、どのコードが読むか。場所を決めるのは `engine/document/folders.h` の `doc_folders` 1 つで、アプリの側は `app/lib/bridge/engine_paths.dart` の `motoliiShelves`・`motoliiOwn`。前の名前（`recipes/`・`animators/`・`ways/`）の利用者のフォルダも `doc_folders` が読み、プロジェクトに残る古い道は `script.h` の `script_shelf_file` が今の棚へ引き直す。

| フォルダ | エンジン | アプリ（`app/lib/`） |
|---|---|---|
| `effects/` | `document/recipes.h` `doc_folder_names` | `workspace/shelf/effect_tiles.dart` |
| `aviutl_scripts/` | `document/recipes.h` `doc_aviutl_names` | `workspace/shelf/effect_decks.dart` `effectPack` |
| `create/` | `document/recipes.h` `doc_recipes_read` | `workspace/dock/dock_make_expressions.dart` `_expressionRecipes`、`dock_make_create.dart` |
| `expressions/` | `entry/calls.h` `motolii_animators` | `workspace/dock/dock_make_expressions.dart` `_expressionsOf`、`workspace/shelf/shelf_add.dart`（Add to shelf の書き込み先） |
| `relations/` | `entry/calls.h` `motolii_relations` | `workspace/edits/make_relation.dart` |
| `looks/` | `document/presets.h` `doc_look_names` | `bridge/motolii_shelves.dart` `looks` |
| `solids/` | `community/three/solid_three.cpp`、`document/moment_fx.h` | — |
| `ease/` | `document/recipes.h` `doc_own_ways` | `workspace/tool_panel/tool_panel_ease_shelf.dart` |
| `skins/` | — | `skin/theme.dart` `ColorTheme.skinNames`（前の置き場 `~/.motolii/skins/` も読む） |
| `extensions/hydra/` | `document/adapter.h`、`community/hydra/hydra_isf.cpp` | — |
| （棚でない）`engine/third_party/wordnet_ja/` | `entry/calls_find.h` `find_english`（`doc_folders("words")`） | — |
| （棚でない）`engine/third_party/noto_sans_jp/` | `stage/canvas/canvas_renderables.h` `type_fallback`（`doc_folders("fonts")`） | `workspace/dock/dock_fonts.dart` |
| （棚でない）`engine/third_party/gflanguages/` | — | `workspace/dock/dock_fonts.dart`（`samples.json`） |
