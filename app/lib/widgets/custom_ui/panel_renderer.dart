// Shared native Flutter renderer for declarative QuickJS UI trees
// (used by both Custom Docking Tabs and Effect Custom Inspector Cards).
// 詳細: docs/design/custom_panels.md
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/custom_ui/panel_node.dart';
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/widgets/number_field.dart';
import 'package:motolii/widgets/number_format.dart';
import 'package:motolii/widgets/text_gestures.dart' show TypedField;

/// Callback fired whenever a control in the declarative UI tree is interacted with.
typedef PanelActionCallback = void Function(
  String id,
  Object? value, {
  bool live,
});

/// Renders a [PanelNode] tree using Motolii's native widgets and current skin.
class PanelTreeView extends StatelessWidget {
  const PanelTreeView({required this.node, required this.onAction, super.key});

  final PanelNode node;
  final PanelActionCallback onAction;

  @override
  Widget build(BuildContext context) => _buildNode(context, node);

  Widget _buildNode(BuildContext context, PanelNode n) {
    switch (n.type) {
      case 'column':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, c) in n.children.indexed) ...[
              if (i > 0) SizedBox(height: Shape.s(6)),
              _buildNode(context, c),
            ],
          ],
        );

      case 'row':
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (i, c) in n.children.indexed) ...[
              if (i > 0) SizedBox(width: Shape.s(5)),
              if (c.type == 'spacer')
                SizedBox(width: Shape.s(c.size ?? 6))
              else if (c.type == 'badge' || c.type == 'text')
                _buildNode(context, c)
              else
                Expanded(child: _buildNode(context, c)),
            ],
          ],
        );

      case 'grid':
        final cols = n.cols.clamp(1, 12);
        final rows = (n.children.length / cols).ceil();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var r = 0; r < rows; r++) ...[
              if (r > 0) SizedBox(height: Shape.s(4)),
              Row(
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    if (c > 0) SizedBox(width: Shape.s(4)),
                    Expanded(
                      child: (r * cols + c) < n.children.length
                          ? _buildNode(context, n.children[r * cols + c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );

      case 'section':
        return _PanelSection(
          title: n.title,
          initialOpen: n.open,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, c) in n.children.indexed) ...[
                if (i > 0) SizedBox(height: Shape.s(5)),
                _buildNode(context, c),
              ],
            ],
          ),
        );

      case 'divider':
        return Container(height: 1, color: Grey.g20);

      case 'spacer':
        return SizedBox(height: Shape.s(n.size ?? 6));

      case 'text':
        return Text(
          n.text,
          style: (n.bold ? TextStyles.name : TextStyles.micro)(
            n.muted ? Grey.g56 : Grey.g91,
          ),
        );

      case 'badge':
        final tone = panelToneColor(n.tone);
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: Shape.s(6),
            vertical: Shape.s(2),
          ),
          decoration: BoxDecoration(
            color: tone.withValues(alpha: 0.16),
            borderRadius: Shape.round(4),
            border: Border.all(color: tone.withValues(alpha: 0.45)),
          ),
          child: Text(n.text, style: TextStyles.micro(tone)),
        );

      case 'meter':
        final tone = panelToneColor(n.tone);
        final v = (n.numValue ?? 0.0).clamp(0.0, 1.0);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n.label.isNotEmpty) ...[
              Text(n.label, style: TextStyles.micro(Grey.g56)),
              SizedBox(height: Shape.s(3)),
            ],
            Container(
              height: Shape.z(6),
              decoration: BoxDecoration(
                color: Grey.g20,
                borderRadius: Shape.round(3),
              ),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: tone,
                    borderRadius: Shape.round(3),
                  ),
                ),
              ),
            ),
          ],
        );

      case 'swatch':
        final swatchColor = parseHexColor(n.color) ?? Grey.g56;
        return Pressable(
          key: n.id.isEmpty ? null : ValueKey('panel:swatch:${n.id}'),
          onTap: n.id.isEmpty ? null : () => onAction(n.id, n.color),
          builder: (_, hot) => Container(
            height: Shape.z(22),
            decoration: BoxDecoration(
              color: swatchColor,
              borderRadius: Shape.round(4),
              border: Border.all(
                color: n.active ? Grey.g95 : (hot ? Grey.g76 : Grey.g26),
                width: n.active ? 1.8 : 1.0,
              ),
            ),
          ),
        );

      case 'button':
        final activeTone = n.accent ? Accent.fill : Grey.g91;
        return Opacity(
          opacity: n.disabled ? 0.4 : 1.0,
          child: Pressable(
            key: n.id.isEmpty ? null : ValueKey('panel:btn:${n.id}'),
            onTap: n.disabled ? null : () => onAction(n.id, true),
            builder: (_, hot) => Container(
              height: Shape.z(24),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: n.accent
                    ? Accent.fill.withValues(alpha: hot ? 0.28 : 0.18)
                    : (hot ? Grey.g26 : InspectorSkin.well),
                borderRadius: Shape.round(5),
                border: Border.all(
                  color: n.accent
                      ? Accent.fill.withValues(alpha: 0.70)
                      : Grey.g26,
                ),
              ),
              child: Text(
                n.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.micro(
                  n.accent ? activeTone : (hot ? Grey.g95 : Grey.g91),
                ),
              ),
            ),
          ),
        );

      case 'toggle':
        final on = n.boolValue ?? false;
        return Pressable(
          key: n.id.isEmpty ? null : ValueKey('panel:toggle:${n.id}'),
          onTap: n.disabled ? null : () => onAction(n.id, !on),
          builder: (_, hot) => Row(
            children: [
              Container(
                width: Shape.z(14),
                height: Shape.z(14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on
                      ? Accent.fill.withValues(alpha: 0.22)
                      : (hot ? Grey.g26 : InspectorSkin.well),
                  borderRadius: Shape.round(3),
                  border: Border.all(
                    color: on ? Accent.fill : (hot ? Grey.g56 : Grey.g38),
                  ),
                ),
                child: on
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Accent.fill,
                          borderRadius: Shape.round(1.5),
                        ),
                      )
                    : null,
              ),
              SizedBox(width: Shape.s(6)),
              Expanded(
                child: Text(
                  n.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.micro(hot ? Grey.g95 : Grey.g91),
                ),
              ),
            ],
          ),
        );

      case 'number':
      case 'slider':
        final cur = n.numValue ?? 0.0;
        final min = n.min;
        final max = n.max;
        final step = n.step ?? (n.type == 'slider' ? 0.01 : 1.0);
        final dec = n.dec ?? (step < 1 ? (step < 0.1 ? 2 : 1) : 0);
        final span = (min != null && max != null && max > min)
            ? (max - min)
            : 100.0;
        return NumberField(
          key: n.id.isEmpty ? null : ValueKey('panel:num:${n.id}'),
          value: () => cur,
          text: (v, _) => formatNumber(v, dec),
          unit: (_, _) => n.unit,
          caption: n.label.isEmpty ? null : n.label,
          min: min,
          max: max,
          perPx: span / 140.0,
          step: step,
          reach: (to, _) =>
              (min != null && max != null) ? to.clamp(min, max).toDouble() : to,
          onChange: (v) => onAction(n.id, v, live: true),
          onType: (v) => onAction(n.id, v),
          onDrop: () => onAction(n.id, cur),
          height: InspectorSkin.tile,
          pad: InspectorSkin.tilePad,
        );

      case 'select':
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n.label.isNotEmpty) ...[
              Text(n.label, style: TextStyles.micro(Grey.g56)),
              SizedBox(height: Shape.s(3)),
            ],
            Row(
              children: [
                for (final (i, opt) in n.options.indexed) ...[
                  if (i > 0) SizedBox(width: Shape.s(3)),
                  Expanded(
                    child: Pressable(
                      key: n.id.isEmpty
                          ? null
                          : ValueKey('panel:opt:${n.id}:$opt'),
                      onTap: () => onAction(n.id, opt),
                      builder: (_, hot) => Container(
                        height: Shape.z(22),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: n.stringValue == opt
                              ? Accent.fill.withValues(alpha: 0.20)
                              : (hot ? Grey.g26 : InspectorSkin.well),
                          borderRadius: Shape.round(4),
                          border: Border.all(
                            color: n.stringValue == opt
                                ? Accent.fill.withValues(alpha: 0.65)
                                : Grey.g26,
                          ),
                        ),
                        child: Text(
                          opt,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyles.micro(
                            n.stringValue == opt
                                ? Accent.fill
                                : (hot ? Grey.g95 : Grey.g76),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );

      case 'input':
      case 'color':
        final swatch = n.type == 'color' ? parseHexColor(n.stringValue) : null;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (n.label.isNotEmpty) ...[
              Text(n.label, style: TextStyles.micro(Grey.g56)),
              SizedBox(height: Shape.s(3)),
            ],
            Container(
              height: Shape.z(22),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
              decoration: BoxDecoration(
                color: InspectorSkin.well,
                borderRadius: Shape.round(4),
                border: Border.all(color: Grey.g26),
              ),
              child: Row(
                children: [
                  if (swatch != null) ...[
                    Container(
                      width: Shape.z(12),
                      height: Shape.z(12),
                      decoration: BoxDecoration(
                        color: swatch,
                        borderRadius: Shape.round(2),
                        border: Border.all(color: Grey.g38),
                      ),
                    ),
                    SizedBox(width: Shape.s(5)),
                  ],
                  Expanded(
                    child: TypedField(
                      key: n.id.isEmpty ? null : ValueKey('panel:in:${n.id}'),
                      text: n.stringValue,
                      standing: true,
                      escapes: true,
                      style: TextStyles.micro(Grey.g91),
                      cursor: Grey.g95,
                      backgroundCursor: Grey.g20,
                      selection: Role.selected.withValues(alpha: 0.4),
                      onDone: (said) {
                        if (said != null) onAction(n.id, said);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case 'xy':
        return _XyPad(
          padKey: n.id.isEmpty ? null : ValueKey('panel:xy:${n.id}'),
          label: n.label,
          x: n.x,
          y: n.y,
          min: n.min ?? -1.0,
          max: n.max ?? 1.0,
          snap9: n.snap9,
          onPick: (nx, ny, {bool live = false}) =>
              onAction(n.id, {'x': nx, 'y': ny}, live: live),
        );

      case 'canvas':
        return _PanelCanvas(
          canvasKey: n.id.isEmpty ? null : ValueKey('panel:canvas:${n.id}'),
          label: n.label,
          height: (n.height ?? 96.0).clamp(32.0, 360.0),
          draw: n.draw,
          interactive: n.id.isNotEmpty,
          onPointer: (x, y, phase, {bool live = false}) => onAction(n.id, {
            'x': x,
            'y': y,
            'phase': phase,
            'shift': HardwareKeyboard.instance.isShiftPressed,
          }, live: live),
        );

      default:
        return Text(
          'Unknown node: ${n.type}',
          style: TextStyles.micro(Grey.g44),
        );
    }
  }
}

class _PanelSection extends StatefulWidget {
  const _PanelSection({
    required this.title,
    required this.initialOpen,
    required this.child,
  });

  final String title;
  final bool initialOpen;
  final Widget child;

  @override
  State<_PanelSection> createState() => _PanelSectionState();
}

class _PanelSectionState extends State<_PanelSection> {
  late bool _open = widget.initialOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Shape.s(6)),
    decoration: BoxDecoration(
      color: WindowTokens.card,
      borderRadius: Shape.round(6),
      border: Border.all(color: Grey.g20),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: () => setState(() => _open = !_open),
          builder: (_, hot) => Row(
            children: [
              CustomPaint(
                size: const Size(8, 8),
                painter: Draw(
                  (c, s) =>
                      _drawChevron(c, s, _open, hot ? Grey.g95 : Grey.g56),
                  (_open, hot),
                ),
              ),
              SizedBox(width: Shape.s(4)),
              Text(
                widget.title,
                style: TextStyles.micro(hot ? Grey.g95 : Grey.g76),
              ),
            ],
          ),
        ),
        if (_open) ...[SizedBox(height: Shape.s(5)), widget.child],
      ],
    ),
  );
}

class _XyPad extends StatelessWidget {
  const _XyPad({
    this.padKey,
    required this.label,
    required this.x,
    required this.y,
    required this.min,
    required this.max,
    required this.snap9,
    required this.onPick,
  });

  final Key? padKey;
  final String label;
  final double x;
  final double y;
  final double min;
  final double max;
  final bool snap9;
  final void Function(double x, double y, {bool live}) onPick;

  (double, double) _toValue(Offset local, Size size) {
    final u = (local.dx / math.max(1.0, size.width)).clamp(0.0, 1.0);
    final v = (local.dy / math.max(1.0, size.height)).clamp(0.0, 1.0);
    var nx = min + (max - min) * u;
    var ny = min + (max - min) * v;
    if (snap9) {
      final mid = (min + max) * 0.5;
      final stops = [min, mid, max];
      double nearest(double val) {
        var best = stops.first;
        for (final s in stops) {
          if ((val - s).abs() < (val - best).abs()) best = s;
        }
        return best;
      }

      nx = nearest(nx);
      ny = nearest(ny);
    }
    return (nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    final span = math.max(1e-6, max - min);
    final u = ((x - min) / span).clamp(0.0, 1.0);
    final v = ((y - min) / span).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            children: [
              Text(label, style: TextStyles.micro(Grey.g56)),
              const Spacer(),
              Text(
                '${formatNumber(x, 2)}, ${formatNumber(y, 2)}',
                style: TextStyles.micro(Grey.g76),
              ),
            ],
          ),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, Shape.z(64));
            return GestureDetector(
              key: padKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final (nx, ny) = _toValue(d.localPosition, size);
                onPick(nx, ny);
              },
              onPanUpdate: (d) {
                final (nx, ny) = _toValue(d.localPosition, size);
                onPick(nx, ny, live: true);
              },
              onPanEnd: (_) => onPick(x, y),
              child: Container(
                height: size.height,
                decoration: BoxDecoration(
                  color: InspectorSkin.well,
                  borderRadius: Shape.round(6),
                  border: Border.all(color: Grey.g26),
                ),
                child: CustomPaint(
                  size: size,
                  painter: Draw(
                    (c, s) => _drawXyPad(c, s, u, v, snap9: snap9),
                    (u, v, snap9),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

void _drawXyPad(Canvas c, Size s, double u, double v, {required bool snap9}) {
  const pad = 10.0;
  final w = math.max(1.0, s.width - pad * 2);
  final h = math.max(1.0, s.height - pad * 2);

  final line = Paint()
    ..color = Grey.g26
    ..strokeWidth = 1;
  c.drawLine(Offset(pad + w * 0.5, pad), Offset(pad + w * 0.5, pad + h), line);
  c.drawLine(Offset(pad, pad + h * 0.5), Offset(pad + w, pad + h * 0.5), line);

  if (snap9) {
    final dot = Paint()..color = Grey.g44;
    for (final gx in const [0.0, 0.5, 1.0]) {
      for (final gy in const [0.0, 0.5, 1.0]) {
        c.drawCircle(Offset(pad + w * gx, pad + h * gy), 2.5, dot);
      }
    }
  }

  final px = pad + w * u;
  final py = pad + h * v;
  // Vector ray from center when free-form (non-snap9) so direction/length reads instantly.
  if (!snap9) {
    c.drawLine(
      Offset(pad + w * 0.5, pad + h * 0.5),
      Offset(px, py),
      Paint()
        ..color = Accent.fill.withValues(alpha: 0.70)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }
  c.drawCircle(
    Offset(px, py),
    5.5,
    Paint()..color = Accent.fill.withValues(alpha: 0.25),
  );
  c.drawCircle(Offset(px, py), 3.5, Paint()..color = Accent.fill);
}

void _drawChevron(Canvas c, Size s, bool open, Color col) {
  final p = Paint()
    ..color = col
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final path = Path();
  if (open) {
    path
      ..moveTo(1.5, 2.5)
      ..lineTo(s.width * 0.5, s.height - 2.2)
      ..lineTo(s.width - 1.5, 2.5);
  } else {
    path
      ..moveTo(2.5, 1.5)
      ..lineTo(s.width - 2.2, s.height * 0.5)
      ..lineTo(2.5, s.height - 1.5);
  }
  c.drawPath(path, p);
}

/// Interactive vector drawing surface for `ui.canvas(height, drawOps, { id })`.
class _PanelCanvas extends StatefulWidget {
  const _PanelCanvas({
    this.canvasKey,
    required this.label,
    required this.height,
    required this.draw,
    required this.interactive,
    required this.onPointer,
  });

  final Key? canvasKey;
  final String label;
  final double height;
  final List<CanvasDrawOp> draw;
  final bool interactive;
  final void Function(double x, double y, String phase, {bool live}) onPointer;

  @override
  State<_PanelCanvas> createState() => _PanelCanvasState();
}

class _PanelCanvasState extends State<_PanelCanvas> {
  double _lastX = 0.5;
  double _lastY = 0.5;

  (double, double) _norm(Offset local, Size size) {
    final nx = (local.dx / math.max(1.0, size.width)).clamp(0.0, 1.0);
    final ny = (local.dy / math.max(1.0, size.height)).clamp(0.0, 1.0);
    _lastX = nx;
    _lastY = ny;
    return (nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    final h = Shape.z(widget.height);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: TextStyles.micro(Grey.g56)),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, h);
            final surface = Container(
              height: h,
              decoration: BoxDecoration(
                color: InspectorSkin.well,
                borderRadius: Shape.round(6),
                border: Border.all(color: Grey.g26),
              ),
              child: ClipRRect(
                borderRadius: Shape.round(5),
                child: CustomPaint(
                  size: size,
                  painter: Draw(
                    (c, s) => _drawCanvasOps(c, s, widget.draw),
                    widget.draw,
                  ),
                ),
              ),
            );
            if (!widget.interactive) return surface;
            return GestureDetector(
              key: widget.canvasKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final (x, y) = _norm(d.localPosition, size);
                widget.onPointer(x, y, 'down');
              },
              onPanStart: (d) {
                final (x, y) = _norm(d.localPosition, size);
                widget.onPointer(x, y, 'down', live: true);
              },
              onPanUpdate: (d) {
                final (x, y) = _norm(d.localPosition, size);
                widget.onPointer(x, y, 'drag', live: true);
              },
              onPanEnd: (_) => widget.onPointer(_lastX, _lastY, 'up'),
              child: surface,
            );
          },
        ),
      ],
    );
  }
}

void _drawCanvasOps(Canvas c, Size s, List<CanvasDrawOp> ops) {
  final w = s.width;
  final h = s.height;
  final minSide = math.min(w, h);

  for (final o in ops) {
    final fillCol = resolveCanvasColor(o.fill)?.withValues(alpha: o.alpha);
    final strokeCol = resolveCanvasColor(o.stroke)?.withValues(alpha: o.alpha);

    void paintPath(Path path) {
      if (fillCol != null) c.drawPath(path, Paint()..color = fillCol);
      if (strokeCol != null) {
        c.drawPath(
          path,
          Paint()
            ..color = strokeCol
            ..style = PaintingStyle.stroke
            ..strokeWidth = o.strokeWidth
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    switch (o.op) {
      case 'line':
        if (strokeCol != null) {
          c.drawLine(
            Offset(o.x * w, o.y * h),
            Offset(o.x2 * w, o.y2 * h),
            Paint()
              ..color = strokeCol
              ..strokeWidth = o.strokeWidth
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'rect':
        final rect = Rect.fromLTWH(o.x * w, o.y * h, o.w * w, o.h * h);
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(o.radius));
        if (fillCol != null) c.drawRRect(rrect, Paint()..color = fillCol);
        if (strokeCol != null) {
          c.drawRRect(
            rrect,
            Paint()
              ..color = strokeCol
              ..style = PaintingStyle.stroke
              ..strokeWidth = o.strokeWidth,
          );
        }
      case 'circle':
        final center = Offset(o.x * w, o.y * h);
        final rad = o.r * minSide;
        if (fillCol != null) {
          c.drawCircle(center, rad, Paint()..color = fillCol);
        }
        if (strokeCol != null) {
          c.drawCircle(
            center,
            rad,
            Paint()
              ..color = strokeCol
              ..style = PaintingStyle.stroke
              ..strokeWidth = o.strokeWidth,
          );
        }
      case 'arc':
        final rect = Rect.fromCircle(
          center: Offset(o.x * w, o.y * h),
          radius: o.r * minSide,
        );
        if (strokeCol != null) {
          c.drawArc(
            rect,
            o.start,
            o.sweep,
            false,
            Paint()
              ..color = strokeCol
              ..style = PaintingStyle.stroke
              ..strokeWidth = o.strokeWidth
              ..strokeCap = StrokeCap.round,
          );
        }
      case 'polyline':
        if (o.points.length >= 2) {
          final path = Path()
            ..moveTo(o.points.first.$1 * w, o.points.first.$2 * h);
          for (final pt in o.points.skip(1)) {
            path.lineTo(pt.$1 * w, pt.$2 * h);
          }
          paintPath(path);
        }
      case 'bezier':
        final path = Path()
          ..moveTo(o.x * w, o.y * h)
          ..cubicTo(
            o.cx1 * w,
            o.cy1 * h,
            o.cx2 * w,
            o.cy2 * h,
            o.x2 * w,
            o.y2 * h,
          );
        paintPath(path);
      case 'text':
        if (o.text.isNotEmpty) {
          final tp = TextPainter(
            text: TextSpan(
              text: o.text,
              style: TextStyles.micro(fillCol ?? Grey.g76),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          final dx = switch (o.align) {
            'center' => o.x * w - tp.width * 0.5,
            'right' => o.x * w - tp.width,
            _ => o.x * w,
          };
          tp.paint(c, Offset(dx, o.y * h - tp.height * 0.5));
        }
    }
  }
}
