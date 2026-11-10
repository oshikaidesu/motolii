# Motolii engine

The C++ / Objective-C++ library behind the app. The app (`../app/`) loads `out/libmotolii.dylib` and reaches it only
through the C API in `entry/motolii.h`. `out/edit_wgpu` is a command-line shell that makes the same calls, one per line.
For the overall design see [`../docs/ARCHITECTURE.md`](../docs/ARCHITECTURE.md).

## Build

macOS on Apple silicon, with the tools in the root `Brewfile`. Run from this folder:

    ./build.sh          # dependencies, materials, then CMake: compiles what changed
    ./build.sh lib      # the same, but only libmotolii.dylib (restart the app afterwards: a native library cannot be hot reloaded)
    ./build.sh test     # the same, then the C++ tests (ctest)

The first build fetches the dependencies and builds Filament from source (about 5 minutes on an M4). Later builds
recompile only what changed. Only one build runs at a time on a machine: `build.sh` takes the lock in
`tools/build_lock.sh` and releases it when it ends. Everything it makes goes to `out/` (not in git).

Once the dependencies exist, CMake can be driven directly: `cmake -S . -B out/cmake -G Ninja && cmake --build out/cmake`.

## Run

    ./edit.sh project.motolii

Builds if needed, opens the project and reads one command per line from standard input (`help` lists them).

## Check and test

- `./check_syntax.sh [path-fragment]` runs `clang++ -fsyntax-only` on every source of ours with CMake's flags. It builds
  nothing, writes nothing and takes no lock. It prints clang's errors, or `ok: <count> sources`.
- `./build.sh test` runs ctest. CMake collects every `<name>_test.cpp` beside the code it tests into one GoogleTest
  binary, but the tree has no `*_test.cpp` file yet, so no C++ test exists today.
- `./drawings_unchanged.sh <old-commit>` draws every shelf recipe and motion with the engine at that commit and with this
  one, and compares the pictures byte by byte. How tests are run, and what counts as passing, is in
  [`../docs/TESTING.md`](../docs/TESTING.md).

## Editor setup

CMake writes `out/cmake/compile_commands.json` (`CMAKE_EXPORT_COMPILE_COMMANDS`) when it configures, which `./build.sh`
does. There is no `.clangd` file; point clangd at it with `--compile-commands-dir=<this folder>/out/cmake`.

## Layout

| Folder | Responsibility |
|---|---|
| `entry/` | The public surface. `motolii.h` is the whole C API; `render_thread.h` owns the render thread that holds the project and the GPU; `calls*.h` are the API calls grouped by purpose (find, map, sound, files, time); `edit.cpp` is the shell. |
| `base/` | Small helpers used everywhere. `json.h` is the single entry point to rapidjson. |
| `document/` | The project, stored in SQLite. `doc.h` is the one include for the whole module; `document.h` defines `Doc`, the open project, as one member for each part, each part a struct in the header that owns it; `kinds.h` lists the kinds of layer and the named values; `undo.h` keeps the change tables and undo; `values.h`, `cards.h` and `marks.h` hold layer values and keys; `match.h` matches items. |
| `document/edit/` | Changes to the project: layers, keys, easings, effects, parents, relations, arrangement and time (`layer_edit.h`, `keys_put.h`, `fx_put.h`). |
| `document/evaluate/` | Computing what a project shows at a given time: values between keys, effect lists, camera, world and materials (`evaluate.h`, `value_at.h`, `world.h`). |
| `document/scripts/` | Reading the shelves into the project: recipes, expressions and scripts, the adapter to posted code, and the shelf folder lists (`recipes.h`, `scripts.h`, `folders.h`). |
| `shelf/` | Where the shelf folders are: the library's and the user's, and a count of changed files (`shelf_folders.h`). |
| `stage/` | Drawing. `live.h` hands frames to the app. |
| `stage/render/` | Drawing with Filament: engine, camera, lights, layers, glTF models and point clouds (`render.h`, `gltf_model.h`, `point_cloud.h`). |
| `stage/canvas/` | 2D art drawn with ThorVG and placed in the preview as a plane, plus path operations (`canvas.h`, `thorvg_path_operators.cpp`, `skia_path_operations.cpp`). |
| `stage/effects/` | Effects over the whole screen, as one WGSL or ISF file each, and Filament viewer settings (`screen_fx.h`, `viewer_settings.h`). |
| `stage/layer_effects/` | A layer's own effect stack: the layer is drawn alone, then its effects run in order, AviUtl2 scripts among them (`layer_fx.h`). It sits above `community/aviutl/`, which itself uses `stage/effects/`. |
| `preview/` | Putting a project on the stage: the playback cache (`playback_cache.h`). |
| `media/` | Everything read through GStreamer: video (`video_layer.h`, `video_datamosh.h`, `video_flash_check.h`), sound (`sound_level.h`, `sound_playback.h`), MIDI (`midi_notes.h`, `midi_roll.h`) and `gstreamer_file_source.h`. |
| `motion/` | Motion: easing (`easing_curves.h`, `easing_names.h`, `easing_godot.h`) and Lottie motion solved by ThorVG (`lottie_motion.h`). |
| `physics/` | Physics through Jolt (`physics.h`, `jolt.cpp`). |
| `materials/` | Filament materials (`.mat`) and the `.glsl` they include, compiled by `materials/build.sh` with Filament's `matc`. |
| `gpu/` | Our code inside Filament's WebGPU (Dawn) backend: the interop files, built within Filament's own build by `gpu/CMakeLists.txt`, and `thorvg_on_dawn.cpp`. |
| `community/` | Adapters that run code from the net unchanged (table below). |
| `deps/` | Scripts that fetch third-party code, and `deps/patches/` (see below). |
| `tools/` | Our own build helper: `build_lock.sh`. |
| `third_party/` | Fetched libraries (not in git) and a few small bundled works (in git). |
| `out/` | Build output (not in git). |

