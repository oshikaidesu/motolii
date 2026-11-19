// A shelf shown as a pane of its own: Media, Effects, Fonts, Colors, Create or Looks.
// It has a header, a search field and a body. Each shelf is one tab of the window's panes.
// Media is the one file browser, for the project and the disk (media/media_shelf.dart).
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/media.dart' show MiniSlider;
import 'package:motolii/widgets/controls.dart' show IconPress;
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/dock/colors/color_palette.dart';
import 'package:motolii/workspace/dock/colors/colors_controller.dart';
import 'package:motolii/workspace/dock/colors/colors_shelf.dart';
import 'package:motolii/workspace/dock/common/shelf_search_field.dart';
import 'package:motolii/workspace/dock/common/shelf_tags.dart';
import 'package:motolii/workspace/dock/create/create_catalog.dart';
import 'package:motolii/workspace/dock/create/create_shelf.dart';
import 'package:motolii/workspace/dock/effects/effects_controller.dart';
import 'package:motolii/workspace/dock/effects/effects_shelf.dart';
import 'package:motolii/workspace/dock/fonts/fonts_controller.dart';
import 'package:motolii/workspace/dock/fonts/fonts_shelf.dart';
import 'package:motolii/workspace/dock/looks/looks_shelf.dart';
import 'package:motolii/workspace/dock/media/media_controller.dart';
import 'package:motolii/workspace/dock/media/media_shelf.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';
import 'package:motolii/workspace/state/tiles/effect_tiles_service.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// One shelf pane. [name] picks which shelf it is and [hint] is the search field's placeholder.
class ShelfPane extends StatefulWidget {
  const ShelfPane(this.name, this.hint, {super.key});
  final String name, hint;
  @override
  State<ShelfPane> createState() => _ShelfPaneState();
}

class _ShelfPaneState extends State<ShelfPane> {
  // What the shelf remembers of itself (selection, folds, search). It lives in the window's view,
  // so the shelf looks the same when it is opened again.
  ShelfMemory get _mem =>
      WorkspaceScope.read(context).view
              .putIfAbsent('dock.${widget.name}', ShelfMemory.new)
          as ShelfMemory;

  /// What a shelf keeps between builds besides its memory: made by [make] the first time it is asked for, then kept
  /// in the window's view under [name], so it is still there when the pane is opened again.
  T _kept<T extends Object>(String name, T Function() make) =>
      WorkspaceScope.read(context).view.putIfAbsent('dock.$name', make) as T;

  /// Goes up each time a shelf has read something from the disk off the UI thread, so the shelves look again.
  ValueNotifier<int> get _reads => _kept('reads', () => ValueNotifier<int>(0));

  /// The tags of the shelves' items and the words searches are completed from, shared by the window's shelves.
  ShelfTags get _tags => _kept('tags', () => ShelfTags.shared);

  // What each shelf keeps between builds. What a controller is given is fetched before it is made, because making
  // one must not add to the view while the view is looking its key up.
  MediaController get _media {
    final ws = WorkspaceScope.read(context), reads = _reads, tags = _tags;
    return _kept('Media.controller', () => MediaController(ws, reads, tags));
  }

  ColorsController get _colors =>
      _kept('Colors.controller', ColorsController.new);
  EffectsController get _effects {
    final tags = _tags;
    return _kept('Effects.controller', () => EffectsController(tags));
  }

  FontsController get _fonts {
    final reads = _reads, tags = _tags;
    return _kept('Fonts.controller', () => FontsController(reads, tags));
  }

  late final TextEditingController _search =
      TextEditingController(
        text: WorkspaceScope.read(context)
            .viewOf('dock.${widget.name}.search', ''),
      )..addListener(
        () => setState(
          () =>
              WorkspaceScope.read(context).view['dock.${widget.name}.search'] =
                  _search.text,
        ),
      );

