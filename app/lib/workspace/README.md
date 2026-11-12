# Workspace

The app's window and its panels. `Workspace` (`workspace.dart`) is opened by `app/lib/main.dart`. The project lives in the C++ engine, reached through `Motolii` (`../bridge/motolii.dart`), where each method is one `motolii_*` C call. The engine (Filament) draws the Stage picture. This folder shows the project and hands every edit back to the engine. Opening it without a project opens an untitled one.

| Path | What it holds |
|---|---|
| `workspace.dart` | The whole window (`Workspace`): top bar, panes, opening a project. |
| `state/` | State every panel reads: `workspace_controller.dart` (`WorkspaceController`), `workspace_scope.dart` (`WorkspaceScope`), `workspace_aspect.dart` (`WorkspaceAspect`, the part of the state a widget listens to), `layer.dart` (`Layer`, and `layerKindColor`, the color of each layer kind), `pane.dart` (`Pane`, a tab), `art_scene.dart` (`ArtGeometry`, `ArtScene`: sizes and boxes of the Stage picture), `beats.dart` (tempo grid), `window_zoom.dart` (`WindowZoom`). |
| `easing/` | Easing itself: `ease.dart` (`Ease` and presets), `ease_text.dart` (the text written into a document), `ease_curve.dart` (curve and formula of stacked cards). |
| `window/` | The window frame: `panes.dart` (pane layout, built on the pub package `docking`), `home.dart` (first screen, choose a project), `zoom.dart` (draws the whole window at the zoom factor). |
| `top_bar/` | The top bar: `top_bar.dart`, `size_chip.dart`, `zoom_readout.dart`, `timings.dart` (time the engine took). |
| `commands/` | Named commands with their keys and menus: `keymap.dart` (key table in the shape of VS Code's keybindings.json), `command_actions.dart`, `panel_requests.dart` (one panel asking another), `menu_bar.dart` (the commands by name), `menu_items.dart` (the menu bar built from them), `layer_menu.dart` (right-click items; menu widgets are in `widgets/context_menu.dart`). |
| `edits/` | Edits applied to several selected layers: `make_relation.dart`, `group_moves.dart`, `keyframe_edits.dart`. |
| `inspector_feed/` | What the project hands to the Inspector (`../inspector/`): `panel.dart`, `cards.dart`, `values.dart`, `keyframe_marks.dart`. |
| `dock/` | The shelf panels on the left. `shelf_pane.dart` (`ShelfPane`) is one pane: header, search field and the shelf's body. One folder per shelf: `create/`, `effects/`, `media/`, `fonts/`, `colors/`. In each, `*_shelf.dart` is the widget, `*_controller.dart` what the shelf keeps while the window is open, and `*_commands.dart` its calls to the engine. `map/` shows a shelf as a map of similar items (Effects, Fonts); `common/` holds the widgets the shelves share (footer, section header, filter chips, search field). |
| `code/` | The Code tab beside the Timeline: `code_pane.dart` (`CodePane`) shows the selected layer's code, one cell for each card that has code (the card's own code, `shelf/effect_code.dart`). |
| `agent/` | The Agent pane: any agent of the ACP registry (`agent_registry.dart`), talked to through the pub packages `acpd`/`acpd_io` (`acp_chat_session.dart`), drawn with the app's own parts and replies laid out by `flutter_markdown_plus` (`agent_pane.dart`). It works in the own folder, where the code a layer runs is kept. A request carries the selected layer: its Inspector cards and values, its code files and the expression reference (`layer_code.dart`). Requests are written in a message box laid out as the Claude app's, on naked_ui's NakedTextField, with the agent's own settings (model, effort, mode; `agent_settings.dart`), its context use and usage limit (`agent_composer.dart`). The magpie, Motolii's mascot, is the agent's face (`magpie.dart`). |
| `shelf/` | Tiles shown in shelves (effects, scripts, materials). |
| `stage/` | The preview: the engine's picture and the drags on top of it. |
| `timeline/` | The timeline. |
| `tool_panel/` | The tool panel under the Inspector (Ease, Align, Blend and others). |