Each folder under `community/` runs code from one outside tool or site, as it is posted.

| Folder | Runs |
|---|---|
| `quickjs/` | The groundwork the adapters below build on: a script's parameters and copies as types, its header of AviUtl2-style or leva-style parameters, shelf files, and anime.js's easings on QuickJS-ng (`script.h`). It includes no other adapter. |
| `script_runner/` | The JavaScript of the shelves (recipes, expressions, relations, sketches) on QuickJS-ng, in whichever dialect it is written (`script_runner.h`), and the parameters of a script of any dialect (`script_parameters.h`). It sits above the adapters it hands the code to. |
| `after_effects/` | After Effects expressions (`ae_expr.h`) and the slots of Lottie files exported from After Effects (`lottie_slots.h`). |
| `p5/` | p5.js sketches in p5.js itself, and sketches that paint with `shader()` as ISF (`adapter_p5_shader.h`). |
| `three/` | three.js: solid shapes (`solid_three.h`) and screen effects turned into ISF (`three_isf.h`). |
| `isf/` | ISF effects (`.fs`), translated to WGSL with glslang and Tint. Every shader entry ends here. |
| `hydra/` | Hydra code, turned into GLSL by Hydra itself, then run as an ISF effect. |
| `playcanvas/` | PlayCanvas Gaussian-splat effects (`splatfx.h`). |
| `sites/` | Code in the form it was posted on Dwitter, tixy.land, Turtletoy, Shadertoy, GLSL Sandbox or OpenProcessing: recognised and handed to one of the above (`adapter.h`). |
| `aviutl/` | AviUtl2 scripts, Lua and HLSL (`aviutl.h`). |
| `absent_motion/` | AbsentMotion motion and text effects (`absent_motion.h`). |
| `three_shading_language_to_shelf/` | Not C++: Node tools that fetch three.js Shading Language works, convert them to WGSL with three.js and write them as files under `../shelves/effects/`. Not part of the build. |

## Third-party code

- **Fetched libraries** (Filament, ThorVG, Skia, Jolt, libtess2, curve_fit_nd, IRIS, AbsentMotion and others): one script
  each under `deps/`, pinned to a commit. Each script fetches into `third_party/` and builds with the library's own build
  system. They are not in git and not built by our CMake.
- **Changes to them** are patches in `deps/patches/<library>/`, one folder per patched library, applied on top of the fetched source.
  Nothing in `third_party/` is edited by hand.
- **Small bundled works** (`anime/`, `godot_easing/`, `js/`, `leva/`, `midi_roll/`, `qdtsne/`, `rapidfuzz/`, `scipy_lsap/`,
  `thermion_frame/`, `ymm4-luascript/` and the data folders `wordnet_ja/`, `noto_sans_jp/`, `gflanguages/`) are in git, with
  their licence files. `.gitignore` in this folder lists exactly which ones.
- Licences of everything are listed in [`../THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

Two kinds of boundary with other people's code, each confined to a few files so that a change on the other side is fixed
in one place. An **interop** reaches into Filament's or Dawn's private internals: only `gpu/*_interop.*`. An **adapter**
runs code from the net unchanged: only `community/sites/adapter*.h`, `community/p5/adapter_p5_shader.h` and
`document/scripts/adapter.h`.

## Conventions

- [Google C++ Style Guide](https://google.github.io/styleguide/cppguide.html), formatted with the root `.clang-format`.
- Every header is self-contained, has an include guard named `MOTOLII_<PATH>_<NAME>_H_`
  (`MOTOLII_DOCUMENT_DOC_H_` for `document/doc.h`), and has its source file beside it.
- Functions of the document module start with `doc_`; the file names do not repeat it.
- Tests are `<name>_test.cpp` beside the code, written with GoogleTest.
