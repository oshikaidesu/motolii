// The stage's view: the composition centred on a dark surround, rulers and guides, overlays, the selection, the zoom
// HUD and the navigator, and the pan, zoom, hover, key handling and pointer gestures over them.
// It repaints only when the scene, the selection, the hover or the view changes. The pointer readout repaints the rulers alone.
import 'dart:async' show Timer;
import 'dart:io' show File;
import 'dart:ui' show PointMode;

import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart' show Motolii;
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/commands/layer_menu.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/stage/camera_gestures.dart';
import 'package:motolii/workspace/stage/draw_tools.dart';
import 'package:motolii/workspace/stage/hud.dart';
import 'package:motolii/workspace/stage/selection_handles.dart';
import 'package:motolii/workspace/stage/stage_context.dart';
import 'package:motolii/workspace/stage/stage_drag.dart';
import 'package:motolii/workspace/stage/stage_navigator.dart';
import 'package:motolii/workspace/stage/stage_tokens.dart';
import 'package:motolii/workspace/stage/stage_tool.dart';
import 'package:motolii/workspace/stage/stage_view_relations.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/stage/view_painter.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// The stage viewport.
///
/// It draws the scene, handles pointer input for selecting, moving and drawing layers, and reports the pointer position.
class StageView extends StatefulWidget {
  const StageView({
    super.key,
    required this.scene,
    required this.selected,
    required this.zoom,
    required this.grid,
    required this.safe,
    required this.cursor,
    this.onPoke,
    this.texture,
    this.tool = const StageTool(),
    this.snapshot,
  });

  /// The active tool and its options.
  final StageTool tool;

  /// The engine's image of the stage as a Flutter texture id. When null, the stand-in art is painted.
  final int? texture;

  /// A still image taken earlier (After Effects' Take Snapshot), laid over the stage while it is shown.
  final String? snapshot;
  final ArtScene scene;
  final String? selected;
  final int zoom;
  final bool grid, safe;

  /// The pointer in composition px while it is over the viewport; the HUD and the rulers read it.
  final ValueNotifier<Offset?> cursor;
  final VoidCallback? onPoke;
  @override
  State<StageView> createState() => _StageViewState();
}

