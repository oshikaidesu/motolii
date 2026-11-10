# Motolii app

The Flutter (macOS) user interface of Motolii. It draws nothing itself and holds no project. Every action is a call into the engine ([`../engine/`](../engine/), built as `libmotolii.dylib`) through `dart:ffi`, and the app shows what comes back.

## Prerequisites

- macOS on Apple silicon.
- Flutter 3.47.2 (pinned in [`.fvmrc`](.fvmrc) and in CI).
- The engine, built first: `../engine/build.sh`. See [`../engine/README.md`](../engine/README.md).

## Run

```
cd app
tool/live.sh
```

`tool/live.sh` opens the app with `flutter run -d macos` and sends a hot reload each time a `.dart` file under `lib/` is saved, so the open window updates with its state kept. The engine's own files (effect `.wgsl`, script `.js`) reload by themselves. The script ends when the window is closed. It takes the machine's build lock (`../engine/tools/build_lock.sh`) until the window is open.

It opens `~/Movies/Motolii/Untitled.motolii`. Set `MOTOLII_DOC=/path/to.motolii` to open another project, and `MOTOLII_DIR` to point at another engine folder.

To build the app without running it: `flutter build macos --profile`.

## Test and check

Run these in `app/`. The full procedure is in [`../docs/TESTING.md`](../docs/TESTING.md).

```
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

`dart analyze lib` is the quick static check. Most tests need no engine; `test/accessibility_guidelines_test.dart` opens the real app and is skipped when `../engine/out/libmotolii.dylib` is missing.

Frame timing needs a window:

```
FLUTTER_TEST_OUTPUTS_DIR=build/test_output flutter drive --profile -d macos \
  --driver=test_driver/frame_timing_driver.dart --target=integration_test/frame_timing_test.dart
