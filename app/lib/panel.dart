export 'bridge/engine_paths.dart'; // Where the engine, the shelves and the project to open are on disk
export 'bridge/motolii.dart'; // What a panel is made of, in one import. This line: the document, read and written (docs/app/BRIDGE.md)
export 'skin/hex_color.dart'; // colorOfHex: a colour as the project writes it, rrggbb or rrggbbaa
export 'skin/tokens.dart'; // the look: T (text), Grey, Role, Shape (sizes), Mo (motion). A panel writes no number of its own
export 'widgets/controls.dart'; // Hov (the one press), IconPress, Badge, Chip and ChipLook, Segmented
export 'widgets/number_field.dart' show NumberField; // a number: scrubbed, typed, wheeled; it never limits what is typed
export 'widgets/text_gestures.dart' show TypedField; // a word typed, said once
export 'widgets/media.dart' show MiniSlider, glyph; // a slider of one or two handles; a picture drawn by a function
export 'widgets/glyphs.dart' show Glyph, GlyphKind, G; // a mark by its name; a skin's SVG of that name wins
export 'widgets/two_fingers.dart'; // a trackpad's two fingers and the wheel
export 'workspace/state/workspace_state.dart' show Ws; // the window's state
export 'workspace/state/workspace_aspect.dart' show WsAspect; // the part of the state a widget listens to
export 'workspace/state/layer.dart' show WsLayer; // a layer as the window lists it
export 'workspace/state/workspace_scope.dart' show WsScope; // how a widget reaches the window's state
export 'widgets/panel_header.dart' show WsHeader; // a panel's header
export 'skin/window_tokens.dart' show WsT; // the window's sizes and colours
export 'workspace/state/pane.dart' show WsPane, WsAt; // a tab: its name, its mark, its body, where it starts
export 'workspace/workspace.dart' show Workspace, LayerCards; // the window; a layer's cards as the engine declares them
export 'widgets/menu.dart' show WsMenu, WsMenuItem; // a right-click menu
export 'workspace/shelf/shelf_tile.dart' show ShelfTile, ShelfGrid; // a tile and a grid of tiles
export 'storage/kept_file.dart' show fileKeep, fileJson, fileList; // a small file the window keeps
