// Pure-Flutter 3D viewport widget (`ui.scene3d`) for VST-style custom cards and panels.
// Uses Flutter Canvas + vector_math (zero C++ engine coupling) and runs in both live app and golden tests.
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/script_files.dart' show readRelativeBytes;
import 'package:motolii/widgets/custom_ui/panel_style.dart';
import 'package:motolii/widgets/media.dart' show Draw;

/// Declarative configuration for a `ui.scene3d` node.
class Scene3dSpec {
  const Scene3dSpec({
    this.shape = 'cube',
    this.model = '',
    this.look = 'studio',
    this.yaw = 0.55,
    this.pitch = 0.35,
    this.roll = 0.0,
    this.zoom = 1.0,
    this.color = '',
    this.color2 = '',
    this.outline = '',
    this.outlineWidth = 1.8,
    this.bg = '',
    this.bg2 = '',
    this.lightYaw = 0.7,
    this.lightPitch = 0.75,
    this.rimColor = '',
    this.ambientColor = '',
    this.ambient = 0.24,
    this.gloss = 0.65,
    this.grid = false,
    this.axes = false,
    this.shadow = true,
    this.wireframe = false,
    this.warp = 0.5,
    this.phase = 0.0,
    this.harmonics = 3.0,
    this.vertices = const [],
    this.faces = const [],
    this.objects = const [],
  });

  final String shape;
  final String model;
  final String look;
  final double yaw;
  final double pitch;
  final double roll;
  final double zoom;
  final String color;
  final String color2;
  final String outline;
  final double outlineWidth;
  final String bg;
  final String bg2;
  final double lightYaw;
  final double lightPitch;
  final String rimColor;
  final String ambientColor;
  final double ambient;
  final double gloss;
  final bool grid;
  final bool axes;
  final bool shadow;
  final bool wireframe;
  final double warp;
  final double phase;
  final double harmonics;
  final List<List<double>> vertices;
  final List<List<int>> faces;
  final List<Scene3dObjectSpec> objects;

  static Scene3dSpec fromJson(Map<Object?, Object?> raw) {
    double n(String k, double d) =>
        raw[k] is num ? (raw[k] as num).toDouble() : d;
    final verts = <List<double>>[];
    if (raw['vertices'] is List) {
      for (final v in raw['vertices'] as List) {
        if (v is List &&
            v.length >= 3 &&
            v[0] is num &&
            v[1] is num &&
            v[2] is num) {
          verts.add([
            (v[0] as num).toDouble(),
            (v[1] as num).toDouble(),
            (v[2] as num).toDouble(),
          ]);
        }
      }
    }
    final fcs = <List<int>>[];
    if (raw['faces'] is List) {
      for (final f in raw['faces'] as List) {
        if (f is List && f.length >= 3) {
          fcs.add([
            for (final idx in f)
              if (idx is num) idx.toInt(),
          ]);
        }
      }
    }
    final objs = <Scene3dObjectSpec>[];
    if (raw['objects'] is List) {
      for (final o in raw['objects'] as List) {
        if (o is Map) objs.add(Scene3dObjectSpec.fromJson(o));
      }
    }
    return Scene3dSpec(
      shape: raw['shape']?.toString() ?? 'cube',
      model: raw['model']?.toString() ?? '',
      look: raw['look']?.toString() ?? 'studio',
      yaw: n('yaw', 0.55),
      pitch: n('pitch', 0.35),
      roll: n('roll', 0.0),
      zoom: n('zoom', 1.0).clamp(0.25, 3.5),
      color: raw['color']?.toString() ?? '',
      color2: raw['color2']?.toString() ?? '',
      outline: raw['outline']?.toString() ?? '',
      outlineWidth: n('outlineWidth', 1.8).clamp(0.4, 5.0),
      bg: raw['bg']?.toString() ?? '',
      bg2: raw['bg2']?.toString() ?? '',
      lightYaw: n('lightYaw', 0.7),
      lightPitch: n('lightPitch', 0.75),
      rimColor: raw['rimColor']?.toString() ?? '',
      ambientColor: raw['ambientColor']?.toString() ?? '',
      ambient: n('ambient', 0.24).clamp(0.0, 1.0),
      gloss: n('gloss', 0.65).clamp(0.0, 1.5),
      grid: raw['grid'] == true,
      axes: raw['axes'] == true,
      shadow: raw['shadow'] != false,
      wireframe: raw['wireframe'] == true,
      warp: n('warp', 0.5),
      phase: n('phase', 0.0),
      harmonics: n('harmonics', 3.0),
      vertices: verts,
      faces: fcs,
      objects: objs,
    );
  }
}

/// One additional sub-object inside `Scene3dSpec.objects`.
class Scene3dObjectSpec {
  const Scene3dObjectSpec({
    this.shape = 'sphere',
    this.x = 0,
    this.y = 0,
    this.z = 0,
    this.scale = 0.35,
    this.rx = 0,
    this.ry = 0,
    this.rz = 0,
    this.color = '',
    this.look = '',
  });

  final String shape;
  final double x, y, z, scale, rx, ry, rz;
  final String color;
  final String look;

