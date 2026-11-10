// The Stage panel: header with view controls, the tool column, the viewport (stage_view.dart) and the tool options strip.
// The image is the work (state/art_scene.dart). The chrome around it stays grey, with the accent only on what is switched on.
import 'dart:io' show Directory, File;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/skin/skin_parts.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable, IconPress;
import 'package:motolii/widgets/glyphs.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/workspace/stage/stage_options.dart';
import 'package:motolii/workspace/stage/stage_view.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_state.dart';

class StagePane extends StatelessWidget {
  const StagePane({super.key});
  @override
  Widget build(BuildContext context) => const Panel(child: _Stage());
}

const stageTools = [
  (Glyphs.select, 'Select', 'V'),
  (Glyphs.move, 'Move', 'M'),
  (Glyphs.rect, 'Rectangle', 'R'),
  (Glyphs.ellipse, 'Ellipse', 'E'),
  (Glyphs.pen, 'Pen', 'P'),
  (Glyphs.text, 'Text', 'T'),
  // Freehand path, as in Alight Motion. B is the brush key in Photoshop and After Effects.
  (Glyphs.brush, 'Brush', 'B'),
  // After Effects' Unified Camera tool: a drag orbits the camera, the wheel dollies it.
  (Glyphs.camera, 'Camera', 'C'),
];

/// The tools as app commands (`tool.select`, `tool.text` ...). Their letters are in the keymap (keymap.dart).
///
/// They work wherever the app has the keys and no text is being typed, as the tool letters of After Effects and
/// Photoshop do, not only while the stage has focus.
Map<String, VoidCallback> wsToolCommands(WorkspaceController ws) => {
  for (final (i, t) in stageTools.indexed) 'tool.${t.$2.toLowerCase()}': () => ws.setView('stage.tool', i),
};

class _Stage extends StatefulWidget {
  const _Stage();
  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  // The stage's look is kept in the app's view state, so any panel can read it and a reopened app shows the same.
  WorkspaceController get _ws => WorkspaceScope.read(context);
  int get _zoom => _ws.viewOf('stage.zoom', 0);
  set _zoom(int v) => _ws.setView('stage.zoom', v);
  int get _tool => _ws.viewOf('stage.tool', 0);
  set _tool(int v) => _ws.setView('stage.tool', v);
  bool get _safe => _ws.viewOf('stage.safe', true);
  set _safe(bool v) => _ws.setView('stage.safe', v);
  bool get _grid => _ws.viewOf('stage.grid', false);
  set _grid(bool v) => _ws.setView('stage.grid', v);
  // Off until the user asks, so the stage shows the whole world. Alight Motion's cameraView works the same way.
  bool get _camera => _ws.viewOf('stage.camera', false);
  (Object?, String) _eyeTold = (null, '');

  /// Tells the engine which view camera the stage is seen through, when that has changed.
  ///
  /// A newly opened document starts with the world view.
  void _tellEye(WorkspaceController ws) {
    final m = ws.inside, word = ws.freeEye ? ws.eye.join(' ') : '';
    if (m == null || _eyeTold == (m, word)) return;
    _eyeTold = (m, word);
    m.later('view_camera', word: word);
  }

  set _camera(bool v) => _ws.setView('stage.camera', v);
  Map<String, int> get _opts => _ws.view.putIfAbsent('stage.options', () => <String, int>{}) as Map<String, int>;
  final _cursor = ValueNotifier<Offset?>(null);
  final _focus = FocusNode(debugLabel: 'stage');
  // Used to find what is under a shelf tile dropped on the stage.
  final _view = GlobalKey();
  // The snapshot as it was when taken: a still image among the system's temporary files.
  String? _shot;
  bool _showing = false;

  @override
  void dispose() {
    _cursor.dispose();
    _focus.dispose();
    _forget();
    super.dispose();
  }

