// The stage's view: the composition centred on a dark surround, rulers and guides, overlays, the selection, the zoom
// HUD and the navigator, and the pan, zoom, hover, key handling and pointer gestures over them.
// It repaints only when the scene, the selection, the hover or the view changes. The pointer readout repaints the rulers alone.
import 'package:motolii/widgets/picks.dart' show clickKeys;
import 'package:motolii/workspace/stage/stage_previews.dart';
import 'package:motolii/workspace/stage/stage_trail.dart';
import 'package:motolii/workspace/stage/stage_desk.dart';
import 'package:motolii/workspace/stage/stage_pointer.dart';

import 'dart:async' show Timer;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyDownEvent, KeyEvent, LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:motolii/storage/snapshot_files.dart';
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
import 'package:motolii/workspace/stage/pick_marks.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/stage/ruler_painter.dart';
import 'package:motolii/workspace/stage/view_painter.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart';
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
  final int? selected;
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
  int? get selected => widget.selected;
  @override
  StageTool get tool => widget.tool;
  @override
  List<double> get crop => _cropOf();

  // The drag in progress, the camera gestures that are carried on through it, and the strokes of the drawing tools.
  late final StageDrag _drag;
  late final CameraGestures _camera;
  late final DrawTools _draw;
  late final StagePointer pointer;
  late final desk = StageDesk(alive: () => mounted, rebuild: setState);
  late final trailOf = StageTrail(alive: () => mounted, rebuild: setState);

  void _rebuild() => setState(() {});

  Offset _pan = Offset.zero;
  int? _hover;
  StageViewport?
  _shown; // The view as last laid out, so handle positions match the screen.

  @override
  int? hitAt(Offset global) {
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
      knob: l.kind != LayerKind.camera,
      form: form,
      round: round,
      crop: _cropOf(),
    );
  }

  /// The selected image's crop, as the share cut from each side, while it is being cropped; empty otherwise.
  List<double> _cropOf() {
    final ws = WorkspaceScope.read(context), t = widget.selected;
    if (!stageConnected(ws) ||
        t == null ||
        _cropping != widget.selected ||
        !_croppable(widget.selected)) {
      return const [];
    }
    return [for (final n in cropSides) stageValue(ws, t, n, 0) ?? 0];
  }

  /// Any placed, visible layer can be cropped — a photo, a video, text, a solid or a shape — as in Google Slides.
  /// Groups, particles, audio, the camera and the background are left out.
  bool _croppable(int? id) {
    if (id == null) return false;
    final l = widget.scene.layer(id);
    return l != null &&
        const {
          LayerKind.shape,
          LayerKind.text,
          LayerKind.image,
        }.contains(l.kind);
  }

  // Double-clicking a selected image starts cropping: bars appear on its sides until a click elsewhere or Enter.
  // Figma's Crop and Keynote's image editing work this way.
  int? _cropping;
  int? _tapped;
  Timer? _tapWait;
  bool _enter(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    // Ignored while the user is typing text.
    if (primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() !=
        null) {
      return false;
    }
    // Escape cancels a drag or a drawing in progress (GESTURES key.4).
    if (e.logicalKey == LogicalKeyboardKey.escape) {
      if (_draw.drawFrom != null ||
          _draw.brush != null ||
          _draw.lasso != null ||
          _drag.held != null) {
        pointer.cancel();
        return true;
      }
      return false;
    }
    if (_cropping == null || e.logicalKey != LogicalKeyboardKey.enter) {
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
    pointer = StagePointer(
      drag: _drag,
      camera: _camera,
      draw: _draw,
      tool: () => widget.tool,
      ws: () => WorkspaceScope.read(context),
      hit: _hitLocal,
      cursor: widget.cursor,
    );
    HardwareKeyboard.instance.addHandler(_enter);
  }

  /// The selected shape's kind and corner radius, for its handles.
  (String, double) _formOf() {
    final ws = WorkspaceScope.read(context), t = widget.selected;
    if (t == null || stageWord(ws, t, 'kind') != 'shape') return ('', 0);
    return (stageWord(ws, t, 'shape'), stageValue(ws, t, 'round', 0) ?? 0);
  }

  @override
  void didUpdateWidget(StageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zoom != widget.zoom) _pan = Offset.zero;
    if (oldWidget.tool.make != widget.tool.make) {
      _draw.endPenPath(); // Another tool: the pen's next point starts a new shape.
    }
  }

  @override
  void dispose() {
    desk.release();
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

  int? _hitLocal(StageViewport v, Offset local) {
    final d = v.toComposition(local),
        id = ArtGeometry.hit(widget.scene, d),
        ws = WorkspaceScope.read(context);
    if (widget.tool.group && stageConnected(ws) && id != null) {
      return stageOutermost(ws, id);
    }
    return id;
  }

  int? _parentOf() {
    final ws = WorkspaceScope.read(context), t = widget.selected;
    final p = t == null ? 0 : stageParentOf(ws, t);
    return p > 0 ? p : null;
  }

  /// Pans by [by] (two-finger trackpad movement, or the wheel in the other direction) when zoomed in. At Fit there is nowhere to pan.
  void _panBy(Offset by, StageViewport v) {
    if (widget.zoom == 0) return;
    setState(() => _pan = v.clampPan(_pan + by));
  }

  final _menu = GlobalKey<ContextMenuState>();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final v = _shown = _view(box.biggest),
          scene = widget.scene,
          trail = trailOf.of(WorkspaceScope.read(context), widget.selected);
      // What the stage paints around and over the preview: the one painter, once for all of it or once for each side of the engine's image.
      ViewPainter painter(ViewPart part, {bool marked = false}) => ViewPainter(
        scene,
        v,
        widget.selected,
        _hover == widget.selected ? null : _hover,
        grid: widget.grid,
        safe: widget.safe,
        part: part,
        pivots: widget.tool.pivots,
        met: _drag.met,
        marked: marked,
        trail: trail,
        parent: _parentOf(),
        grip: _drag.heldGrip,
        form: _formOf(),
        crop: _cropOf(),
      );
      desk.follow(
        WorkspaceScope.read(context),
        v,
        dpr: MediaQuery.devicePixelRatioOf(context),
        textured: widget.texture != null,
      );
      desk.pick(widget.selected, _hover);
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
                // On the empty stage, what can be done there.
                _menu.currentState?.show(
                  d.localPosition,
                  l != null
                      ? layerContextMenu(context, ws, l)
                      : emptyContextMenu(context, ws),
                );
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
                if (widget.tool.make == 'camera') {
                  return; // After Effects' Unified Camera tool makes nothing on a click; it only drags and wheels.
                }
                if (widget.tool.make != null) {
                  return _draw.drawAt(
                    v,
                    d.localPosition,
                  ); // A click creates one layer there.
                }
                final hit = _hitLocal(v, d.localPosition),
                    ws = WorkspaceScope.read(context);
                final keys = clickKeys();
                if (keys.add || keys.span) {
                  return hit == null ? null : clickLayer(ws, hit); // Shift or Cmd adds or removes the layer; on empty space nothing is lost.
                }
                final twice = hit != null && hit == _tapped;
                _tapWait?.cancel();
                _tapped = twice ? null : hit;
                if (!twice) {
                  _tapWait = Timer(kDoubleTapTimeout, () => _tapped = null);
                }
                ws.select(hit);
                final crop = twice && _croppable(hit) ? hit : null;
                if (crop != _cropping) setState(() => _cropping = crop);
              },
              dragStartBehavior: DragStartBehavior.down, // Grab the layer where the pointer went down, not where it had got to when the drag was recognised.
              onPanStart: (d) => pointer.start(v, d.localPosition),
              onPanUpdate: (d) => pointer.update(v, d.localPosition),
              onPanEnd: (_) => pointer.end(v),
              onPanCancel: pointer.cancel,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: painter(
                        widget.texture == null ? ViewPart.all : ViewPart.under,
                      ),
                    ),
                  ),
                  if (desk.id case final deskId?
                      when widget.texture != null) ...[
                    // The whole pane as the engine draws it: the area off the stage is half covered and the selected layer is marked.
                    Positioned.fromRect(
                      rect: v.area,
                      child: IgnorePointer(
                        child: Texture(
                          textureId: deskId,
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
                        child: Image(
                          image: snapshotImage(shot),
                          key: const ValueKey('ws-stage-snapshot'),
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                        ),
                      ),
                    ),
                  if (widget.selected case final picked?
                      when stageConnected(WorkspaceScope.read(context))) // The selected path's own points, so they can be grabbed.
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: PointsPainter(
                          [
                            for (final p in stagePathPoints(
                              WorkspaceScope.read(context),
                              picked,
                            ))
                              v.toScreen(p),
                          ],
                          [
                            for (final (h, o) in stagePathHandles(
                              WorkspaceScope.read(context),
                              picked,
                            ))
                              (v.toScreen(h), v.toScreen(o)),
                          ],
                        ),
                      ),
                    ),
                  ?stageDrawPreview(
                    draw: _draw,
                    last: pointer.last,
                    make: widget.tool.make,
                  ),
                  ?stageHeldSays(drag: _drag, last: pointer.last),
                  if (widget.texture != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: painter(
                          ViewPart.over,
                          marked: desk.id != null,
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: CustomPaint(
                      painter: RulerPainter(v, widget.cursor, scene),
                    ),
                  ),
                  PickMarks(scene: scene, v: v, lasso: _draw.lasso),
                  // The brush path so far, drawn thin; once released the stroke belongs to the engine.
                  if (_draw.brush case final way?)
                    IgnorePointer(child: CustomPaint(painter: BrushWay(way))),
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
