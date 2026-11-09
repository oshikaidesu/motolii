// The Stage panel: header with view controls, the tool column, the viewport (stage_view.dart) and the tool options strip.
// The picture is the work (stage_art.dart); the chrome around it stays grey and round, with the accent only on what is on.
import 'dart:io' show Directory, File;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../skin/forms/forms.dart';
import '../../skin/svg_parts.dart';

import '../../widgets/glyphs.dart';
import '../../skin/tokens.dart';
import 'stage_art.dart';
import 'stage_view.dart';
import '../../widgets/two_fingers.dart';
import '../workspace.dart' show wsPlace;
import '../state/state.dart';

part 'stage_options.dart';

class WsStage extends StatelessWidget {
  const WsStage({super.key});
  @override
  Widget build(BuildContext context) => const WsPanel(child: _Stage());
}

const _tools = [
  (G.select, 'Select', 'V'),
  (G.move, 'Move', 'M'),
  (G.rect, 'Rectangle', 'R'),
  (G.ellipse, 'Ellipse', 'E'),
  (G.pen, 'Pen', 'P'),
  (G.text, 'Text', 'T'),
  (G.brush, 'Brush', 'B'), // (a path drawn by hand, Alight Motion's freehand; B as Photoshop's and After Effects' brush)
  (G.camera, 'Camera', 'C'), // (After Effects' Unified Camera tool, C: a drag turns the camera round where it looks, the wheel brings it nearer)
];

/// The tools as the window's commands (`tool.select`, `tool.text`…), their letters in its keymap (keymap.dart): heard
/// wherever the window has the keys and no words are being typed, as After Effects' and Photoshop's tool letters are,
/// not only while the stage has them (golf_noise.md (78): a document box closed left them to the window, and T was
/// not heard).
Map<String, VoidCallback> wsToolCommands(Ws ws) => {for (final (i, t) in _tools.indexed) 'tool.${t.$2.toLowerCase()}': () => ws.setView('stage.tool', i)};

class _Stage extends StatefulWidget {
  const _Stage();
  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  // (how the stage looks: the window's view, so any pane may read it and the window opened again shows the same)
  Ws get _ws => WsScope.read(context);
  int get _zoom => _ws.viewOf('stage.zoom', 0);
  set _zoom(int v) => _ws.setView('stage.zoom', v);
  int get _tool => _ws.viewOf('stage.tool', 0);
  set _tool(int v) => _ws.setView('stage.tool', v);
  bool get _safe => _ws.viewOf('stage.safe', true);
  set _safe(bool v) => _ws.setView('stage.safe', v);
  bool get _grid => _ws.viewOf('stage.grid', false);
  set _grid(bool v) => _ws.setView('stage.grid', v);
  bool get _camera => _ws.viewOf('stage.camera', false); // (AbsentMotion's cameraView: off till asked, the stage sees the world)
  (Object?, String) _eyeTold = (null, '');

  /// The inside told which eye the stage is seen by, when that has changed (a document opened begins at the world's).
  void _tellEye(Ws ws) {
    final m = ws.inside, word = ws.freeEye ? ws.eye.join(' ') : '';
    if (m == null || _eyeTold == (m, word)) return;
    _eyeTold = (m, word);
    m.later('view_camera', word: word);
  }

  set _camera(bool v) => _ws.setView('stage.camera', v);
  Map<String, int> get _opts => _ws.view.putIfAbsent('stage.options', () => <String, int>{}) as Map<String, int>;
  final _cursor = ValueNotifier<Offset?>(null);
  final _focus = FocusNode(debugLabel: 'stage');
  final _view = GlobalKey(); // (the view: what is under a tile let go over it)
  String? _shot; // (the picture as it was when taken: a still among the system's temporary files)
  bool _showing = false;

  @override
  void dispose() {
    _cursor.dispose();
    _focus.dispose();
    _forget();
    super.dispose();
  }

