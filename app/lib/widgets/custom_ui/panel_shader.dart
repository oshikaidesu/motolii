// Flutter-native FragmentShader widget (`ui.shader`) for 60fps GPU visualizers inside custom cards.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/custom_ui/panel_style.dart';
import 'package:motolii/widgets/media.dart' show Draw;

/// Declarative spec for a `ui.shader` GPU visualizer node.
class PanelShaderSpec {
  const PanelShaderSpec({
    this.preset = 'holo',
    this.time = 0.0,
    this.paramA = 0.6,
    this.paramB = 0.45,
    this.mouseX = 0.5,
    this.mouseY = 0.5,
    this.color = '',
    this.color2 = '',
    this.color3 = '',
  });

  final String preset;
  final double time;
  final double paramA;
  final double paramB;
  final double mouseX;
  final double mouseY;
  final String color;
  final String color2;
  final String color3;

  double get modeIndex => switch (preset) {
    'metaball' => 1.0,
    'vhs' => 2.0,
    'scope' => 3.0,
    'aurora' => 4.0,
    'grid' => 5.0,
    _ => 0.0,
  };

  static PanelShaderSpec fromJson(Map<Object?, Object?> raw) {
    double n(String k, double d) =>
        raw[k] is num ? (raw[k] as num).toDouble() : d;
    return PanelShaderSpec(
      preset: raw['preset']?.toString() ?? raw['shader']?.toString() ?? 'holo',
      time: n('time', 0.0),
      paramA: n('paramA', n('intensity', 0.6)).clamp(0.0, 1.0),
      paramB: n('paramB', n('warp', 0.45)).clamp(0.0, 1.0),
      mouseX: n('mouseX', 0.5).clamp(0.0, 1.0),
      mouseY: n('mouseY', 0.5).clamp(0.0, 1.0),
      color: raw['color']?.toString() ?? '',
      color2: raw['color2']?.toString() ?? '',
      color3: raw['color3']?.toString() ?? '',
    );
  }
}

Future<ui.FragmentProgram?>? _panelShaderFuture;
ui.FragmentProgram? _panelShaderCached;

Future<ui.FragmentProgram?> _loadPanelShader() {
  if (_panelShaderCached != null) return Future.value(_panelShaderCached);
  return _panelShaderFuture ??=
      ui.FragmentProgram.fromAsset('shaders/panel_fx.frag')
          .then<ui.FragmentProgram?>((p) {
            _panelShaderCached = p;
            return p;
          })
          .catchError((_) => null);
}

/// Interactive Flutter `FragmentShader` surface (`ui.shader`) with graceful Canvas fallback.
class PanelShaderView extends StatefulWidget {
  const PanelShaderView({
    required this.spec,
    required this.height,
    required this.interactive,
    this.surfaceKey,
    this.label = '',
    this.framed = true,
    this.style,
    this.onPointer,
    super.key,
  });

  final Key? surfaceKey;
  final PanelShaderSpec spec;
  final double height;
  final bool interactive;
  final String label;
  final bool framed;
  final PanelStyle? style;
  final void Function(double x, double y, String phase, {bool live})? onPointer;

  @override
  State<PanelShaderView> createState() => _PanelShaderViewState();
}

class _PanelShaderViewState extends State<PanelShaderView> {
  ui.FragmentProgram? _program = _panelShaderCached;
  double? _mx;
  double? _my;

  @override
  void initState() {
    super.initState();
    if (_program == null) {
      _loadPanelShader().then((p) {
        if (mounted && p != null) setState(() => _program = p);
      });
    }
  }

  (double, double) _norm(Offset local, Size size) {
    final nx = (local.dx / math.max(1.0, size.width)).clamp(0.0, 1.0);
    final ny = (local.dy / math.max(1.0, size.height)).clamp(0.0, 1.0);
    _mx = nx;
    _my = ny;
    return (nx, ny);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final h = Shape.z(widget.height);
    final rad = st?.radius ?? theme.radius ?? 8.0;
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
    final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;

    final colA =
        resolvePanelColor(widget.spec.color) ?? theme.accent ?? Accent.fill;
    final colB =
        resolvePanelColor(widget.spec.color2) ?? InspectorSkin.toneLayout;
    final colC =
        resolvePanelColor(widget.spec.color3) ?? InspectorSkin.toneTime;
    final mx = _mx ?? widget.spec.mouseX;
    final my = _my ?? widget.spec.mouseY;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: TextStyles.micro(
              resolvePanelColor(st?.muted ?? '') ?? theme.muted ?? Grey.g56,
            ),
          ),
          SizedBox(height: Shape.s(3)),
        ],
        LayoutBuilder(
          builder: (context, box) {
            final size = Size(box.maxWidth, h);
            final painter = Draw(
              (c, s) {
                final prog = _program;
                if (prog != null) {
                  final sh = prog.fragmentShader();
                  sh
                    ..setFloat(0, s.width)
                    ..setFloat(1, s.height)
                    ..setFloat(2, widget.spec.time)
                    ..setFloat(3, widget.spec.modeIndex)
                    ..setFloat(4, widget.spec.paramA)
                    ..setFloat(5, widget.spec.paramB)
                    ..setFloat(6, mx)
                    ..setFloat(7, my)
                    ..setFloat(8, colA.r)
                    ..setFloat(9, colA.g)
                    ..setFloat(10, colA.b)
                    ..setFloat(11, colB.r)
                    ..setFloat(12, colB.g)
                    ..setFloat(13, colB.b)
                    ..setFloat(14, colC.r)
                    ..setFloat(15, colC.g)
                    ..setFloat(16, colC.b);
                  c.drawRect(Offset.zero & s, Paint()..shader = sh);
                } else {
                  _paintShaderFallback(c, s, widget.spec, colA, colB, colC);
                }
              },
              (
                _program,
                widget.spec.preset,
                widget.spec.time,
                widget.spec.paramA,
                widget.spec.paramB,
                mx,
                my,
                colA,
                colB,
                colC,
              ),
            );
            final child = CustomPaint(size: size, painter: painter);
            final surface = widget.framed
                ? Container(
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(rad),
                      border: bw > 0
                          ? Border.all(color: borderCol, width: bw)
                          : null,
                      boxShadow: st?.shadow == null
                          ? null
                          : [st!.shadow!.toBoxShadow()],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(math.max(0, rad - 1)),
                      child: child,
                    ),
                  )
                : SizedBox(
                    height: h,
                    child: ClipRect(child: child),
                  );
            if (!widget.interactive || widget.onPointer == null) return surface;
            return GestureDetector(
              key: widget.surfaceKey,
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final (x, y) = _norm(d.localPosition, size);
                setState(() {});
                widget.onPointer!(x, y, 'down');
              },
              onPanStart: (d) {
                final (x, y) = _norm(d.localPosition, size);
                setState(() {});
                widget.onPointer!(x, y, 'down', live: true);
              },
              onPanUpdate: (d) {
                final (x, y) = _norm(d.localPosition, size);
                setState(() {});
                widget.onPointer!(x, y, 'drag', live: true);
              },
              onPanEnd: (_) {
                final x = _mx ?? widget.spec.mouseX;
                final y = _my ?? widget.spec.mouseY;
                widget.onPointer!(x, y, 'up');
              },
              child: surface,
            );
          },
        ),
      ],
    );
  }
}

void _paintShaderFallback(
  Canvas c,
  Size s,
  PanelShaderSpec spec,
  Color colA,
  Color colB,
  Color colC,
) {
  final rect = Offset.zero & s;
  c.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [colA, colB, colC],
      ).createShader(rect),
  );
}