## Add a panel of your own

Use `Workspace`, `Pane` (`state/pane.dart`; its mark is a `GlyphKind` such as `AppGlyphs`, or null), `WorkspaceController` and `WorkspaceScope` (`state/`), and `Motolii` (`../bridge/motolii.dart`).

```dart
Workspace(document: path, extra: [
  Pane('Notes', null, () => const MyNotes()),   // (name, mark (null shows the first letter), body)
])
```

- The panel appears as a tab beside the Inspector. No existing file changes.
- Inside the panel, `WorkspaceScope.of(context)` returns the `WorkspaceController`. It rebuilds on every change. To rebuild only when one part changes, name it: `WorkspaceScope.of(context, {WorkspaceAspect.picked})`. The playhead is read with `WorkspaceScope.frameOf(context)`.
- `inside` is the project (`Motolii`), `selected` is the selected layer, and `frame` is the current frame. Read a value with `inside.value(thing, name, seconds)`, change it with `inside.set(...)`.
- To move a layer on the preview in pixels: `inside.take(t)`, `inside.dragUpdate('place', 10, 0)`, then `inside.later('drag_end', number: 1)` (one undo, like a real drag). `inside.keyTimes(t, name).length` is the number of keys.
- Four things to remember: `selected` is a string, so `int.parse` it before calling the engine. The current time in seconds is `frame / WorkspaceController.fps`. A layer's name is `inside.word(t, 'name')`. After changing the project, call `ws.reread()` so the other panels read it again.

## Add a tool to the tool panel

```dart
Workspace(document: path, extra: [
  Pane('Snap', null, MySnap.new, at: PaneStrip.catalog, tone: Color(0xFF55AA88), acts: 'Picked thing'),
  // (name, mark, body, where it goes = the tool shelf, color, what it works on)
])
```

The tool is listed after the app's own tools. Choosing it makes the tool panel show its `build`. Its mark is the first letter. It reads state with `WorkspaceScope.of(context)` like any panel.

## Add an Ease preset

Presets belong to the user, like scripts. A file in `ease/` of the user folder (below) appears as a tile in the Ease tool panel in every project. The bundled examples are in `shelves/ease/`. A formula can use `a` (value at the previous key), `b` (value at the next key), `u` (0 to 1 across the span), `p1` to `p4` (numbers set on the span) and `bezier(u, x1, y1, x2, y2)`.

```
// Snappy: fast away from the first key, a long soft landing          (line 1: name, then a description after the colon)
a + (b - a) * bezier(u, .2, 0, 0, 1)
```

Applying a preset to a key writes its formula into the project, so the project behaves the same when handed to someone else. Applying and writing are one undo. Example: `shelves/ease/snappy.way`.

## The user folder