  /// After Effects' Take Snapshot: the picture at the playhead kept as a still (the inside's Export Frame), to be seen
  /// again over the picture while Show Snapshot is held: an earlier look against the one now, nothing undone (P19).
  void _take() {
    final m = _ws.inside;
    if (m == null) return;
    final png = '${Directory.systemTemp.path}/motolii_snapshot_${DateTime.now().microsecondsSinceEpoch}.png'; // (a new name each time: Flutter's image cache knows a file by its name)
    if (!m.still(png)) {
      _ws.notice = 'No snapshot: ${m.error}';
      return;
    }
    _forget();
    setState(() => _shot = png);
  }

  void _forget() {
    try {
      if (_shot case final was?) File(was).deleteSync();
    } catch (_) {} // (gone already)
  }

  @override
  Widget build(BuildContext context) {
    WsScope.frameOf(context); // (the scene is at the playhead)
    WsScope.pictureOf(context); // (and as the picture shown has it)
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked, WsAspect.stage, WsAspect.view}),
        scene = Ws.timed('stage scene', () => ArtScene.of(ws, camera: !ws.freeEye));
    _tellEye(ws);
    return DragTarget<VoidCallback>(
      // (a tile of a shelf dropped here does what its double press does: Ableton's drop of a device on a track)
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) {
        // (on the thing it is let go over, as After Effects takes an effect dragged to a layer in
        //  the Composition panel; over none, on the picked thing as a double press puts it)
        if ((_view.currentState as StageHandles?)?.hitAt(d.offset) case final id?) ws.select(id);
        d.data();
      },
      builder: (context, hot, _) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: hot.isEmpty ? null : Border.all(color: WsT.accent, width: 2)),
        child: Focus(
          focusNode: _focus,
          child: Column(
            children: [
              WsHeader(
                '',
                trailing: [
                  _Seg(items: stageZooms, index: _zoom, onChanged: (i) => setState(() => _zoom = i)),
                  SizedBox(width: Shape.s(6)),
                  _Toggle(label: 'Safe', icon: _Icon.safe, on: _safe, onTap: () => setState(() => _safe = !_safe)),
                  SizedBox(width: WsT.gap),
                  _Toggle(label: 'Grid', icon: _Icon.grid, on: _grid, onTap: () => setState(() => _grid = !_grid)),
                  SizedBox(width: Shape.s(6)),
                  if (_camera || ws.layers.any((l) => l.kind == WsKind.camera)) ...[
                    // (AbsentMotion's PreviewMode: the switch once there is a camera to switch to)
                    _Toggle(label: _camera ? 'Camera' : 'Free', glyph: G.camera, on: _camera, onTap: () => setState(() => _camera = !_camera)),
                    SizedBox(width: Shape.s(6)),
                  ],
                  _Toggle(key: const ValueKey('ws-snapshot-take'), label: 'Snapshot', icon: _Icon.snap, on: false, onTap: _take),
                  if (_shot != null) ...[
                    SizedBox(width: WsT.gap),
                    Listener(
                      // (After Effects' Show Snapshot: seen while it is held; let go, the picture as it is now)
                      onPointerDown: (_) => setState(() => _showing = true),
                      onPointerUp: (_) => setState(() => _showing = false),
                      onPointerCancel: (_) => setState(() => _showing = false),
                      child: _Toggle(key: const ValueKey('ws-snapshot-show'), label: 'Show', icon: _Icon.show, on: _showing, onTap: () {}),
                    ),
                  ],
                ],
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ToolColumn(active: _tool, onChanged: (i) => setState(() => _tool = i), onTwice: (kind) => _whole(ws, kind)),
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          WsTwoFingers(
                            onPinchStep: (step) => setState(() => _zoom = (_zoom + step).clamp(0, stageZooms.length - 1)),
                            child: StageView(
                              key: _view,
                              scene: scene,
                              selected: ws.selected,
                              zoom: _zoom,
                              grid: _grid,
                              safe: _safe,
                              cursor: _cursor,
                              onPoke: _focus.requestFocus,
                              texture: ws.stageTexture,
                              snapshot: _showing ? _shot : null,
                              make: const [null, null, 'rect', 'circle', 'pen', 'text', 'brush', 'camera'][_tool],
                              brushSize: const [8.0, 16.0, 32.0][_opts['brush.size'] ?? 1],
                              brushTool: const [1, 0, 2, 3][_opts['brush.kind'] ?? 0],
                              axis: _tool == 1 ? _opts['move.axis'] ?? 0 : 0,
                              fromCentre: (_opts['ell.from'] ?? 0) == 1,
                              snap: _tool < 2 && (_opts[_tool == 0 ? 'sel.snap' : 'move.snap'] ?? 1) == 1,
                              pivots: (_opts['sel.pivot'] ?? 0) == 1,
                              group: _tool == 0 && (_opts['sel.level'] ?? 0) == 1,
                              mask: (_opts[_tool == 2 ? 'rect.mode' : 'pen.mode'] ?? 0) == 1 && (_tool == 2 || _tool == 4),
                            ),
                          ), // (joined: the tool in hand draws a thing of the document)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _OptionsStrip(tool: _tool, opts: _opts, onOpt: (k, v) => setState(() => _opts[k] = v), scene: scene, layer: ws.layer, ws: ws),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- small round things you touch --------------------------------------------------------------------------------------

class _Hov extends StatefulWidget {
  const _Hov({required this.builder, this.onTap});
  final Widget Function(BuildContext, bool) builder;
  final VoidCallback? onTap;
  @override
  State<_Hov> createState() => _HovState();
}

class _HovState extends State<_Hov> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child: widget.builder(context, _h)),
  );
}

/// A segmented chip: a well with round items, the chosen one filled with the accent.
class _Seg extends StatelessWidget {
  const _Seg({required this.items, required this.index, required this.onChanged});
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Forms.worn.segment(context, ChoiceSpec(labels: items, selected: index, onSelect: onChanged));
}

enum _Icon { safe, grid, snap, show }

/// An on/off chip: raised with an accent mark when on, a quiet well when off.
class _Toggle extends StatelessWidget {
  const _Toggle({super.key, required this.label, required this.on, required this.onTap, this.icon, this.glyph});
  final String label;
  final bool on;
  final VoidCallback onTap;
  final _Icon? icon;
  final G? glyph;
  @override
  Widget build(BuildContext context) => Forms.worn.flag(
    context,
    FlagSpec(
      label: label,
      on: on,
      onTap: onTap,
      mark: (ink) {
        if (glyph case final g?) return Glyph(g, size: Shape.z(14), color: ink);
        return CustomPaint(size: const Size.square(12), painter: _IconPainter(icon!, ink));
      },
    ),
  );
}

class _IconPainter extends CustomPainter {
  const _IconPainter(this.icon, this.c);
  final _Icon icon;
  final Color c;
  @override
  void paint(Canvas cv, Size s) {
    if (SkinParts.draw(cv, s, 'stage.${icon.name}', c)) return; // (the skin's own picture, if it brings one)
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = (Offset.zero & s).deflate(1);
    switch (icon) {
      case _Icon.safe:
        cv.drawRect(r, p);
        cv.drawRect(r.deflate(2.5), p);
      case _Icon.grid:
        cv.drawRect(r, p);
        for (final t in const [1 / 3, 2 / 3]) {
          cv.drawLine(Offset(r.left + r.width * t, r.top), Offset(r.left + r.width * t, r.bottom), p);
          cv.drawLine(Offset(r.left, r.top + r.height * t), Offset(r.right, r.top + r.height * t), p);
        }
      case _Icon.snap: // (a camera's body and its lens)
        cv.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(r.left, r.top + r.height * .25, r.right, r.bottom), const Radius.circular(1.5)), p);
        cv.drawCircle(r.center.translate(0, r.height * .12), r.width * .2, p);
      case _Icon.show: // (the picture halved: then and now)
        cv.drawRect(r, p);
        cv.drawRect(Rect.fromLTRB(r.left, r.top, r.center.dx, r.bottom), p..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_IconPainter o) => o.icon != icon || o.c != c;
}

/// A shape tool pressed twice: one as large as the picture, at once (After Effects': Adobe's own lesson on adding layers).
void _whole(Ws ws, String kind) {
  ws.whole(kind);
  ws.setView('stage.tool', 0);
}

// ---- tool column -------------------------------------------------------------------------------------------------------

class _ToolColumn extends StatelessWidget {
  const _ToolColumn({required this.active, required this.onChanged, required this.onTwice});
  final int active;
  final ValueChanged<int> onChanged;
  final ValueChanged<String> onTwice;
  static var _last = (-1, 0); // (the tool last pressed, and when)

  void _press(int i) {
    final now = DateTime.now().millisecondsSinceEpoch, twice = _last.$1 == i && now - _last.$2 < 500;
    _last = (i, now);
    if (twice && (i == 2 || i == 3)) return onTwice(i == 2 ? 'rect' : 'circle');
    onChanged(i);
  }

  @override
  Widget build(BuildContext context) => Container(
    width: WsT.rail,
    decoration: BoxDecoration(
      color: WsT.body,
      border: Border(right: BorderSide(color: WsT.line)),
    ),
    child: ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _tools.length; i++) ...[
                if (i == 2 || i == 4 || i == 7)
                  Container(
                    width: Shape.z(20),
                    height: 1,
                    margin: EdgeInsets.symmetric(vertical: Shape.s(5)),
                    color: WsT.line,
                  ),
                if (i != 0 && i != 2 && i != 4 && i != 7) SizedBox(height: Shape.s(3)),
                _ToolButton(key: ValueKey('ws-tool-$i'), glyph: _tools[i].$1, on: i == active, onTap: () => _press(i)),
              ],
              Container(
                width: Shape.z(20),
                height: 1,
                margin: EdgeInsets.symmetric(vertical: Shape.s(8)),
                color: WsT.line,
              ),
              const _Swatches(), // (joined: the picked thing's fill and stroke, or the inks a drawn thing gets)
            ],
          ),
        ),
      ),
    ),
  );
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({super.key, required this.glyph, required this.on, required this.onTap});
  final G glyph;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Hov(
    onTap: onTap,
    builder: (_, h) => Container(
      width: Shape.z(28),
      height: Shape.z(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: on ? WsT.accent : (h ? WsT.raised : WsT.body), borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
      child: Glyph(glyph, size: Shape.z(16), color: on ? WsT.onAccent : (h ? Grey.g95 : Grey.g63)),
    ),
  );
}