class _StageViewState extends State<StageView>
    implements StageHandles, StageContext {
  @override
  WorkspaceController get workspace => WorkspaceScope.read(context);
  @override
  ArtScene get scene => widget.scene;
  @override
  String? get selected => widget.selected;
  @override
  StageTool get tool => widget.tool;
  @override
  List<double> get crop => _cropOf();

  // The drag in progress, the camera gestures that are carried on through it, and the strokes of the drawing tools.
  late final StageDrag _drag;
  late final CameraGestures _camera;
  late final DrawTools _draw;

  void _rebuild() => setState(() {});

  Offset _pan = Offset.zero;
  String? _hover;
  StageViewport?
  _shown; // The view as last laid out, so handle positions match the screen.

  @override
  String? hitAt(Offset global) {
    final box = context.findRenderObject() as RenderBox?, v = _shown;
    return box == null || v == null
        ? null
        : _hitLocal(v, box.globalToLocal(global));
  }

  @override
  Map<String, Offset> get handles {
    final v = _shown,
        scene = widget.scene,
        b = ArtGeometry.boxOf(scene, widget.selected),
        l = scene.layer(widget.selected);
    if (v == null || b == null || l == null) return const {};
    final (form, round) = _formOf();
    return selectionHandles(
      v.toScreen,
      b,
      knob: l.kind != LayerKind.camera && l.id != 'bg',
      form: form,
      round: round,
      crop: _cropOf(),
    );
  }

  /// The selected image's crop, as the share cut from each side, while it is being cropped; empty otherwise.
  List<double> _cropOf() {
    final m = WorkspaceScope.read(context).inside,
        t = int.tryParse(widget.selected ?? '');
    if (m == null ||
        t == null ||
        _cropping != widget.selected ||
        !_photo(m, t)) {
      return const [];
    }
    return [for (final n in cropSides) m.value(t, n, 0) ?? 0];
  }

  static bool _photo(Motolii m, int t) =>
      m.word(t, 'kind') == 'picture' &&
      RegExp(
        r'\.(jpe?g|png|webp|bmp)$',
        caseSensitive: false,
      ).hasMatch(m.word(t, 'file'));

  // Double-clicking a selected image starts cropping: bars appear on its sides until a click elsewhere or Enter.
  // Figma's Crop and Keynote's image editing work this way.
  String? _cropping;
  String? _tapped; // Layer id clicked a moment ago, until the double-click timeout passes.
  Timer? _tapWait;
  bool _enter(KeyEvent e) {
    // Ignored while the user is typing text.
    if (_cropping == null ||
        e is! KeyDownEvent ||
        e.logicalKey != LogicalKeyboardKey.enter) {
      return false;
    }
    if (primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return false;
    }
    setState(() => _cropping = null);
    return true;
  }

  @override
  void initState() {
    super.initState();
    _drag = StageDrag(this)..addListener(_rebuild);
    _camera = CameraGestures(this, _drag)..addListener(_rebuild);
    _draw = DrawTools(this)..addListener(_rebuild);
    HardwareKeyboard.instance.addHandler(_enter);
  }

  /// The selected shape's kind and corner radius, for its handles.
  (String, double) _formOf() {
    final m = WorkspaceScope.read(context).inside,
        t = int.tryParse(widget.selected ?? '');
    if (m == null || t == null || m.word(t, 'kind') != 'shape') return ('', 0);
    return (m.word(t, 'shape'), m.value(t, 'round', 0) ?? 0);
  }

  @override
  void didUpdateWidget(StageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) _pan = Offset.zero;
    if (oldWidget.tool.make != widget.tool.make) {
      _draw.endPenPath(); // Another tool: the pen's next point starts a new shape.
    }
  }

  // When the engine draws the whole pane, the stage sits inside it where this view puts it. The engine is told again when
  // that changes, after the frame, because it cannot be asked during build.
  int? _desk;
  StageViewport? _toldDesk;
  Motolii? _deskOf;
  double? _toldDpr;
  void _deskTo(StageViewport v) {
    final dpr = MediaQuery.devicePixelRatioOf(context),
        m = WorkspaceScope.read(context).inside;
    if (m != _deskOf) {
      // A different project was opened: forget the old engine view and send it again.
      _desk = null;
      _toldDesk = null;
      _toldPick = null;
    }
    if (widget.texture == null || (v == _toldDesk && dpr == _toldDpr)) {
      return; // Also sent again when the window's pixel ratio changes.
    }
    _toldDesk = v;
    _toldDpr = dpr;
    if ((_deskOf = m) == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _toldDesk != v || _toldDpr != dpr) return;
      final m = _deskOf!;
      final ticket = m.desk(
        (v.area.width * dpr).round(),
        (v.area.height * dpr).round(),
        (v.origin.dx - v.area.left) * dpr,
        (v.origin.dy - v.area.top) * dpr,
        v.scale * dpr,
        dpr,
      );
      void look(Duration _) {
        // Poll once per frame until the engine has drawn, so the window never blocks on it.
        if (!mounted) return;
        final a = m.answer(ticket);
        if (a < 0) {
          SchedulerBinding.instance.scheduleFrameCallback(look);
          return;
        }
        if (a == 0) return;
        _toldPick = null;
        if (_desk == null) {
          m.deskTexture().then(
            (id) => mounted && id >= 0 ? setState(() => _desk = id) : null,
          );
        }
      }

      SchedulerBinding.instance
        ..scheduleFrameCallback(look)
        ..ensureVisualUpdate();
    });
  }

  // With the engine drawing the pane: tells it which layer is selected and which is hovered whenever they change.
  (int, int)? _toldPick;
  void _pickTo() {
    final m = _deskOf;
    if (_desk == null || m == null) return;
    final now = (
      int.tryParse(widget.selected ?? '') ?? 0,
      int.tryParse(_hover ?? '') ?? 0,
    );
    if (now == _toldPick) return;
    _toldPick = now;
    m.pick(now.$1, now.$2);
  }

  @override
  void dispose() {
    _deskOf?.desk(0, 0, 0, 0, 0, 0); // Back to the engine's own stage view.
    _camera.dispose();
    _drag.dispose();
    _draw.dispose();
    _tapWait?.cancel();
    HardwareKeyboard.instance.removeHandler(_enter);
    super.dispose();
  }

  StageViewport _view(Size size) => StageViewport.of(
    size,
    composition: ArtGeometry.comp,
    zoom: widget.zoom,
    pan: _pan,
    ruler: StageTokens.ruler,
    margin: StageTokens.fitMargin,
  );

  String? _hitLocal(StageViewport v, Offset local) {
    // A layer off the canvas can still be grabbed by its frame and dragged back.
    final d = v.toComposition(local),
        id = ArtGeometry.hit(widget.scene, d),
        m = WorkspaceScope.read(context).inside;
    if (widget.tool.group && m != null && id != null) {
      // Grouping: pick the outermost ancestor by following parents.
      var t = int.parse(id);
      for (
        var p = (m.value(t, 'parent', 0) ?? 0).round(), n = 0;
        p > 0 && n < 64;
        p = (m.value(t, 'parent', 0) ?? 0).round(), n++
      ) {
        t = p;
      }
      return '$t';
    }
    return id;
  }

  Offset? _last;

  /// Decides what a drag starting at [local] grabs, in order: the active tool's action, a handle of the selected layer,
  /// a camera gizmo, a guide, a layer, and otherwise a lasso.
  void _dragStart(StageViewport v, Offset local) {
    if (widget.tool.make == 'camera') return _camera.orbitDragStart(local);
    if (widget.tool.make == 'brush') {
      _draw.brushDragStart(local);
      return;
    }
    if (widget.tool.make != null) {
      _draw.drawDragStart(local);
      return;
    }
    final ws = WorkspaceScope.read(context), m = ws.inside;
    if (_drag.handleDragStart(v, local)) return;
    if (m != null && _camera.gizmoDragStart(v, local, inside: false)) return;
    // Guides come after the handles, which lie over everything else.
    if (_drag.guideDragStart(v, local)) return;
    final id = m == null ? null : _hitLocal(v, local),
        t = int.tryParse(id ?? '');
    // Layers are tested first, then the camera frames they lie in.
    if (m != null &&
        t == null &&
        _camera.gizmoDragStart(v, local, inside: true)) {
      return;
    }
    if (m != null && t == null) {
      // Nothing under the pointer: draw a lasso.
      ws.select(null);
      _draw.lassoDragStart(local);
      return;
    }
    if (m == null || t == null) return;
    _drag.layerDragStart(id!, local);
  }

  /// Carries the drag on to [local]: the camera's, when it is one, else the layer's or the handle's.
  void _dragUpdate(StageViewport v, Offset local) {
    if (_camera.dragUpdate(local)) return;
    _drag.dragUpdate(v, local);
  }

  /// Ends the current drag. With [keep] false, or when nothing moved, the engine discards the change.
  void _dragEnd({bool keep = true}) {
    _camera.dragEnd();
    _drag.dragEnd(keep: keep);
  }

  /// The id of the selected layer's parent, or null if it has none.
  String? _parentOf() {
    final m = WorkspaceScope.read(context).inside,
        t = int.tryParse(widget.selected ?? '');
    final p = m == null || t == null
        ? 0
        : (m.value(t, 'parent', 0) ?? 0).round();
    return p > 0 ? '$p' : null;
  }

  /// Pans by [by] (two-finger trackpad movement, or the wheel in the other direction) when zoomed in. At Fit there is nowhere to pan.
  void _panBy(Offset by, StageViewport v) {
    if (widget.zoom == 0) return;
    setState(() => _pan = v.clampPan(_pan + by));
  }

  // The selected layer's motion path over time as the engine computes it (including its wave), in canvas points, drawn thin
  // with direction arrows as in Alight Motion. Recomputed only when the document or the selection changes; null when the
  // layer stays put.
  (Object?, List<Offset>?) _trail = (null, null);
  List<Offset>? _trailOf() {
    final ws = WorkspaceScope.read(context),
        m = ws.inside,
        t = int.tryParse(widget.selected ?? '');
    if (m == null ||
        t == null ||
        const {'behaviour', 'camera', 'light'}.contains(m.word(t, 'kind'))) {
      return null;
    }
    final key = (ws.rev, t);
    if (_trail.$1 != key) {
      _trail = (key, null);
      final start = m.value(t, 'start', 0) ?? 0,
          lasts = m.lasts(t),
          end = lasts > 0 ? start + lasts : m.seconds;
      if (end > start) {
        m.path(t, from: start, to: end, n: 90).then((p) {
          if (!mounted || _trail.$1 != key || p == null) return;
          final c = ArtGeometry.centre,
              pts = [
                for (var i = 0; i + 1 < p.length; i += 4)
                  c + Offset(p[i], -p[i + 1]) * m.point,
              ];
          setState(
            () => _trail = (
              key,
              pts.any((q) => (q - pts.first).distance > 1) ? pts : null,
            ),
          );
        });
      }
    }
    return _trail.$2;
  }

  final _menu = GlobalKey<ContextMenuState>();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final v = _shown = _view(box.biggest),
          scene = widget.scene,
          trail = _trailOf();
      _deskTo(v);
      _pickTo();
      return ContextMenu(
        key: _menu,
        child: TwoFingerGestures(
          onWheel: (d) => widget.tool.make == 'camera'
              ? _camera.dolly(d.dy)
              : _panBy(-d, v),
          onPan: (by, _) => _panBy(by, v),
          child: MouseRegion(
            onHover: (e) {
              widget.cursor.value = v.toComposition(e.localPosition);
              final h = _hitLocal(v, e.localPosition);
              if (h != _hover) setState(() => _hover = h);
            },
            onExit: (_) {
              widget.cursor.value = null;
              if (_hover != null) setState(() => _hover = null);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              supportedDevices: pressingDevices,
              onSecondaryTapDown: (d) {
                // Context menu for the layer under the pointer, same as on its bar.
                final ws = WorkspaceScope.read(context),
                    id = _hitLocal(v, d.localPosition),
                    l = ws.layers.where((l) => l.id == id).firstOrNull;
                if (l != null) {
                  _menu.currentState?.show(
                    d.localPosition,
                    layerContextMenu(context, ws, l),
                  );
                }
              },
              onTapUp: (d) {
                widget.onPoke?.call();
                if (widget.tool.make == 'pen') {
                  return _draw.pen(
                    v,
                    d.localPosition,
                    d.localPosition,
                  ); // A click makes a corner point.
                }
                if (widget.tool.make == 'brush') {
                  return; // A stroke is drawn, not clicked.
                }
                if (widget.tool.make != null) {
                  return _draw.drawAt(
                    v,
                    d.localPosition,
                  ); // A click creates one layer there.
                }
                final hit = _hitLocal(v, d.localPosition),
                    ws = WorkspaceScope.read(context),
                    m = ws.inside;
                if (HardwareKeyboard.instance.isShiftPressed ||
                    HardwareKeyboard.instance.isMetaPressed) {
                  return hit == null ? null : selectAlso(ws, hit); // Shift or Cmd adds or removes the layer; on empty space nothing is lost.
                }
                final twice = hit != null && hit == _tapped;
                _tapWait?.cancel();
                _tapped = twice ? null : hit;
                if (!twice) {
                  _tapWait = Timer(kDoubleTapTimeout, () => _tapped = null);
                }
                ws.select(hit);
                final crop = twice && m != null && _photo(m, int.parse(hit))
                    ? hit
                    : null;
                if (crop != _cropping) setState(() => _cropping = crop);
              },
              dragStartBehavior: DragStartBehavior.down, // Grab the layer where the pointer went down, not where it had got to when the drag was recognised.
              onPanStart: (d) => _dragStart(v, _last = d.localPosition),
              onPanUpdate: (d) => _draw.brush != null
                  ? _draw.brushDragUpdate(d.localPosition)
                  : _draw.lasso != null
                  ? _draw.lassoDragUpdate(d.localPosition)
                  : _draw.drawFrom != null
                  ? _draw.drawDragUpdate(
                      _last = d.localPosition, // Record the pointer position for every tool, not only the pen.
                    )
                  : _drag.isPullingGuide
                  ? (widget.cursor.value = v.toComposition(
                      _last = d.localPosition,
                    ))
                  : _dragUpdate(v, _last = d.localPosition),
              onPanEnd: (_) => _draw.brush != null
                  ? _draw.brushDragEnd(v)
                  : _draw.lasso != null
                  ? _draw.lassoDragEnd(v)
                  : _draw.drawFrom != null
                  ? (widget.tool.make == 'pen'
                        ? _draw.pen(
                            v,
                            _draw.drawFrom!,
                            _last ?? _draw.drawFrom!,
                          )
                        : _draw.drawDragEnd(v, _last ?? _draw.drawFrom!))
                  : _drag.isPullingGuide
                  ? _drag.guideDragEnd(v, _last!)
                  : _dragEnd(),
              onPanCancel: () => _draw.brush != null
                  ? _draw.brushDragCancel()
                  : _draw.lasso != null
                  ? _draw.lassoDragCancel()
                  : _draw.drawFrom != null
                  ? _draw.drawDragCancel()
                  : _drag.isPullingGuide
                  ? _drag.guideDragCancel()
                  : _dragEnd(keep: false),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: ViewPainter(
                        scene,
                        v,
                        widget.selected,
                        _hover == widget.selected ? null : _hover,
                        grid: widget.grid,
                        safe: widget.safe,
                        part: widget.texture == null
                            ? ViewPart.all
                            : ViewPart.under,
                        pivots: widget.tool.pivots,
                        met: _drag.met,
                        trail: trail,
                        parent: _parentOf(),
                        grip: _drag.heldGrip,
                        form: _formOf(),
                        crop: _cropOf(),
                      ),
                    ),
                  ),
                  if (_desk case final desk? when widget.texture != null) ...[
                    // The whole pane as the engine draws it: the area off the stage is half covered and the selected layer is marked.
                    Positioned.fromRect(
                      rect: v.area,
                      child: IgnorePointer(
                        child: Texture(
                          textureId: desk,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                    ),
                    Positioned.fromRect(
                      rect: v.compositionRect,
                      child: const IgnorePointer(
                        child: SizedBox(key: ValueKey('ws-stage-comp')),
                      ),
                    ), // Where the canvas lies inside it.
                  ] else
                    Positioned.fromRect(
                      rect: v.compositionRect,
                      child: IgnorePointer(
                        child: widget.texture == null
                            ? const SizedBox(key: ValueKey('ws-stage-comp'))
                            : ClipRect(
                                key: const ValueKey('ws-stage-comp'),
                                child: Texture(
                                  textureId: widget.texture!,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                      ),
                    ),
                  if (widget.snapshot case final shot?) // While Show Snapshot is held, the earlier frame is drawn over the canvas.
                    Positioned.fromRect(
                      rect: v.compositionRect,
                      child: IgnorePointer(
                        child: Image.file(
                          File(shot),
                          key: const ValueKey('ws-stage-snapshot'),
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  if (int.tryParse(widget.selected ?? '') case final picked?
                      when WorkspaceScope.read(context).inside != null) // The selected path's own points, so they can be grabbed.
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: PointsPainter(
                          [
                            for (final p in WorkspaceScope.read(
                              context,
                            ).inside!.points(picked))
                              v.toScreen(p),
                          ],
                          [
                            for (final (h, o) in WorkspaceScope.read(
                              context,
                            ).inside!.handles(picked))
                              (v.toScreen(h), v.toScreen(o)),
                          ],
                        ),
                      ),
                    ),
                  if (_draw.drawFrom case final from?
                      when _last != null &&
                          widget.tool.make == 'pen' &&
                          _draw.penWay != null &&
                          DrawTools.scribbled(
                            _draw.penWay!,
                            from,
                            _last!,
                          )) // A scribble is drawn thin like the brush and becomes a path on release.
                    IgnorePointer(
                      child: CustomPaint(painter: _BrushWay(_draw.penWay!)),
                    )
                  else if (_draw.drawFrom case final from?
                      when _last != null &&
                          widget.tool.make ==
                              'pen') // The pen's handle being pulled out, drawn through its point both ways.
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: PointsPainter(
                          [from],
                          [(_last!, from), (from * 2 - _last!, from)],
                        ),
                      ),
                    )
                  else if (_draw.drawFrom case final from?
                      when _last != null) // The box of the layer being drawn.
                    Positioned.fromRect(
                      rect: Rect.fromPoints(from, _last!),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: WindowTokens.accent),
                          ),
                        ),
                      ),
                    ),
                  if (_drag.held
                      case final h? when h.moved && _last != null) // Show the numbers beside the pointer while dragging, as Figma does; Alight Motion shows none.
                    if (_drag.heldSays(h.by) case final says?)
                      Positioned(
                        left: _last!.dx + 16,
                        top: _last!.dy + 16,
                        child: IgnorePointer(
                          child: Container(
                            key: const ValueKey('ws-held-says'),
                            padding: EdgeInsets.symmetric(
                              horizontal: Shape.s(6),
                              vertical: Shape.s(3),
                            ),
                            decoration: BoxDecoration(
                              color: WindowTokens.raised,
                              borderRadius: BorderRadius.all(Shape.r(3)),
                            ),
                            child: Text(
                              says,
                              style: TextStyles.micro(Grey.g95),
                            ),
                          ),
                        ),
                      ),
                  if (widget.texture != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: ViewPainter(
                          scene,
                          v,
                          widget.selected,
                          _hover == widget.selected ? null : _hover,
                          grid: widget.grid,
                          safe: widget.safe,
                          part: ViewPart.over,
                          pivots: widget.tool.pivots,
                          met: _drag.met,
                          marked: _desk != null,
                          trail: trail,
                          parent: _parentOf(),
                          grip: _drag.heldGrip,
                          form: _formOf(),
                          crop: _cropOf(),
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: RulerPainter(v, widget.cursor, scene),
                    ),
                  ),
                  // Marks for the lasso, the layers picked together and the picked relation: its shape, handles and what it moves.
                  RelationMarks(scene: scene, v: v, lasso: _draw.lasso),
                  // The brush path so far, drawn thin; once released the stroke belongs to the engine.
                  if (_draw.brush case final way?)
                    IgnorePointer(child: CustomPaint(painter: _BrushWay(way))),
                  Positioned(
                    left: StageTokens.ruler + StageTokens.pad,
                    bottom: StageTokens.pad,
                    child: Hud(scale: v.scale, cursor: widget.cursor),
                  ),
                  if (widget.zoom != 0 &&
                      box.maxWidth > 360 &&
                      box.maxHeight > 220)
                    Positioned(
                      right: StageTokens.pad,
                      bottom: StageTokens.pad,
                      child: StageNavigator(
                        scene: scene,
                        view: v,
                        texture: widget.texture,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _BrushWay extends CustomPainter {
  const _BrushWay(this.way);
  final List<Offset> way;
  @override
  void paint(Canvas c, Size s) => c.drawPoints(
    PointMode.polygon,
    way,
    Paint()
      ..color = WindowTokens.accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round,
  );
  @override
  bool shouldRepaint(_BrushWay o) => true;
}