On Mac it is `~/Library/Application Support/Motolii/`; on Windows `%APPDATA%\Motolii\`. `MOTOLII_OWN` replaces it. What is put in a folder here shows up at once. The bundled examples are in the folder of the same name under `shelves/`; the user's file wins when names match.

- `create/*.js`: scripts that make a picture. They appear as tiles in the Create shelf, and their parameters appear in the layer's Script card. The header syntax is described at the top of `engine/community/quickjs/script.h` (`// --track@name:label,min,max,start,step`, `--check@`, `--select@`, as in AviUtl2). Examples: `shelves/create/`.
- `relations/*.js`: relations that move many layers at once. They appear as chips on the preview and in the relations tab, and their parameters appear in the relation's Script card. Examples: `shelves/relations/`.
  - A relation is `relate(things, t, k)`. It gets all layers and returns only what it changes. Each item has `i` (original index), `x`, `y`, `z`, `size`, `rotate`, `rotate_x`, `rotate_y`, `opacity`, `w`, `h` and `id`. `near` is how much a layer is covered by the Falloff shape; ordinary relations weaken by it automatically. p5's `noise`, `createVector` and `constrain` are available, and so is `ease`.
  - A fourth argument, `relate(things, t, k, was)`, receives what the previous frame returned as `was[a.i]` (`null` on the first frame). Do not modify `was`. It is called only while Strength is above 0, and the first such frame gets `null`. This form reads `near` itself.
  - A force is `force(things, t, k)`. Each item is one particle: `x`, `y`, `z` is where it is, `vx`, `vy`, `vz` its speed per frame, `home` where it would rest. Add to the speed, as in d3-force. All forces on a layer add to the same speed, are scaled by Strength and Falloff, and the particle moves once at the end, so speed carries over when rules change. Values written on a particle (`a.n = ...`) stay for the next frame. With `d3.` at the top, `d3.forceCollide` and the other d3 forces are available. A particle no force pushes returns to its home.
  - A file added or changed takes effect without a restart.
- `effects/*.wgsl`: whole-picture effects (Effects shelf). `expressions/*.js`: motion attached to things (Create, Expression).
- `ease/*.way`: Ease presets (above).
- `skins/<name>/`: skins; see `shelves/skins/README.md`.
- The folders `recipes/`, `animators/` and `ways/` are still read (`engine/document/scripts/folders.h`).

## Look

- Take values from `WindowTokens` (`lib/skin/window_tokens.dart`), `InspectorSkin` (`lib/skin/inspector_tokens.dart`), and `Grey` and `TextStyles` (`lib/skin/tokens.dart`). Do not write numbers in place.
- Boxes (panels, cards) are square and sit edge to edge, with a dark line (`WindowTokens.gutter`) between. Things you touch or read (fields, chips, buttons) are round.
- Colors are flat and opaque. The accent is one lime. Paint fills with `WindowTokens.accent` or `InspectorSkin.accent`; draw lines and text on a background with `accentInk`, because lime melts into white in Light. The playhead line is `accentInk`, its head is `accent`.
- Each layer kind has one color (`layerKindColor`), the same in the timeline bar, the shelves and the Stage. Kind colors do not change with the theme.
- The half-circle button in the top bar (key `ws-shade`) switches Dark and Light. It flips `Grey.shade` and calls `reassembleApplication()`, so state, and any edit in progress, stays.
- Take grays as `Grey.g07` and so on. `DarkGrey` is a fixed dark scale and does not follow the theme. A color that changes with the theme cannot be `const`: use a getter, or `Color?` with `?? Grey.xx`, because a `final` keeps the first color.

## Behavior rules

- Media and Files are one shelf, Media: a tree of places (Project, Home, Desktop, Downloads) and folders on the left (above when narrow), the open folder as thumbnails or a list on the right. Search covers everything under the current place and shows the folder name of each hit.
- Shelf tabs show a mark only; Stage, Inspector, Timeline and Tool Panel show a mark and a name.
- Panes use extra width: grids choose their column count with `gridColumns(width, cell width)` and `gridCellWidth`; lists of groups use `ShelfMasonry` (one column is 260 to 300 px or more, up to 4). The Inspector stays one column of cards.
- Do not hide rarely used values such as a seed: declare them `@advanced` and `ValuesCard` folds them.
- Path operations can be stacked any number of times; the UI does not limit them.
- The Effects list has no thumbnails. Select a row to try it on the selected layer, Add or Enter to keep it, Cancel or Esc to undo.
- The Inspector shows current values and links to the panel that edits them (`LinkLine`): fonts, color lists and easing live in their own panels. Position, scale, rotation and fill come from `ArtGeometry.boxOf` so they match the Stage (`InspectorHost(snapshot:)`, an `InspectorSnapshot` of numbers and words).

## Changing this folder

- Information shared between panels goes into `WorkspaceController`. Panels do not import each other. The Stage's sizes and boxes (`ArtGeometry`, `ArtScene`) are in `state/art_scene.dart`, readable from every panel.
