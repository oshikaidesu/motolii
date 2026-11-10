// A shelf shown as a pane of its own: Media, Effects, Fonts, Colors, Create, Program or Presets.
// It has a header, a search field and a body. Each shelf is one tab of the window's panes.
// Media is the one file browser, for the project and the disk (dock_files.dart).
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import 'dock_effects.dart';
import 'dock_files.dart';
import 'dock_fonts.dart';
import 'dock_glyphs.dart';
import 'dock_make.dart';
import 'dock_widgets.dart';
import 'dock_tags.dart';
import 'dock_program.dart';
import '../shelf/effect_tiles.dart';
import '../state/state.dart';

/// One shelf pane. [name] picks which shelf it is and [hint] is the search field's placeholder.
class WsShelf extends StatefulWidget {
  const WsShelf(this.name, this.hint, {super.key});
  final String name, hint;
  @override
  State<WsShelf> createState() => _WsShelfState();
}

class _WsShelfState extends State<WsShelf> {
  // What the shelf remembers of itself (selection, folds, search). It lives in the window's view,
  // so the shelf looks the same when it is opened again.
  DockMem get _mem => WsScope.read(context).view.putIfAbsent('dock.${widget.name}', DockMem.new) as DockMem;
  late final TextEditingController _search = TextEditingController(text: WsScope.read(context).viewOf('dock.${widget.name}.search', ''))
    ..addListener(() => setState(() => WsScope.read(context).view['dock.${widget.name}.search'] = _search.text));