  // The shelf follows the document one frame after the render thread. After a change, the inspector and the canvas
  // build in that frame and the shelf in the next, once for all the changes since. Building them together
  // was half of each frame's work.
  WorkspaceController? _ws;
  bool _due = false;
  Object? _seen;
  // A new revision of the document is checked for the part this shelf shows. For example, a number
  // the user has finished dragging changes no effects, motion or layers, so the shelf is not rebuilt for it.
  int? _rev;
  Object? _shows;
  Object _showing(WorkspaceController ws) => switch (widget.name) {
    'Effects' => (
      ws.screenFx.join(' '),
      ws.motion,
      ws.fxOf(ws.selected).join(' '),
    ),
    'Create' => ws.layers.map((l) => '${l.id} ${l.name}').join(' '),
    _ => ws.reads,
  };
  void _later() {
    final ws = _ws!;
    if (ws.reads != _rev) {
      _rev = ws.reads;
      final shows = _showing(ws);
      if (shows != _shows) {
        _shows = shows;
        _seen = null;
      }
    }
    // What the shelf shows of the window: its part of the document, and the selection.
    final now = (_shows, ws.selected);
    if (_due || now == _seen) return;
    _seen = now;
    _due = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _due = false;
        // Rebuilds in the next frame, on its own.
        if (mounted) setState(() {});
      })
      ..ensureVisualUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WorkspaceScope.read(context);
    if (ws != _ws) {
      for (final a in const [WorkspaceAspect.layers, WorkspaceAspect.picked]) {
        _ws?.on[a]!.removeListener(_later);
        ws.on[a]!.addListener(_later);
      }
      _ws = ws;
    }
  }

  @override
  void dispose() {
    for (final a in const [WorkspaceAspect.layers, WorkspaceAspect.picked]) {
      _ws?.on[a]!.removeListener(_later);
    }
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.read(context), name = widget.name;
    final c = ShelfContext(
      name,
      _mem,
      _search.text.trim(),
      ws,
      setState,
      _search.clear,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelHeader(
          name,
          trailing: [
            if (name == 'Media') ...[
              IconPress(
                dockMark(AppGlyphs.grid),
                tip: 'Grid view',
                on: !_mem.mediaList,
                onTap: () => setState(() => _mem.mediaList = false),
              ),
              IconPress(
                dockMark(AppGlyphs.list),
                tip: 'List view',
                on: _mem.mediaList,
                onTap: () => setState(() => _mem.mediaList = true),
              ),
              IconPress(
                dockMark(AppGlyphs.folder),
                tip: 'Show subfolders',
                on: _mem.mediaDeep,
                onTap: () => setState(() => _mem.mediaDeep = !_mem.mediaDeep),
              ),
              IconPress(
                dockMark(AppGlyphs.files),
                tip: 'Folder tree',
                on: _mem.treeSide != 0,
                onTap: () =>
                    setState(() => _mem.treeSide = (_mem.treeSide + 1) % 3),
              ),
            ] else ...[
              if (name == 'Colors') ...[
                IconPress(
                  dockMark(AppGlyphs.grid),
                  tip: 'Grid view',
                  key: const ValueKey('ws-colors-grid'),
                  on: _mem.colorGrid,
                  onTap: () => setState(() => _mem.colorGrid = true),
                ),
                IconPress(
                  dockMark(AppGlyphs.particles),
                  tip: 'Bento view',
                  key: const ValueKey('ws-colors-bento'),
                  on: !_mem.colorGrid,
                  onTap: () => setState(() => _mem.colorGrid = false),
                ),
              ],
              if (name == 'Effects' || name == 'Fonts') ...[
                // Shows the items as rows or as a map with similar items close together, like XO's Space beside its list (map/shelf_map.dart).
                IconPress(
                  dockMark(AppGlyphs.grid),
                  tip: 'Grid view',
                  key: ValueKey('ws-$name-rows'),
                  on: !_mem.mapped.contains(name),
                  onTap: () => setState(() => _mem.mapped.remove(name)),
                ),
                IconPress(
                  dockMark(AppGlyphs.particles),
                  tip: 'Map view',
                  key: ValueKey('ws-$name-map'),
                  on: _mem.mapped.contains(name),
                  onTap: () => setState(() => _mem.mapped.add(name)),
                ),
              ],
              // Lit while tiles are being drawn. A click draws the selected tile again, or all of them when none is selected.
              if (name == 'Effects') ...[
                ListenableBuilder(
                  listenable: EffectTiles.progress,
                  builder: (context, _) => IconPress(
                    dockMark(AppGlyphs.reload),
                    tip: 'Redraw tiles',
                    key: const ValueKey('ws-fx-reload'),
                    on: EffectTiles.progress.value != null,
                    onTap: effectTilesAgain(ws, file: c.sel),
                  ),
                ),
                SizedBox(width: Shape.s(6)),
                SizedBox(
                  width: Shape.z(48),
                  child: MiniSlider(
                    key: const ValueKey('ws-fx-tile-size'),
                    values: [_mem.fxTileSize],
                    min: 50,
                    max: 140,
                    width: Shape.z(48),
                    onChanged: (v) {
                      final stepped = (v.first / 10).roundToDouble() * 10;
                      if (stepped != _mem.fxTileSize) {
                        setState(() => _mem.fxTileSize = stepped);
                      }
                    },
                  ),
                ),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Shape.z(88)),
                child: ListenableBuilder(
                  listenable: Listenable.merge([_reads, EffectTiles.progress]),
                  builder: (context, _) => Text(
                    switch (name) {
                      // What the engine offers: its fonts and effects, the colors the document uses, and the tile drawing progress.
                      'Fonts' => '${_fonts.offered ?? '…'} fonts',
                      'Effects' => switch (EffectTiles.progress.value) {
                        (final done, final all) => '$done of $all',
                        null => '${readyEffectCount(ws)} ready',
                      },
                      'Colors' =>
                        '${usedColors(ws).values.toSet().length} used here',
                      'Create' => createFact(ws),
                      'Looks' => '0',
                      _ => '',
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.label(Grey.g56),
                  ),
                ),
              ),
            ],
          ],
        ),
        ShelfSearchField(controller: _search, hint: widget.hint),
        Builder(
          builder: (context) {
            // Completions of the word being typed, from the tags the shelf has. A click takes one.
            final done = _tags.completing(name, _search.text);
            if (done.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: WindowTokens.inset,
                vertical: Shape.s(3),
              ),
              child: SingleChildScrollView(
                // All of them in one line that scrolls sideways, as the chips row does (BaseControls.chips).
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final t in done) ...[
                      if (t != done.first) SizedBox(width: Shape.s(4)),
                      DockHover(
                        onTap: () {
                          final text = ShelfTags.complete(_search.text, t);
                          _search.value = TextEditingValue(
                            text: text,
                            selection: TextSelection.collapsed(
                              offset: text.length,
                            ),
                          );
                        },
                        builder: (context, h) => Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: Shape.s(7),
                            vertical: Shape.s(2),
                          ),
                          decoration: BoxDecoration(
                            color: h ? WindowTokens.raised : WindowTokens.well,
                            borderRadius: Shape.round(WindowTokens.chipRadius),
                          ),
                          child: Text(t, style: TextStyles.micro(Grey.g91)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        Expanded(
          child: ListenableBuilder(
            // A footer waiting for a second click opens once that click can no longer come (ShelfContext.foot).
            listenable: DockHover.secondMayCome,
            builder: (context, _) => AnimatedSwitcher(
              duration: Motion.dur,
              child: KeyedSubtree(
                key: ValueKey(name),
                child: switch (name) {
                  'Effects' => EffectsShelf(c, _effects),
                  'Fonts' => FontsShelf(c, _fonts),
                  'Colors' => ColorsShelf(c, _colors),
                  'Create' => CreateShelf(c),
                  'Looks' => LooksShelf(c),
                  _ => MediaShelf(c, _media),
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