```

CI runs the first three commands on every push (`../.github/workflows/checks.yml`).

## Layout

"Shelf" is the name of the tabs on the left (Create, Effects, Media, Fonts, Colors). "Skin" is a theme folder that changes colors, sizes, pictures and control shapes.

| Path | What it holds |
|---|---|
| `lib/main.dart` | Starts the app and opens the `Workspace` window. |
| `lib/panel.dart` | The one import for writing a panel (`package:motolii/panel.dart`). It only re-exports the parts of the folders below. |
| `lib/bridge/` | The border to the engine: calls into `libmotolii.dylib` for the project, shelves, questions and writes. `motolii.dart` holds `Motolii`; `motolii_bindings.dart` is generated. See [`../docs/app/BRIDGE.md`](../docs/app/BRIDGE.md). |
| `lib/storage/` | Small files the app keeps: `json_file.dart` (write files, read JSON and lists), `window_settings.dart` (`~/.motolii/window.xml`: zoom and the chosen skin). |
| `lib/skin/` | Look: `tokens.dart` (grays, sizes), `window_tokens.dart`, `inspector_tokens.dart`, `theme.dart` (colors from a skin's `theme.xml`), `skin_parts.dart` (a skin's `parts/*.svg`). |
| `lib/skin/forms/` | How controls are built per skin: `poster_forms.dart`, `sheet_forms.dart`, `lighttable_forms.dart`, `own_forms.dart`, and `base_controls.dart` for controls a skin does not define. |
| `lib/widgets/` | The standard parts every panel is built from: `controls.dart` (`Pressable`, `Chip`), `number_field.dart` (`NumberField`), `text_gestures.dart` (`TypedField`), `media.dart` (`MiniSlider`), `glyphs.dart` (`Glyph`), `timeline_painters.dart`. |
| `lib/inspector/` | The Inspector on the right. Cards come from the engine's declarations (`../engine/document/card_table.h`), and `values_card.dart` (`ValuesCard`) draws every one of them. |
| `lib/inspector/controls/` | Controls per kind of value: number, angle, color, text, link. |
| `lib/inspector/rows/` | Rows and the frame of a card. |
| `lib/workspace/` | The window itself and its panels. `workspace.dart` holds `Workspace`. See [`lib/workspace/README.md`](lib/workspace/README.md). |
| `lib/workspace/state/` | State every panel reads: `workspace_controller.dart` (`WorkspaceController`), `workspace_scope.dart` (`WorkspaceScope`), `pane.dart` (`Pane`). |
| `lib/workspace/easing/` | Easing: `ease.dart` (`Ease` and presets), `ease_text.dart` (the text written into a project). |
| `lib/workspace/edits/` | Edits applied to several selected layers: `make_relation.dart`, `keyframe_edits.dart`. |
| `lib/workspace/commands/` | Named commands with their keys and menus: `keymap.dart`, `menu_bar.dart`. |
| `lib/workspace/inspector_feed/` | What the project hands to the Inspector: `cards.dart`, `values.dart`. |
| `lib/workspace/shelf/` | Tiles shown in shelves (effects, scripts, materials): `shelf_tile.dart`, `effect_tiles.dart`. |
| `lib/workspace/dock/` | The shelf panels on the left. |
| `lib/workspace/stage/` | The preview: the engine's picture and the drags on top of it. |
| `lib/workspace/timeline/` | The timeline. |
| `lib/workspace/tool_panel/` | The tool panel under the Inspector (Ease, Align, Blend, Depth, Relations). |
| `lib/workspace/top_bar/` | The bar at the top: size, zoom readout, engine timings. |
| `lib/workspace/window/` | The window frame: `panes.dart` (pane layout), `home.dart` (project chooser), `zoom.dart`. |
| `test/` | Unit and widget tests, laid out like `lib/` (`inspector/`, `skin/`, `widgets/`, `workspace/`), plus `skin_folders_test.dart` and `accessibility_guidelines_test.dart`. They pin what the code returns now, so a change of value fails them. |
| `integration_test/` | `frame_timing_test.dart`: scrolls the timeline on a real Mac and checks each frame fits about 16 ms. |
| `test_driver/` | The driver that runs `integration_test/` with `flutter drive`. Test output goes to `build/test_output/`. |
| `tool/` | `live.sh` (run with hot reload) and `flicker.py` (finds one-frame flicker in a screen recording; needs ffmpeg). |
| `example/` | `my_panel.dart`: a panel built from the standard alone. The analyzer compiles it, so it breaks when the standard changes. |
| `assets/` | `effect_parameter_weights.json`: how strongly each effect parameter acts. It is read from the repository with `File`, and is not listed in `pubspec.yaml`. |
| `macos/` | The Flutter macOS runner project. |

## Dependency direction

Dependencies run one way: from the panels down to the border to the engine (`bridge/`). A folder does not import one above it.

- A folder may always import itself.
- `export` counts as an import.
- A row includes its subfolders, except that `skin/` does not include `skin/forms/`, and the `.dart` files directly in `workspace/` do not include the folders below them.

| Folder (under `lib/`) | May import |
|---|---|
| `bridge/`, `storage/` | Nothing else in the app. |
| `skin/` (not `forms/`) | `bridge/engine_paths.dart`, `storage/` |
| `widgets/` | `skin/` |
| `skin/forms/` | `skin/`, `widgets/` |
| `inspector/` | `skin/`, `skin/forms/`, `widgets/`. Never `bridge/` or `workspace/`. |
| `workspace/easing/` | `bridge/` |
| `workspace/state/` | `bridge/`, `storage/`, `skin/`, `widgets/glyphs.dart`, `workspace/easing/` |
| `workspace/edits/` | `workspace/state/` and what it may import |
| `workspace/commands/` | `workspace/edits/` and what it may import, `widgets/` |
| `workspace/shelf/` | `workspace/commands/` and what it may import, `skin/forms/`. Never `inspector/`. |
| `workspace/inspector_feed/` | `workspace/shelf/` and what it may import, `inspector/` |
| `workspace/dock/`, `stage/`, `timeline/`, `tool_panel/`, `top_bar/`, `window/` | `workspace/inspector_feed/` and what it may import. These six do not import each other. |
| `workspace/*.dart` (the whole window) | Anything |
| `panel.dart` | Anything; it contains only `export` lines. |
| `main.dart` | `workspace/*.dart` and `bridge/` |

Three rules apply everywhere: do not use `part`; write `export` only in `panel.dart`; import app files as `package:motolii/...` (`always_use_package_imports` in `analysis_options.yaml` enforces this last one).

## Making a panel

1. Write one Dart file. Two imports are enough: `package:flutter/widgets.dart` and `package:motolii/panel.dart`. [`example/my_panel.dart`](example/my_panel.dart) is a working model.
2. To show values only, no Dart is needed: `LayerCards(layer: ..., only: ['Transform'])` draws the cards the engine declares (`../engine/document/card_table.h`). Write your own drawing or controls only where you need them, using the standard parts (`NumberField`, `MiniSlider`, `Chip`, `IconPress`, `Glyph`).
3. Add one line to the `Workspace` in `lib/main.dart`: `Workspace(document: motoliiDoc, extra: const [Pane('Mine', null, MyPanel.new)])`. A `null` mark shows the first letter of the name; pass a `GlyphKind` for your own mark (a skin's SVG of the same name wins).
4. Inside a panel, use the parts in `lib/widgets/` instead of writing your own press handlers (`GestureDetector`), text fields (`EditableText`) or painters (`CustomPainter`). If a part is missing, add it to `lib/widgets/` so every panel can use it.

Example skins are in [`../shelves/skins/`](../shelves/skins/), with how to make one. In the app, `lib/skin/theme.dart` reads colors and sizes from `theme.xml`, `lib/skin/skin_parts.dart` reads `<Parts>` pictures, and `lib/skin/forms/` builds controls for `<Forms>`.

Longer documents are in [`../docs/app/`](../docs/app/): `BRIDGE.md` (calls into the engine), `DESIGN.md` (the sources of the values in `tokens.dart`) and `GESTURES.md` (what presses, drags and keys mean; read it before making a panel).

## Bindings

`lib/bridge/motolii_bindings.dart` is generated by `ffigen` from the engine's C header, `../engine/entry/motolii.h`. Do not edit it by hand. After the header changes, regenerate it in `app/`:

```
dart run ffigen --config ffigen.yaml
```

[`ffigen.yaml`](ffigen.yaml) takes every function named `motolii_*`, marks `motolii_broken_count` as a leaf call, and reads `libclang` from the Xcode toolchain.