  // The shelf follows the document one frame after the render thread. After a change, the inspector and the canvas
  // build in that frame and the shelf in the next, once for all the changes since. Building them together
  // was half of each frame's work.
  Ws? _ws;
  bool _due = false;
  Object? _seen;
  // A new revision of the document is checked for the part this shelf shows. For example, a number
  // the user has finished dragging changes no effects, motion or layers, so the shelf is not rebuilt for it.
  int? _rev;
  Object? _shows;
  Object _showing(Ws ws) => switch (widget.name) {
    'Effects' => (ws.screenFx.join(' '), ws.motion, ws.fxOf(ws.selected).join(' ')),
    'Create' => ws.layers.map((l) => '${l.id} ${l.name}').join(' '),
    _ => ws.rev,
  };
  void _later() {
    final ws = _ws!;
    if (ws.rev != _rev) {
      _rev = ws.rev;
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
    final ws = WsScope.read(context);
    if (ws != _ws) {
      for (final a in const [WsAspect.document, WsAspect.picked]) {
        _ws?.on[a]!.removeListener(_later);
        ws.on[a]!.addListener(_later);
      }
      _ws = ws;
    }
  }

  @override
  void dispose() {
    for (final a in const [WsAspect.document, WsAspect.picked]) {
      _ws?.on[a]!.removeListener(_later);
    }
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WsScope.read(context), name = widget.name;
    final c = DockCtx(name, _mem, _search.text.trim(), ws, setState, _search.clear);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WsHeader(
          name,
          trailing: [
            if (name == 'Media') ...[
              IconPress(dockMark(DockG.grid), on: !_mem.mediaList, onTap: () => setState(() => _mem.mediaList = false)),
              IconPress(dockMark(DockG.list), on: _mem.mediaList, onTap: () => setState(() => _mem.mediaList = true)),
              IconPress(
                dockMark(DockG.folder),
                on: _mem.mediaDeep,
                onTap: () => setState(() => _mem.mediaDeep = !_mem.mediaDeep),
              ), // Lists the folders below as well.
              IconPress(
                dockMark(DockG.files),
                on: _mem.treeSide != 0,
                onTap: () => setState(() => _mem.treeSide = (_mem.treeSide + 1) % 3),
              ), // Cycles the folder tree between automatic, left and above.
            ] else if (name == 'Program') ...[
              IconPress(dockMark(DockG.list), on: !_mem.programCode, onTap: () => setState(() => _mem.programCode = false)),
              IconPress(dockMark(DockG.program), on: _mem.programCode, onTap: () => setState(() => _mem.programCode = true)),
            ] else ...[
              if (name == 'Effects' || name == 'Fonts') ...[
                // Shows the items as rows or as a map with similar items close together, like XO's Space beside its list (dock_map.dart).
                IconPress(
                  dockMark(DockG.grid),
                  key: ValueKey('ws-$name-rows'),
                  on: !_mem.mapped.contains(name),
                  onTap: () => setState(() => _mem.mapped.remove(name)),
                ),
                IconPress(
                  dockMark(DockG.particles),
                  key: ValueKey('ws-$name-map'),
                  on: _mem.mapped.contains(name),
                  onTap: () => setState(() => _mem.mapped.add(name)),
                ),
              ],
              // Lit while tiles are being drawn. A click draws the selected tile again, or all of them when none is selected.
              if (name == 'Effects')
                ListenableBuilder(
                  listenable: EffectTiles.progress,
                  builder: (context, _) => IconPress(
                    dockMark(DockG.reload),
                    key: const ValueKey('ws-fx-reload'),
                    on: EffectTiles.progress.value != null,
                    onTap: ws.inside == null ? null : () => EffectTiles.again(ws.inside!, file: c.sel),
                  ),
                ),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: Shape.z(88)),
                child: ListenableBuilder(
                  listenable: Listenable.merge([dockRead, EffectTiles.progress]),
                  builder: (context, _) => Text(
                    switch (name) {
                      // What the engine offers: its fonts and effects, the colors the document uses, and the tile drawing progress.
                      'Fonts' => '${fontsOffered ?? '…'} fonts',
                      'Effects' => switch (EffectTiles.progress.value) {
                        (final done, final all) => '$done of $all',
                        null => '${(ws.inside?.layerEffects.length ?? 0) + (ws.inside?.effects.length ?? 0)} ready',
                      },
                      'Colors' => '${usedColors(ws).values.toSet().length} used here',
                      'Create' => createFact(ws),
                      'Presets' => '0',
                      _ => '',
                    },
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: T.label(Grey.g56),
                  ),
                ),
              ),
            ],
          ],
        ),
        DockSearch(controller: _search, hint: widget.hint),
        Builder(
          builder: (context) {
            // Completions of the word being typed, from the tags the shelf has. A click takes one.
            final done = DockTags.completing(name, _search.text);
            if (done.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: WsT.inset, vertical: Shape.s(3)),
              child: SingleChildScrollView(
                // All of them in one line that scrolls sideways, as the chips row does (Usual.chips).
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final t in done) ...[
                      if (t != done.first) SizedBox(width: Shape.s(4)),
                      DockHover(
                        onTap: () {
                          final text = DockTags.complete(_search.text, t);
                          _search.value = TextEditingValue(
                            text: text,
                            selection: TextSelection.collapsed(offset: text.length),
                          );
                        },
                        builder: (context, h) => Container(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(7), vertical: Shape.s(2)),
                          decoration: BoxDecoration(color: h ? WsT.raised : WsT.well, borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius))),
                          child: Text(t, style: T.micro(Grey.g91)),
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
            // A footer waiting for a second click opens once that click can no longer come (DockCtx.foot).
            listenable: DockHover.secondMayCome,
            builder: (context, _) => switch (name) {
              'Effects' => EffectsShelf(c),
              'Fonts' => FontsShelf(c),
              'Colors' => ColorsShelf(c),
              'Create' => CreateShelf(c),
              'Program' => ProgramShelf(c),
              'Presets' => Padding(
                padding: EdgeInsets.all(Shape.s(24)),
                child: Text('No presets yet', textAlign: TextAlign.center, style: T.label(Grey.g63)),
              ),
              _ => MediaShelf(c),
            },
          ),
        ),
      ],
    );
  }
}