  static Scene3dObjectSpec fromJson(Map<Object?, Object?> raw) {
    double n(String k, double d) =>
        raw[k] is num ? (raw[k] as num).toDouble() : d;
    return Scene3dObjectSpec(
      shape: raw['shape']?.toString() ?? 'sphere',
      x: n('x', 0),
      y: n('y', 0),
      z: n('z', 0),
      scale: n('scale', 0.35),
      rx: n('rx', 0),
      ry: n('ry', 0),
      rz: n('rz', 0),
      color: raw['color']?.toString() ?? '',
      look: raw['look']?.toString() ?? '',
    );
  }
}

/// Interactive Flutter-native 3D widget with orbit drag.
class PanelScene3d extends StatefulWidget {
  const PanelScene3d({
    required this.spec,
    required this.height,
    required this.interactive,
    this.surfaceKey,
    this.label = '',
    this.baseFile = '',
    this.framed = true,
    this.style,
    this.onOrbit,
    super.key,
  });

  final Key? surfaceKey;
  final Scene3dSpec spec;
  final double height;
  final bool interactive;
  final String label;
  final String baseFile;
  final bool framed;
  final PanelStyle? style;
  final void Function(
    double yaw,
    double pitch,
    double x,
    double y,
    String phase, {
    bool live,
  })?
  onOrbit;

  @override
  State<PanelScene3d> createState() => _PanelScene3dState();
}

class _PanelScene3dState extends State<PanelScene3d> {
  double? _dragYaw;
  double? _dragPitch;
  double _lastX = 0.5;
  double _lastY = 0.5;
  Mesh3d? _loadedModel;
  String _loadedKey = '';

  @override
  void initState() {
    super.initState();
    _syncModel();
  }

  @override
  void didUpdateWidget(PanelScene3d oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.model != widget.spec.model ||
        oldWidget.baseFile != widget.baseFile) {
      _syncModel();
    }
  }

  void _syncModel() {
    final key = '${widget.baseFile}|${widget.spec.model}';
    if (key == _loadedKey) return;
    _loadedKey = key;
    if (widget.spec.model.isEmpty) {
      _loadedModel = null;
      return;
    }
    final bytes = readRelativeBytes(widget.baseFile, widget.spec.model);
    if (bytes == null) {
      _loadedModel = null;
      return;
    }
    final lower = widget.spec.model.toLowerCase();
    _loadedModel = lower.endsWith('.glb')
        ? parseGlbMesh(bytes)
        : (lower.endsWith('.obj')
              ? parseObjMesh(utf8.decode(bytes, allowMalformed: true))
              : null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = PanelThemeScope.of(context);
    final st = widget.style;
    final h = Shape.z(widget.height);
    final yaw = _dragYaw ?? widget.spec.yaw;
    final pitch = _dragPitch ?? widget.spec.pitch;
    final bg1 =
        resolvePanelColor(widget.spec.bg) ??
        resolvePanelColor(st?.bg ?? '') ??
        (widget.framed ? InspectorSkin.well : null);
    final bg2 =
        resolvePanelColor(widget.spec.bg2) ?? resolvePanelColor(st?.bg2 ?? '');
    final borderCol =
        resolvePanelColor(st?.border ?? '') ?? theme.border ?? Grey.g26;
    final rad = st?.radius ?? theme.radius ?? 6.0;
    final bw = st?.borderWidth ?? theme.borderWidth ?? 1.0;

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
            final paint = CustomPaint(
              size: size,
              painter: Draw(
                (c, s) => _paintScene3d(
                  c,
                  s,
                  spec: widget.spec,
                  yaw: yaw,
                  pitch: pitch,
                  bg1: bg1,
                  bg2: bg2,
                  defaultAccent: theme.accent ?? Accent.fill,
                  loadedModel: _loadedModel,
                ),
                (
                  widget.spec.shape,
                  widget.spec.look,
                  yaw,
                  pitch,
                  widget.spec.roll,
                  widget.spec.zoom,
                  widget.spec.color,
                  widget.spec.color2,
                  widget.spec.lightYaw,
                  widget.spec.lightPitch,
                  widget.spec.warp,
                  widget.spec.phase,
                  widget.spec.harmonics,
                  widget.spec.grid,
                  widget.spec.axes,
                  widget.spec.objects.length,
                  _loadedModel,
                ),
              ),
            );
            final surface = widget.framed
                ? Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: bg1,
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
                      child: paint,
                    ),
                  )
                : SizedBox(
                    height: h,
                    child: ClipRect(child: paint),
                  );

            if (!widget.interactive || widget.onOrbit == null) return surface;
            return GestureDetector(
              key: widget.surfaceKey,
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) {
                _dragYaw = widget.spec.yaw;
                _dragPitch = widget.spec.pitch;
                _lastX = (d.localPosition.dx / math.max(1.0, size.width)).clamp(
                  0.0,
                  1.0,
                );
                _lastY = (d.localPosition.dy / math.max(1.0, size.height))
                    .clamp(0.0, 1.0);
                widget.onOrbit!(
                  _dragYaw!,
                  _dragPitch!,
                  _lastX,
                  _lastY,
                  'down',
                  live: true,
                );
              },
              onPanUpdate: (d) {
                final fine = HardwareKeyboard.instance.isShiftPressed
                    ? 0.3
                    : 1.0;
                _dragYaw =
                    (_dragYaw ?? widget.spec.yaw) + d.delta.dx * 0.018 * fine;
                _dragPitch =
                    ((_dragPitch ?? widget.spec.pitch) +
                            d.delta.dy * 0.016 * fine)
                        .clamp(-1.45, 1.45);
                _lastX = (d.localPosition.dx / math.max(1.0, size.width)).clamp(
                  0.0,
                  1.0,
                );
                _lastY = (d.localPosition.dy / math.max(1.0, size.height))
                    .clamp(0.0, 1.0);
                setState(() {});
                widget.onOrbit!(
                  _dragYaw!,
                  _dragPitch!,
                  _lastX,
                  _lastY,
                  'drag',
                  live: true,
                );
              },
              onPanEnd: (_) {
                final fy = _dragYaw ?? widget.spec.yaw;
                final fp = _dragPitch ?? widget.spec.pitch;
                setState(() {
                  _dragYaw = null;
                  _dragPitch = null;
                });
                widget.onOrbit!(fy, fp, _lastX, _lastY, 'up');
              },
              child: surface,
            );
          },
        ),
      ],
    );
  }
}