/// Fill and stroke inks of the drawing tools, fill above, stroke below. Pressed, one is the one the Colors shelf
/// gives its colour to, brought to the front and ringed, and the shelf comes (CLIP STUDIO PAINT's main and sub colour
/// icons at the foot of its tools: the one picked has a blue outline and the wheel changes it; Illustrator's Fill and
/// Stroke boxes: the one chosen is edited). With nothing picked, it is the ink or the edge a thing drawn next comes in.
class _Swatches extends StatelessWidget {
  const _Swatches();
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked}), p = _paintOf(ws);
    final fill = p.fill ?? WsT.body, stroke = p.stroke ?? WsT.line, edgeOn = ws.aim == 'stroke';
    Widget box(String aim, BoxDecoration look) => GestureDetector(
      key: ValueKey('ws-ink-$aim'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        ws.aim = aim;
        ws.route('Browser › Colors');
      },
      child: Container(
        width: Shape.z(16),
        height: Shape.z(16),
        foregroundDecoration: ws.aim == aim
            ? BoxDecoration(
                borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius)),
                border: Border.all(color: WsT.accent),
              )
            : null,
        decoration: look,
      ),
    );
    final edge = Positioned(
      right: 0,
      bottom: 0,
      child: box(
        'stroke',
        BoxDecoration(
          color: WsT.body,
          borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius)),
          border: Border.all(color: stroke, width: 3),
        ),
      ),
    );
    final ink = Positioned(
      left: 0,
      top: 0,
      child: box(
        'fill',
        BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius)),
          border: Border.all(color: WsT.body),
        ),
      ),
    );
    return SizedBox(
      width: Shape.z(26),
      height: Shape.z(26),
      child: Stack(
        children: edgeOn ? [ink, edge] : [edge, ink], // (the one aimed in front)
      ),
    );
  }
}