  /// After Effects' Take Snapshot: keeps the frame at the playhead as a still image (the engine's Export Frame).
  ///
  /// While Show Snapshot is held the still is shown over the stage, to compare an earlier look with the current one.
  /// Nothing is undone.
  void _take() {
    final m = _ws.inside;
    if (m == null) return;
    // A new name each time, because Flutter's image cache identifies a file by its name.
    final png = '${Directory.systemTemp.path}/motolii_snapshot_${DateTime.now().microsecondsSinceEpoch}.png';
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
    } catch (_) {
      // Already gone.
    }
  }

  @override
  Widget build(BuildContext context) {
    // The scene follows the playhead and the image being shown.
    WorkspaceScope.frameOf(context);
    WorkspaceScope.pictureOf(context);
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document, WorkspaceAspect.picked, WorkspaceAspect.stage, WorkspaceAspect.view}),
        scene = WorkspaceController.timed('stage scene', () => ArtScene.of(ws, camera: !ws.freeEye));
    _tellEye(ws);
    return DragTarget<VoidCallback>(
      // A shelf tile dropped here does what its double click does, as dropping a device on a track does in Ableton.
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (d) {
        // Apply to the layer under the drop, as After Effects does for an effect dragged onto a layer in the
        // Composition panel. Over no layer, apply to the selected layer, as a double click does.
        if ((_view.currentState as StageHandles?)?.hitAt(d.offset) case final id?) ws.select(id);
        d.data();
      },
      builder: (context, hot, _) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(border: hot.isEmpty ? null : Border.all(color: WindowTokens.accent, width: 2)),
        child: Focus(
          focusNode: _focus,
          child: Column(
            children: [
              PanelHeader(
                '',
                trailing: [
                  Forms.worn.segment(context, ChoiceSpec(labels: stageZooms, selected: _zoom, onSelect: (i) => setState(() => _zoom = i))),
                  SizedBox(width: Shape.s(6)),
                  Toggle(label: 'Safe', icon: StageIcon.safe, on: _safe, onTap: () => setState(() => _safe = !_safe)),
                  SizedBox(width: WindowTokens.gap),
                  Toggle(label: 'Grid', icon: StageIcon.grid, on: _grid, onTap: () => setState(() => _grid = !_grid)),
                  SizedBox(width: Shape.s(6)),
                  if (_camera || ws.layers.any((l) => l.kind == LayerKind.camera)) ...[
                    // Alight Motion's PreviewMode: the switch appears once there is a camera to switch to.
                    Toggle(label: _camera ? 'Camera' : 'Free', glyph: Glyphs.camera, on: _camera, onTap: () => setState(() => _camera = !_camera)),
                    SizedBox(width: Shape.s(6)),
                  ],
                  Toggle(key: const ValueKey('ws-snapshot-take'), label: 'Snapshot', icon: StageIcon.snap, on: false, onTap: _take),
                  if (_shot != null) ...[
                    SizedBox(width: WindowTokens.gap),
                    Listener(
                      // After Effects' Show Snapshot: the still is shown only while the button is held.
                      onPointerDown: (_) => setState(() => _showing = true),
                      onPointerUp: (_) => setState(() => _showing = false),
                      onPointerCancel: (_) => setState(() => _showing = false),
                      child: Toggle(key: const ValueKey('ws-snapshot-show'), label: 'Show', icon: StageIcon.show, on: _showing, onTap: () {}),
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
                          TwoFingerGestures(
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              OptionsStrip(tool: _tool, opts: _opts, onOpt: (k, v) => setState(() => _opts[k] = v), scene: scene, layer: ws.layer, ws: ws),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- header toggles ----------------------------------------------------------------------------------------------------

enum StageIcon { safe, grid, snap, show }

/// An on/off chip: raised with an accent mark when on, a quiet well when off.
class Toggle extends StatelessWidget {
  const Toggle({super.key, required this.label, required this.on, required this.onTap, this.icon, this.glyph});
  final String label;
  final bool on;
  final VoidCallback onTap;
  final StageIcon? icon;
  final Glyphs? glyph;
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
  final StageIcon icon;
  final Color c;
  @override
  void paint(Canvas cv, Size s) {
    // Use the skin's own icon if it provides one.
    if (SkinParts.draw(cv, s, 'stage.${icon.name}', c)) return;
    final p = Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final r = (Offset.zero & s).deflate(1);
    switch (icon) {
      case StageIcon.safe:
        cv.drawRect(r, p);
        cv.drawRect(r.deflate(2.5), p);
      case StageIcon.grid:
        cv.drawRect(r, p);
        for (final t in const [1 / 3, 2 / 3]) {
          cv.drawLine(Offset(r.left + r.width * t, r.top), Offset(r.left + r.width * t, r.bottom), p);
          cv.drawLine(Offset(r.left, r.top + r.height * t), Offset(r.right, r.top + r.height * t), p);
        }
      case StageIcon.snap: // A camera body and its lens.
        cv.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(r.left, r.top + r.height * .25, r.right, r.bottom), const Radius.circular(1.5)), p);
        cv.drawCircle(r.center.translate(0, r.height * .12), r.width * .2, p);
      case StageIcon.show: // The image halved: then and now.
        cv.drawRect(r, p);
        cv.drawRect(Rect.fromLTRB(r.left, r.top, r.center.dx, r.bottom), p..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_IconPainter o) => o.icon != icon || o.c != c;
}

/// A shape tool clicked twice adds a shape as large as the canvas at once, as in After Effects.
void _whole(WorkspaceController ws, String kind) {
  ws.whole(kind);
  ws.setView('stage.tool', 0);
}

// ---- tool column -------------------------------------------------------------------------------------------------------

/// The column of tool buttons, with the fill and stroke swatches at its foot.
class _ToolColumn extends StatelessWidget {
  const _ToolColumn({required this.active, required this.onChanged, required this.onTwice});
  final int active;
  final ValueChanged<int> onChanged;
  final ValueChanged<String> onTwice;
  // The tool last pressed, and when.
  static var _last = (-1, 0);

  void _press(int i) {
    final now = DateTime.now().millisecondsSinceEpoch, twice = _last.$1 == i && now - _last.$2 < 500;
    _last = (i, now);
    if (twice && (i == 2 || i == 3)) return onTwice(i == 2 ? 'rect' : 'circle');
    onChanged(i);
  }

  @override
  Widget build(BuildContext context) => Container(
    width: WindowTokens.rail,
    decoration: BoxDecoration(
      color: WindowTokens.body,
      border: Border(right: BorderSide(color: WindowTokens.line)),
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
              for (var i = 0; i < stageTools.length; i++) ...[
                if (i == 2 || i == 4 || i == 7)
                  Container(
                    width: Shape.z(20),
                    height: 1,
                    margin: EdgeInsets.symmetric(vertical: Shape.s(5)),
                    color: WindowTokens.line,
                  ),
                if (i != 0 && i != 2 && i != 4 && i != 7) SizedBox(height: Shape.s(3)),
                IconPress(
                  (ink) => Glyph(stageTools[i].$1, size: Shape.z(16), color: ink),
                  key: ValueKey('ws-tool-$i'),
                  size: Shape.z(28),
                  rest: WindowTokens.body,
                  ink: Grey.g63,
                  on: i == active,
                  onTap: () => _press(i),
                ),
              ],
              Container(
                width: Shape.z(20),
                height: 1,
                margin: EdgeInsets.symmetric(vertical: Shape.s(8)),
                color: WindowTokens.line,
              ),
              const _Swatches(),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Fill and stroke swatches of the drawing tools, fill above and stroke below.
///
/// Clicking one makes it the target of the Colors shelf: it is brought to the front, ringed, and the shelf opens.
/// This follows the main and sub colour icons of CLIP STUDIO PAINT and the Fill and Stroke boxes of Illustrator.
/// With no layer selected, the swatches show the fill and stroke the next drawn layer will get.
class _Swatches extends StatelessWidget {
  const _Swatches();
  @override
  Widget build(BuildContext context) {
    final ws = WorkspaceScope.of(context, {WorkspaceAspect.document, WorkspaceAspect.picked}), p = paintOf(ws);
    final fill = p.fill ?? WindowTokens.body, stroke = p.stroke ?? WindowTokens.line, edgeOn = ws.aim == 'stroke';
    Widget box(String aim, BoxDecoration look) => Pressable(
      key: ValueKey('ws-ink-$aim'),
      cursor: MouseCursor.defer,
      onTap: () {
        ws.aim = aim;
        ws.route('Browser › Colors');
      },
      builder: (_, _) => Container(
        width: Shape.z(16),
        height: Shape.z(16),
        foregroundDecoration: ws.aim == aim
            ? BoxDecoration(
                borderRadius: BorderRadius.all(Shape.r(WindowTokens.chipRadius)),
                border: Border.all(color: WindowTokens.accent),
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
          color: WindowTokens.body,
          borderRadius: BorderRadius.all(Shape.r(WindowTokens.chipRadius)),
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
          borderRadius: BorderRadius.all(Shape.r(WindowTokens.chipRadius)),
          border: Border.all(color: WindowTokens.body),
        ),
      ),
    );
    return SizedBox(
      width: Shape.z(26),
      height: Shape.z(26),
      child: Stack(
        // The targeted swatch goes in front.
        children: edgeOn ? [ink, edge] : [edge, ink],
      ),
    );
  }
}