/// Unit-normalized triangle/polygon mesh rendered by [PanelScene3d].
class Mesh3d {
  const Mesh3d(this.verts, this.faces);
  final List<Vector3> verts;
  final List<List<int>> faces;
}

class _ProjectedTri {
  const _ProjectedTri({
    required this.points,
    required this.depth,
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.isEdgeOnly,
  });

  final List<Offset> points;
  final double depth;
  final Color? fill;
  final Color? stroke;
  final double strokeWidth;
  final bool isEdgeOnly;
}

void _paintScene3d(
  Canvas c,
  Size s, {
  required Scene3dSpec spec,
  required double yaw,
  required double pitch,
  required Color? bg1,
  required Color? bg2,
  required Color defaultAccent,
  required Mesh3d? loadedModel,
}) {
  final rect = Offset.zero & s;
  if (bg1 != null && bg2 != null) {
    c.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bg1, bg2],
        ).createShader(rect),
    );
  } else if (bg1 != null) {
    c.drawRect(rect, Paint()..color = bg1);
  }

  final cx = s.width * 0.5;
  final cy = s.height * 0.52;
  final scale = math.min(s.width, s.height) * 0.44 * spec.zoom;
  const camDist = 3.8;

  final viewMat = Matrix4.identity()
    ..rotateX(pitch)
    ..rotateY(yaw)
    ..rotateZ(spec.roll);

  Offset project(Vector3 p) {
    final z = camDist - p.z;
    final persp = camDist / math.max(0.4, z);
    return Offset(cx + p.x * scale * persp, cy - p.y * scale * persp);
  }

  // Optional floor grid (studio / Serum / CAD look).
  if (spec.grid) {
    final gridCol = spec.look == 'toon'
        ? DarkGrey.g00.withValues(alpha: 0.14)
        : (spec.look == 'holo' || spec.look == 'wireframe'
              ? (resolvePanelColor(spec.color) ?? defaultAccent).withValues(
                  alpha: 0.22,
                )
              : Grey.g56.withValues(alpha: 0.24));
    final gp = Paint()
      ..color = gridCol
      ..strokeWidth = 0.9;
    const n = 5;
    const floorY = -0.95;
    const half = 1.4;
    for (var i = -n; i <= n; i++) {
      final f = (i / n) * half;
      final a = viewMat.transformed3(Vector3(f, floorY, -half));
      final b = viewMat.transformed3(Vector3(f, floorY, half));
      c.drawLine(project(a), project(b), gp);
      final d = viewMat.transformed3(Vector3(-half, floorY, f));
      final e = viewMat.transformed3(Vector3(half, floorY, f));
      c.drawLine(project(d), project(e), gp);
    }
  }

  // Soft studio or hard pop floor shadow beneath object.
  if (spec.shadow &&
      spec.look != 'wireframe' &&
      spec.look != 'holo' &&
      spec.shape != 'wavetable') {
    final shadowCenter = Offset(
      cx + (spec.look == 'toon' ? 8.0 : 0.0),
      cy + scale * 0.86,
    );
    final rx = scale * 0.72;
    final ry = scale * 0.22;
    if (spec.look == 'toon') {
      c.drawOval(
        Rect.fromCenter(
          center: shadowCenter,
          width: rx * 1.7,
          height: ry * 1.5,
        ),
        Paint()..color = DarkGrey.g00.withValues(alpha: 0.22),
      );
    } else {
      c.drawOval(
        Rect.fromCenter(
          center: shadowCenter,
          width: rx * 2.1,
          height: ry * 2.1,
        ),
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  DarkGrey.g00.withValues(alpha: 0.42),
                  DarkGrey.g00.withValues(alpha: 0.0),
                ],
              ).createShader(
                Rect.fromCenter(
                  center: shadowCenter,
                  width: rx * 2.1,
                  height: ry * 2.1,
                ),
              ),
      );
    }
  }

  // Optional 3D XYZ axes gizmo.
  if (spec.axes || spec.shape == 'gizmo') {
    final o = project(viewMat.transformed3(Vector3.zero()));
    void axis(Vector3 v, Color col) {
      final end = project(viewMat.transformed3(v));
      c.drawLine(
        o,
        end,
        Paint()
          ..color = col
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(end, 3.0, Paint()..color = col);
    }

    axis(Vector3(1.15, 0, 0), InspectorSkin.alert);
    axis(Vector3(0, 1.15, 0), InspectorSkin.toneBlend);
    axis(Vector3(0, 0, 1.15), InspectorSkin.toneLayout);
  }

  // Dedicated Serum/Vital glowing 3D wavetable terrain renderer.
  if (spec.shape == 'wavetable') {
    _paintWavetable3d(
      c,
      viewMat: viewMat,
      project: project,
      spec: spec,
      defaultAccent: defaultAccent,
    );
    return;
  }

  final keyLight = Vector3(
    math.cos(spec.lightPitch) * math.sin(spec.lightYaw),
    math.sin(spec.lightPitch),
    math.cos(spec.lightPitch) * math.cos(spec.lightYaw),
  )..normalize();
  final rimLight = Vector3(-keyLight.x, 0.35, -keyLight.z)..normalize();
  final viewDir = Vector3(0, 0, 1);

  final baseColor = resolvePanelColor(spec.color) ?? defaultAccent;
  final baseColor2 = resolvePanelColor(spec.color2);
  final rimCol =
      resolvePanelColor(spec.rimColor) ??
      Color.lerp(baseColor, DarkGrey.g100, 0.55)!;
  final outlineCol =
      resolvePanelColor(spec.outline) ??
      (spec.look == 'toon'
          ? DarkGrey.g00
          : (spec.look == 'wireframe' || spec.look == 'holo'
                ? baseColor
                : baseColor.withValues(alpha: 0.35)));

  final tris = <_ProjectedTri>[];

  void emitMesh(Mesh3d mesh, Matrix4 localMat, Color col, String look) {
    final xf = viewMat * localMat;
    final transformed = [for (final v in mesh.verts) xf.transformed3(v)];
    final projected = [for (final v in transformed) project(v)];

    for (var fi = 0; fi < mesh.faces.length; fi++) {
      final f = mesh.faces[fi];
      if (f.length < 3) continue;
      final v0 = transformed[f[0]];
      final v1 = transformed[f[1]];
      final v2 = transformed[f[2]];
      final normal = (v1 - v0).cross(v2 - v0);
      final len = normal.length;
      if (len < 1e-6) continue;
      normal.scale(1.0 / len);

      final front = normal.z > -0.02;
      if (!front && look != 'wireframe' && look != 'holo') continue;

      var avgZ = 0.0;
      for (final idx in f) {
        avgZ += transformed[idx].z;
      }
      avgZ /= f.length;

      final pts = [for (final idx in f) projected[idx]];
      final faceTint = baseColor2 != null
          ? Color.lerp(col, baseColor2, ((v0.y + 1.0) * 0.5).clamp(0.0, 1.0))!
          : col;

      if (look == 'wireframe') {
        tris.add(
          _ProjectedTri(
            points: pts,
            depth: avgZ,
            fill: null,
            stroke: faceTint.withValues(alpha: front ? 0.92 : 0.25),
            strokeWidth: front ? 1.35 : 0.7,
            isEdgeOnly: true,
          ),
        );
        continue;
      }

      if (look == 'holo') {
        final fresnel = (1.0 - normal.z.abs()).clamp(0.0, 1.0);
        final alpha = front ? (0.14 + 0.30 * fresnel) : 0.06;
        tris.add(
          _ProjectedTri(
            points: pts,
            depth: avgZ,
            fill: faceTint.withValues(alpha: alpha),
            stroke: faceTint.withValues(alpha: front ? 0.78 : 0.20),
            strokeWidth: front ? 1.1 : 0.55,
            isEdgeOnly: false,
          ),
        );
        continue;
      }

      final ndl = normal.dot(keyLight).clamp(0.0, 1.0);
      final halfVec = (keyLight + viewDir)..normalize();
      final ndh = normal.dot(halfVec).clamp(0.0, 1.0);
      final rim =
          math.pow((1.0 - normal.z.clamp(0.0, 1.0)), 2.2).toDouble() *
          (0.35 + 0.65 * normal.dot(rimLight).clamp(0.0, 1.0));

      late Color shaded;
      Color? edgeCol;
      var edgeW = 0.6;
      if (look == 'toon') {
        // Crisp 3-step cel shading + bold ink outline (Flat-Pop VST look).
        if (ndl > 0.72) {
          shaded = Color.lerp(faceTint, DarkGrey.g100, 0.28)!;
        } else if (ndl > 0.26) {
          shaded = faceTint;
        } else {
          shaded = Color.lerp(faceTint, DarkGrey.g00, 0.30)!;
        }
        edgeCol = outlineCol;
        edgeW = spec.outlineWidth;
      } else if (look == 'clay') {
        final l = 0.24 + 0.68 * ndl;
        shaded = Color.lerp(DarkGrey.g00, faceTint, l)!;
        edgeCol = shaded;
        edgeW = 0.5;
      } else {
        // `studio`: smooth diffuse + Blinn-Phong specular + rim glow + optional colored bounce light.
        final ambCol = resolvePanelColor(spec.ambientColor) ?? DarkGrey.g00;
        final specAmt = math.pow(ndh, 28.0).toDouble() * spec.gloss;
        final diffuse = (spec.ambient + (1.0 - spec.ambient) * ndl).clamp(
          0.0,
          1.0,
        );
        shaded = Color.lerp(ambCol, faceTint, diffuse)!;
        if (rim > 0.02) {
          shaded = Color.lerp(shaded, rimCol, (rim * 0.58).clamp(0.0, 0.75))!;
        }
        if (specAmt > 0.01) {
          shaded = Color.lerp(shaded, DarkGrey.g100, specAmt.clamp(0.0, 0.90))!;
        }
        edgeCol = spec.wireframe ? outlineCol : shaded;
        edgeW = spec.wireframe ? 0.9 : 0.45;
      }

      tris.add(
        _ProjectedTri(
          points: pts,
          depth: avgZ,
          fill: shaded,
          stroke: edgeCol,
          strokeWidth: edgeW,
          isEdgeOnly: false,
        ),
      );
    }
  }

  final mainMesh = loadedModel ?? _buildMesh(spec);
  if (mainMesh != null) {
    emitMesh(mainMesh, Matrix4.identity(), baseColor, spec.look);
  }
  for (final obj in spec.objects) {
    final m = _primitiveMesh(obj.shape);
    if (m == null) continue;
    final mat = Matrix4.identity()
      ..translateByDouble(obj.x, obj.y, obj.z, 1.0)
      ..rotateX(obj.rx)
      ..rotateY(obj.ry)
      ..rotateZ(obj.rz)
      ..scaleByDouble(obj.scale, obj.scale, obj.scale, 1.0);
    emitMesh(
      m,
      mat,
      resolvePanelColor(obj.color) ?? baseColor,
      obj.look.isEmpty ? spec.look : obj.look,
    );
  }

  // Painter's algorithm (back-to-front depth sort).
  tris.sort((a, b) => a.depth.compareTo(b.depth));

  // For `toon` look, first draw a bold exterior silhouette pass for clean sticker pop.
  if (spec.look == 'toon' && tris.isNotEmpty) {
    final silPaint = Paint()
      ..color = outlineCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = spec.outlineWidth * 2.4
      ..strokeJoin = StrokeJoin.round;
    for (final t in tris) {
      final path = _polyPath(t.points);
      c.drawPath(path, silPaint);
    }
  }

  for (final t in tris) {
    final path = _polyPath(t.points);
    if (t.fill != null) {
      c.drawPath(path, Paint()..color = t.fill!);
    }
    if (t.stroke != null) {
      c.drawPath(
        path,
        Paint()
          ..color = t.stroke!
          ..style = PaintingStyle.stroke
          ..strokeWidth = t.strokeWidth
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }
}

Path _polyPath(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    p.lineTo(pts[i].dx, pts[i].dy);
  }
  p.close();
  return p;
}

/// Serum / Vital style 3D stacked wavetable terrain renderer.
void _paintWavetable3d(
  Canvas c, {
  required Matrix4 viewMat,
  required Offset Function(Vector3) project,
  required Scene3dSpec spec,
  required Color defaultAccent,
}) {
  final colA = resolvePanelColor(spec.color) ?? defaultAccent;
  final colB =
      resolvePanelColor(spec.color2) ??
      Color.lerp(colA, InspectorSkin.toneTime, 0.65)!;
  const slices = 15;
  const cols = 42;
  final warp = spec.warp;
  final phase = spec.phase;
  final harm = spec.harmonics.clamp(1.0, 8.0);

  for (var si = 0; si < slices; si++) {
    final zFrac = si / (slices - 1);
    final z = -1.15 + zFrac * 2.3;
    final path = Path();
    final fillPath = Path();
    Offset? firstPt;
    Offset? lastPt;
    for (var ci = 0; ci <= cols; ci++) {
      final xFrac = ci / cols;
      final x = -1.35 + xFrac * 2.7;
      final env = math.sin(xFrac * math.pi);
      final w1 = math.sin(xFrac * math.pi * 2.0 * harm + phase + zFrac * 3.8);
      final w2 =
          math.sin(xFrac * math.pi * 4.0 * (1.0 + warp) - zFrac * 5.0) * warp;
      final y = (w1 * 0.48 + w2 * 0.34) * env;
      final pt = project(viewMat.transformed3(Vector3(x, y, z)));
      if (ci == 0) {
        firstPt = pt;
        path.moveTo(pt.dx, pt.dy);
        fillPath.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
        fillPath.lineTo(pt.dx, pt.dy);
      }
      lastPt = pt;
    }
    if (firstPt != null && lastPt != null) {
      final baseR = project(viewMat.transformed3(Vector3(1.35, -0.55, z)));
      final baseL = project(viewMat.transformed3(Vector3(-1.35, -0.55, z)));
      fillPath
        ..lineTo(baseR.dx, baseR.dy)
        ..lineTo(baseL.dx, baseL.dy)
        ..close();
      final sliceCol = Color.lerp(colB, colA, zFrac)!;
      c.drawPath(
        fillPath,
        Paint()..color = sliceCol.withValues(alpha: 0.05 + 0.14 * zFrac),
      );
      // Outer neon glow on front slices
      if (si >= slices - 4) {
        c.drawPath(
          path,
          Paint()
            ..color = sliceCol.withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.2,
        );
      }
      c.drawPath(
        path,
        Paint()
          ..color = sliceCol.withValues(alpha: 0.32 + 0.68 * zFrac)
          ..style = PaintingStyle.stroke
          ..strokeWidth = si == slices - 1 ? 2.1 : 1.15,
      );
    }
  }
}

Mesh3d? _buildMesh(Scene3dSpec spec) {
  if (spec.vertices.isNotEmpty && spec.faces.isNotEmpty) {
    return Mesh3d([
      for (final v in spec.vertices) Vector3(v[0], v[1], v[2]),
    ], spec.faces);
  }
  if (spec.shape == 'gizmo') return null;
  return _primitiveMesh(spec.shape);
}

Mesh3d? _primitiveMesh(String shape) => switch (shape) {
  'cube' => _cubeMesh(),
  'sphere' => _sphereMesh(22, 34),
  'torus' => _torusMesh(20, 12, 0.72, 0.28),
  'icosahedron' => _icosahedronMesh(),
  'crystal' => _crystalMesh(),
  'pyramid' => _pyramidMesh(),
  'cone' => _coneMesh(18),
  'cylinder' => _cylinderMesh(18),
  'ring' => _torusMesh(24, 6, 0.92, 0.08),
  _ => _cubeMesh(),
};

Mesh3d _cubeMesh() {
  const s = 0.74;
  final v = [
    Vector3(-s, -s, s),
    Vector3(s, -s, s),
    Vector3(s, s, s),
    Vector3(-s, s, s),
    Vector3(-s, -s, -s),
    Vector3(s, -s, -s),
    Vector3(s, s, -s),
    Vector3(-s, s, -s),
  ];
  const f = [
    [0, 1, 2, 3],
    [5, 4, 7, 6],
    [4, 0, 3, 7],
    [1, 5, 6, 2],
    [3, 2, 6, 7],
    [4, 5, 1, 0],
  ];
  return Mesh3d(v, f);
}

Mesh3d _pyramidMesh() {
  const s = 0.85;
  final v = [
    Vector3(0, 0.92, 0),
    Vector3(-s, -0.68, s),
    Vector3(s, -0.68, s),
    Vector3(s, -0.68, -s),
    Vector3(-s, -0.68, -s),
  ];
  const f = [
    [0, 1, 2],
    [0, 2, 3],
    [0, 3, 4],
    [0, 4, 1],
    [4, 3, 2, 1],
  ];
  return Mesh3d(v, f);
}

Mesh3d _crystalMesh() {
  const sides = 6;
  const r = 0.62;
  final v = <Vector3>[
    Vector3(0, 1.08, 0),
    for (var i = 0; i < sides; i++)
      Vector3(
        math.cos(i * math.pi * 2 / sides) * r,
        0.24,
        math.sin(i * math.pi * 2 / sides) * r,
      ),
    for (var i = 0; i < sides; i++)
      Vector3(
        math.cos((i + 0.5) * math.pi * 2 / sides) * r * 0.86,
        -0.30,
        math.sin((i + 0.5) * math.pi * 2 / sides) * r * 0.86,
      ),
    Vector3(0, -1.05, 0),
  ];
  final bot = v.length - 1;
  final f = <List<int>>[];
  for (var i = 0; i < sides; i++) {
    final n = (i + 1) % sides;
    final u0 = 1 + i;
    final u1 = 1 + n;
    final l0 = 1 + sides + i;
    final l1 = 1 + sides + ((i + sides - 1) % sides);
    f.add([0, u1, u0]);
    f.add([u0, u1, l0]);
    f.add([u0, l0, l1]);
    f.add([bot, l0, 1 + sides + n]);
  }
  return Mesh3d(v, f);
}

Mesh3d _icosahedronMesh() {
  const t = 1.618033988749895;
  final raw = [
    Vector3(-1, t, 0),
    Vector3(1, t, 0),
    Vector3(-1, -t, 0),
    Vector3(1, -t, 0),
    Vector3(0, -1, t),
    Vector3(0, 1, t),
    Vector3(0, -1, -t),
    Vector3(0, 1, -t),
    Vector3(t, 0, -1),
    Vector3(t, 0, 1),
    Vector3(-t, 0, -1),
    Vector3(-t, 0, 1),
  ];
  final v = [for (final p in raw) p.normalized() * 0.96];
  const f = [
    [0, 11, 5],
    [0, 5, 1],
    [0, 1, 7],
    [0, 7, 10],
    [0, 10, 11],
    [1, 5, 9],
    [5, 11, 4],
    [11, 10, 2],
    [10, 7, 6],
    [7, 1, 8],
    [3, 9, 4],
    [3, 4, 2],
    [3, 2, 6],
    [3, 6, 8],
    [3, 8, 9],
    [4, 9, 5],
    [2, 4, 11],
    [6, 2, 10],
    [8, 6, 7],
    [9, 8, 1],
  ];
  return Mesh3d(v, f);
}

Mesh3d _sphereMesh(int lat, int lon) {
  final v = <Vector3>[];
  final f = <List<int>>[];
  for (var i = 0; i <= lat; i++) {
    final theta = i * math.pi / lat;
    final sinT = math.sin(theta);
    final cosT = math.cos(theta);
    for (var j = 0; j < lon; j++) {
      final phi = j * 2 * math.pi / lon;
      v.add(Vector3(sinT * math.cos(phi), cosT, sinT * math.sin(phi)) * 0.92);
    }
  }
  for (var i = 0; i < lat; i++) {
    for (var j = 0; j < lon; j++) {
      final nj = (j + 1) % lon;
      final a = i * lon + j;
      final b = i * lon + nj;
      final c = (i + 1) * lon + nj;
      final d = (i + 1) * lon + j;
      if (i != 0) f.add([a, b, d]);
      if (i != lat - 1) f.add([b, c, d]);
    }
  }
  return Mesh3d(v, f);
}

Mesh3d _torusMesh(int major, int minor, double rMajor, double rMinor) {
  final v = <Vector3>[];
  final f = <List<int>>[];
  for (var i = 0; i < major; i++) {
    final u = i * 2 * math.pi / major;
    final cu = math.cos(u);
    final su = math.sin(u);
    for (var j = 0; j < minor; j++) {
      final w = j * 2 * math.pi / minor;
      final cw = math.cos(w);
      final sw = math.sin(w);
      final rr = rMajor + rMinor * cw;
      v.add(Vector3(rr * cu, rMinor * sw, rr * su));
    }
  }
  for (var i = 0; i < major; i++) {
    final ni = (i + 1) % major;
    for (var j = 0; j < minor; j++) {
      final nj = (j + 1) % minor;
      final a = i * minor + j;
      final b = ni * minor + j;
      final c = ni * minor + nj;
      final d = i * minor + nj;
      f.add([a, b, c, d]);
    }
  }
  return Mesh3d(v, f);
}

Mesh3d _coneMesh(int sides) {
  final v = <Vector3>[Vector3(0, 0.95, 0), Vector3(0, -0.75, 0)];
  for (var i = 0; i < sides; i++) {
    final a = i * 2 * math.pi / sides;
    v.add(Vector3(math.cos(a) * 0.78, -0.75, math.sin(a) * 0.78));
  }
  final f = <List<int>>[];
  for (var i = 0; i < sides; i++) {
    final cur = 2 + i;
    final nxt = 2 + (i + 1) % sides;
    f.add([0, nxt, cur]);
    f.add([1, cur, nxt]);
  }
  return Mesh3d(v, f);
}

Mesh3d _cylinderMesh(int sides) {
  final v = <Vector3>[Vector3(0, 0.78, 0), Vector3(0, -0.78, 0)];
  for (var i = 0; i < sides; i++) {
    final a = i * 2 * math.pi / sides;
    v.add(Vector3(math.cos(a) * 0.68, 0.78, math.sin(a) * 0.68));
    v.add(Vector3(math.cos(a) * 0.68, -0.78, math.sin(a) * 0.68));
  }
  final f = <List<int>>[];
  for (var i = 0; i < sides; i++) {
    final t0 = 2 + i * 2;
    final b0 = t0 + 1;
    final t1 = 2 + ((i + 1) % sides) * 2;
    final b1 = t1 + 1;
    f.add([t0, t1, b1, b0]);
    f.add([0, t1, t0]);
    f.add([1, b0, b1]);
  }
  return Mesh3d(v, f);
}

/// Parses a standard Wavefront `.obj` mesh into a unit-normalized [Mesh3d].
Mesh3d? parseObjMesh(String src) {
  final verts = <Vector3>[];
  final faces = <List<int>>[];
  for (final raw in src.split('\n')) {
    final line = raw.trim();
    if (line.startsWith('v ')) {
      final p = line.split(RegExp(r'\s+'));
      if (p.length >= 4) {
        final x = double.tryParse(p[1]);
        final y = double.tryParse(p[2]);
        final z = double.tryParse(p[3]);
        if (x != null && y != null && z != null) verts.add(Vector3(x, y, z));
      }
    } else if (line.startsWith('f ')) {
      final p = line.split(RegExp(r'\s+')).skip(1);
      final idx = <int>[];
      for (final tok in p) {
        final vIdx = int.tryParse(tok.split('/').first);
        if (vIdx != null) {
          final resolved = vIdx < 0 ? verts.length + vIdx : vIdx - 1;
          if (resolved >= 0 && resolved < verts.length) idx.add(resolved);
        }
      }
      if (idx.length >= 3) faces.add(idx);
    }
  }
  return _normalizeMesh(verts, faces);
}

/// Parses a binary glTF 2.0 (`.glb`) first mesh primitive into a unit-normalized [Mesh3d].
Mesh3d? parseGlbMesh(Uint8List bytes) {
  if (bytes.length < 20) return null;
  final bd = ByteData.sublistView(bytes);
  // Magic 'glTF' ASCII header, version 2.
  if (bytes[0] != 0x67 ||
      bytes[1] != 0x6C ||
      bytes[2] != 0x54 ||
      bytes[3] != 0x46) {
    return null;
  }
  var off = 12;
  Map<String, Object?>? jsonChunk;
  Uint8List? binChunk;
  while (off + 8 <= bytes.length) {
    final len = bd.getUint32(off, Endian.little);
    final chunkTag = utf8.decode(
      bytes.sublist(off + 4, off + 8),
      allowMalformed: true,
    );
    off += 8;
    if (off + len > bytes.length) break;
    if (chunkTag == 'JSON') {
      final decoded = jsonDecode(utf8.decode(bytes.sublist(off, off + len)));
      if (decoded is Map<String, Object?>) jsonChunk = decoded;
    } else if (chunkTag == 'BIN\x00') {
      binChunk = bytes.sublist(off, off + len);
    }
    off += len;
  }
  if (jsonChunk == null || binChunk == null) return null;
  final meshes = jsonChunk['meshes'];
  final accessors = jsonChunk['accessors'];
  final views = jsonChunk['bufferViews'];
  if (meshes is! List ||
      meshes.isEmpty ||
      accessors is! List ||
      views is! List) {
    return null;
  }
  final firstMesh = meshes.first;
  if (firstMesh is! Map || firstMesh['primitives'] is! List) return null;
  final prims = firstMesh['primitives'] as List;
  if (prims.isEmpty || prims.first is! Map) return null;
  final prim = prims.first as Map;
  final attrs = prim['attributes'];
  if (attrs is! Map || attrs['POSITION'] is! num) return null;

  final posAcc = accessors[(attrs['POSITION'] as num).toInt()] as Map;
  final posView = views[(posAcc['bufferView'] as num).toInt()] as Map;
  final posCount = (posAcc['count'] as num).toInt();
  final posOff =
      ((posView['byteOffset'] as num?)?.toInt() ?? 0) +
      ((posAcc['byteOffset'] as num?)?.toInt() ?? 0);
  final posStride = (posView['byteStride'] as num?)?.toInt() ?? 12;
  final binData = ByteData.sublistView(binChunk);
  final verts = <Vector3>[];
  for (var i = 0; i < posCount; i++) {
    final p = posOff + i * posStride;
    if (p + 12 > binChunk.length) break;
    verts.add(
      Vector3(
        binData.getFloat32(p, Endian.little),
        binData.getFloat32(p + 4, Endian.little),
        binData.getFloat32(p + 8, Endian.little),
      ),
    );
  }
  final faces = <List<int>>[];
  if (prim['indices'] is num) {
    final idxAcc = accessors[(prim['indices'] as num).toInt()] as Map;
    final idxView = views[(idxAcc['bufferView'] as num).toInt()] as Map;
    final idxCount = (idxAcc['count'] as num).toInt();
    final compType = (idxAcc['componentType'] as num).toInt();
    final idxOff =
        ((idxView['byteOffset'] as num?)?.toInt() ?? 0) +
        ((idxAcc['byteOffset'] as num?)?.toInt() ?? 0);
    final indices = <int>[];
    for (var i = 0; i < idxCount; i++) {
      if (compType == 5123 && idxOff + i * 2 + 2 <= binChunk.length) {
        indices.add(binData.getUint16(idxOff + i * 2, Endian.little));
      } else if (compType == 5125 && idxOff + i * 4 + 4 <= binChunk.length) {
        indices.add(binData.getUint32(idxOff + i * 4, Endian.little));
      } else if (compType == 5121 && idxOff + i < binChunk.length) {
        indices.add(binData.getUint8(idxOff + i));
      }
    }
    for (var i = 0; i + 2 < indices.length; i += 3) {
      faces.add([indices[i], indices[i + 1], indices[i + 2]]);
    }
  } else {
    for (var i = 0; i + 2 < verts.length; i += 3) {
      faces.add([i, i + 1, i + 2]);
    }
  }
  return _normalizeMesh(verts, faces);
}

Mesh3d? _normalizeMesh(List<Vector3> verts, List<List<int>> faces) {
  if (verts.isEmpty || faces.isEmpty) return null;
  var minV = verts.first.clone();
  var maxV = verts.first.clone();
  for (final v in verts.skip(1)) {
    minV = Vector3(
      math.min(minV.x, v.x),
      math.min(minV.y, v.y),
      math.min(minV.z, v.z),
    );
    maxV = Vector3(
      math.max(maxV.x, v.x),
      math.max(maxV.y, v.y),
      math.max(maxV.z, v.z),
    );
  }
  final center = (minV + maxV) * 0.5;
  final extent = math.max(
    1e-4,
    math.max(maxV.x - minV.x, math.max(maxV.y - minV.y, maxV.z - minV.z)),
  );
  final inv = 1.65 / extent;
  return Mesh3d([for (final v in verts) (v - center) * inv], faces);
}
