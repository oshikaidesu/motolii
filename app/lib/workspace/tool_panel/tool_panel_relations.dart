// The Relations tab: the layers seen from outside the camera, as the Depth tab shows depth.
// It draws every layer where it is (including off camera), the camera's frame, and each relation as its shape:
// a ring, a row, the reach of a push, or the threads of a follow.
// The user views it from the front or top, or turns it by dragging. Tapping picks a layer or a relation, which the inspector shows.
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/tool_strip.dart';
import 'package:motolii/widgets/paint_helpers.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';

class RelationsTool extends StatefulWidget {
  const RelationsTool({super.key});
  @override
  State<RelationsTool> createState() => _RelationsToolState();
}

class _RelationsToolState extends State<RelationsTool> {
  // Yaw and pitch of the view; 0, 0 looks from the front, in the camera's own direction. Scrolling zooms in.
  double _yaw = 0, _pitch = 0, _zoom = 1;
  // Each layer's path over the whole duration for one document revision. Requested again when the revision changes.
  (int, Map<String, List<_P3>>)? _paths;
  int? _pathsAsked;
  Object? _stationsAsked;

  /// A picked relation's layers at the time of each of its keyframes, in time order.
  /// These are the shapes the relation passes through, not the path between them.
  /// They are times other than the one the preview shows, so they are requested from the engine (another isolate) and shown when they arrive.
  (Object, Map<String, List<_P3>>)? _stations;
  Map<String, List<_P3>> _stationsOf(Ws ws) {
    final m = ws.inside, r = int.tryParse(ws.selected ?? '');
    final at = (ws.rev, ws.selected);
    if (_stations?.$1 == at || _stationsAsked == at || m == null) return _stations?.$2 ?? const {};
    _stationsAsked = at;
    final moments = r != null && m.word(r, 'kind') == 'behaviour' ? ({for (final n in m.moving(r)) ...m.keyTimes(r, n)}.toList()..sort()) : <double>[];
    final members = [
      for (final s in r == null ? const <String>[] : m.word(r, 'members').split(' '))
        if (int.tryParse(s) case final t? when moments.length > 1) t,
    ];
    m
        .shownAt([
          for (final t in members)
            for (final a in moments)
              for (final n in const ['x', 'y', 'z']) (t, n, a),
        ])
        .then((v) {
          if (!mounted) return;
          var i = 0;
          double next() => v[i++] ?? 0;
          setState(
            () => _stations = (
              at,
              {
                for (final t in members) '$t': [for (final _ in moments) (x: next(), y: next(), z: next())],
              },
            ),
          );
        });
    return _stations?.$2 ?? const {};
  }

  Map<String, List<_P3>> _pathsOf(Ws ws) {
    final m = ws.inside;
    if (_paths?.$1 == ws.rev || _pathsAsked == ws.rev || m == null) return _paths?.$2 ?? const {};
    final rev = _pathsAsked = ws.rev;
    const steps = 60;
    final things = [
      for (final l in ws.layers)
        if (int.tryParse(l.id) case final t? when m.word(t, 'kind') != 'behaviour' && m.word(t, 'kind') != 'camera') t,
    ];
    m
        .shownAt([
          for (final t in things)
            for (var k = 0; k <= steps; k++)
              for (final n in const ['x', 'y', 'z']) (t, n, k / steps * Ws.duration / Ws.fps),
        ])
        .then((v) {
          if (!mounted) return;
          var i = 0;
          double next() => v[i++] ?? 0;
          final out = <String, List<_P3>>{};
          for (final t in things) {
            final way = [for (var k = 0; k <= steps; k++) (x: next(), y: next(), z: next())];
            // Keep only the layers that move.
            if (way.any((p) => (p.x - way.first.x).abs() + (p.y - way.first.y).abs() + (p.z - way.first.z).abs() > 1e-4)) out['$t'] = way;
          }
          setState(() => _paths = (rev, out));
        });
    return _paths?.$2 ?? const {};
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      WsScope.read(context).on[WsAspect.document],
      WsScope.read(context).on[WsAspect.picked],
      // Changes with the frame the preview shows, which decides where the layers are.
      WsScope.read(context).seen,
    ]),
    builder: (context, _) {
      final ws = WsScope.read(context), world = _World.of(ws), together = wsRelatable(ws).length, many = together > 1;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolStrip(
            left: [Chip(label: 'Relations · ${world.relations.length}', look: ChipLook.flat(WsT.toneGroup))],
          ),
          ColoredBox(
            // The row names what the tab is for in the words that do it, as the top of the preview does.
            // Blender's Constraints tab also holds its own Add menu.
            color: WsT.card,
            child: Padding(
              padding: EdgeInsets.fromLTRB(WsT.inset, 0, WsT.inset, Shape.s(5)),
              child: Wrap(
                spacing: Shape.s(4),
                runSpacing: Shape.s(4),
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(many ? '$together picked' : 'Pick two or more', style: T.micro(Grey.g63)),
                  for (final k in wsRelationChoices(ws))
                    GestureDetector(
                      key: ValueKey('ws-tab-relate-$k'),
                      onTap: many ? () => wsRelate(ws, k) : null,
                      child: IntrinsicWidth(
                        child: Chip(label: wsRelationWord(k), look: ChipLook.flat(many ? WsT.accent : Grey.g38)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WsT.gutter),
          Expanded(
            child: ColoredBox(
              color: WsT.card,
              child: LayoutBuilder(
                builder: (context, box) {
                  final view = _View(world, box.biggest, _yaw, _pitch, paths: _pathsOf(ws), zoom: _zoom);
                  // Two fingers on a trackpad turn the view, as in Blender, through the drag handler below. A pinch zooms in.
                  return WsTwoFingers(
                    onWheel: (d) => setState(() => _zoom = (_zoom * math.exp(-d.dy / 300)).clamp(.3, 8.0)),
                    onPinch: (by, _) => setState(() => _zoom = (_zoom * by).clamp(.3, 8.0)),
                    child: GestureDetector(
                      key: const ValueKey('ws-relations-map'),
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (d) => setState(() {
                        _yaw += d.delta.dx * .01;
                        _pitch = (_pitch - d.delta.dy * .01).clamp(-math.pi / 2, math.pi / 2);
                      }),
                      onTapUp: (d) {
                        if (view.axisAt(d.localPosition) case final a?) {
                          // Tapping an axis of the gizmo looks from that side, as in Blender.
                          final (yaw, pitch) = switch (a) {
                            'x' => (-math.pi / 2, 0.0),
                            'y' => (0.0, -math.pi / 2),
                            _ => (0.0, 0.0),
                          };
                          return setState(() {
                            _yaw = yaw;
                            _pitch = pitch;
                          });
                        }
                        if (view.hit(d.localPosition) case final id?) ws.select(id);
                      },
                      child: CustomPaint(
                        size: box.biggest,
                        painter: _Map(view, ws.selected, {if (_pathsOf(ws)[ws.selected] case final w?) ws.selected!: w}, _stationsOf(ws)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    },
  );
}

typedef _P3 = ({double x, double y, double z});

/// What the map draws, read from the engine: the layers, the camera and the relations.
class _World {
  _World(this.things, this.camera, this.relations, this.half);

  /// Layers by id: position, colour and name.
  final Map<String, (_P3, Color, String)> things;
  final _P3? camera;
  final List<_Relation> relations;

  /// Half the camera's frame, in the canvas's units.
  final Size half;

  static _World of(Ws ws) {
    final m = ws.inside;
    if (m == null) return _World(const {}, null, const [], Size.zero);
    // The time of the frame the preview shows.
    final now = m.now, things = <String, (_P3, Color, String)>{};
    _P3? camera;
    // Prefer the position where the layer is shown, since a relation moves depth too.
    double v(int t, String n) => (n == 'x' || n == 'y' || n == 'z' ? m.shows(t, n, now)?.$1 : null) ?? m.value(t, n, now) ?? 0;
    final rels = <_Relation>[];
    for (final l in ws.layers) {
      final t = int.tryParse(l.id);
      if (t == null) continue;
      final kind = m.word(t, 'kind');
      if (kind == 'behaviour') {
        if (wsRelations.contains(m.word(t, 'file'))) {
          rels.add(
            _Relation(l.id, m.word(t, 'file'), [
              for (final s in m.word(t, 'members').split(' '))
                if (s != '_' && s.isNotEmpty) s,
            ], v),
          );
        }
        continue;
      }
      final at = (x: v(t, 'x'), y: v(t, 'y'), z: v(t, 'z'));
      if (kind == 'camera') {
        camera = at;
        continue;
      }
      things[l.id] = (at, l.tone, l.name); // The label colour, the same as its row's.
    }
    return _World(things, camera, rels, Size(WsArt.comp.width / 2 / m.point, WsArt.comp.height / 2 / m.point));
  }
}

/// A relation's shape in the world: its kind, its layers and the parameters that place it.
class _Relation {
  _Relation(this.id, this.kind, this.members, double Function(int, String) v)
    : radius = v(int.parse(id), 'radius'),
      gap = v(int.parse(id), 'gap'),
      tilt = v(int.parse(id), 'tilt') * math.pi / 180,
      centre = (x: v(int.parse(id), 'centre_x'), y: v(int.parse(id), 'centre_y'), z: 0.0),
      leader = '${v(int.parse(id), 'leader').round()}';
  final String id, kind, leader;
  final List<String> members;
  final double radius, gap, tilt;
  final _P3 centre;
}

/// The world rotated and fitted to the map.
class _View {
  _View(this.world, this.size, double yaw, double pitch, {Map<String, List<_P3>> paths = const {}, double zoom = 1})
    : _cy = math.cos(yaw),
      _sy = math.sin(yaw),
      _cp = math.cos(pitch),
      _sp = math.sin(pitch) {
    // Fit to the layers and their paths, not the camera's frame, so what moves fills the map. Scrolling zooms in.
    final all = [
      for (final (p, _, _) in world.things.values) _turn(p),
      for (final w in paths.values)
        for (final p in w) _turn(p),
    ];
    if (all.isEmpty) all.addAll([for (final p in _frame) _turn(p)]);
    var r = Rect.fromCenter(center: all.first, width: .2, height: .2);
    for (final p in all) {
      r = r.expandToInclude(Rect.fromCenter(center: p, width: 0, height: 0));
    }
    _fit = r.inflate(r.longestSide * .08 + .05);
    _scale = math.min(size.width / _fit.width, size.height / _fit.height) * zoom;
  }
  final _World world;
  final Size size;
  final double _cy, _sy, _cp, _sp;
  late final Rect _fit;
  late final double _scale;

  List<_P3> get _frame => [
    for (final (sx, sy) in const [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)]) (x: sx * world.half.width, y: sy * world.half.height, z: 0.0),
  ];

  Offset _turn(_P3 p) {
    // Rotated about the up axis, then tilted: x to the right, y up on the map.
    final x = p.x * _cy + p.z * _sy, z = -p.x * _sy + p.z * _cy;
    return Offset(x, p.y * _cp - z * _sp);
  }

  Offset on(_P3 p) {
    final q = _turn(p);
    return Offset(size.width / 2 + (q.dx - _fit.center.dx) * _scale, size.height / 2 - (q.dy - _fit.center.dy) * _scale);
  }

  /// The axes gizmo in the corner, as in Blender: the end of each axis, rotated with the world (x red, y green, z blue).
  Offset get axisMiddle => Offset(size.width - 38, size.height - 38);
  Map<String, Offset> get axisEnds => {
    for (final (n, p) in const [('x', (x: 1.0, y: 0.0, z: 0.0)), ('y', (x: 0.0, y: 1.0, z: 0.0)), ('z', (x: 0.0, y: 0.0, z: 1.0))])
      n: axisMiddle + Offset(_turn(p).dx, -_turn(p).dy) * 20,
  };
  String? axisAt(Offset at) {
    for (final e in axisEnds.entries) {
      if ((e.value - at).distance < 9) return e.key;
    }
    return null;
  }

  /// The layer nearest the tap, else the relation whose shape passes nearest.
  String? hit(Offset at) {
    String? best;
    var d = 16.0;
    for (final e in world.things.entries) {
      final o = (on(e.value.$1) - at).distance;
      if (o < d) (best, d) = (e.key, o);
    }
    if (best != null) return best;
    for (final r in world.relations) {
      for (final p in shape(r)) {
        if ((on(p) - at).distance < 10) return r.id;
      }
    }
    return null;
  }

  /// Points along a relation's shape, in the world.
  List<_P3> shape(_Relation r) {
    final lead = world.things[r.leader]?.$1;
    final c = (x: r.centre.x + (lead?.x ?? 0), y: r.centre.y + (lead?.y ?? 0), z: lead?.z ?? 0.0);
    switch (r.kind) {
      case 'around' || 'push':
        final o = r.kind == 'push' ? lead : c;
        if (o == null) return const [];
        final t = r.kind == 'push' ? 0.0 : r.tilt; // An around relation is tipped back by its tilt.
        return [
          for (var k = 0; k <= 48; k++)
            (
              x: o.x + r.radius * math.sin(k / 48 * 2 * math.pi),
              y: o.y + r.radius * math.cos(k / 48 * 2 * math.pi) * math.cos(t),
              z: o.z + r.radius * math.cos(k / 48 * 2 * math.pi) * math.sin(t),
            ),
        ];
      case 'row':
        final half = r.gap * (r.members.length - 1) / 2;
        return [for (var k = 0; k <= 12; k++) (x: c.x - half + 2 * half * k / 12, y: c.y, z: c.z)];
      default:
        // A follow has no shape of its own here; the painter draws its threads from the leader to each layer.
        return const [];
    }
  }
}

class _Map extends CustomPainter {
  _Map(this.v, this.selected, this.paths, this.stations);
  final _View v;
  final String? selected;
  // paths: the picked layer's path. stations: a picked relation's shapes at its keyframes.
  final Map<String, List<_P3>> paths, stations;

  @override
  void paint(Canvas c, Size s) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // The camera's frame and where the camera stands.
    line.color = WsT.toneCamera;
    c.drawPath(Path()..addPolygon([for (final p in v._frame) v.on(p)], true), line);
    if (v.world.camera case final cam?) c.drawCircle(v.on(cam), 5, Paint()..color = WsT.toneCamera);
    // Each relation's shape and its threads to its layers, in its own colour.
    for (final r in v.world.relations) {
      final hue = wsLabel(r.id), picked = r.id == selected; // The same label colour as its row.
      line
        ..color = hue.withValues(alpha: picked ? 1 : .7)
        ..strokeWidth = picked ? 2 : 1;
      final pts = [for (final p in v.shape(r)) v.on(p)];
      for (var k = 0; k + 1 < pts.length; k += 2) {
        // The shape is drawn as separate segments, so it reads as a relation and not a layer.
        // Each stretch takes the colour of the layer it carries, as the bar in its row does.
        if (r.members.isNotEmpty) {
          line.color = wsLabel(r.members[(k * r.members.length / pts.length).floor().clamp(0, r.members.length - 1)]).withValues(alpha: picked ? 1 : .8);
        }
        c.drawLine(pts[k], pts[k + 1], line);
      }
      final lead = v.world.things[r.leader]?.$1;
      if (r.kind == 'follow' && lead != null) {
        for (final m in r.members) {
          if (v.world.things[m]?.$1 case final p?) c.drawLine(v.on(lead), v.on(p), line);
        }
      }
      if (lead != null) c.drawCircle(v.on(lead), 9, line); // Ring the leader.
      for (final m in r.members) {
        if (v.world.things[m]?.$1 case final p?) c.drawCircle(v.on(p), 7, Paint()..color = hue.withValues(alpha: .25));
      }
    }
    // Each moving layer's path over the duration, in its colour, with a dot per step.
    // A morph from one relation to another shows as the paths bending from one shape into the other.
    // An easing shows as the dots bunching up and spreading out.
    for (final e in paths.entries) {
      // As in After Effects, only the picked layer's path, with a dot per step.
      final hue = v.world.things[e.key]?.$2 ?? WsT.accent, pts = [for (final p in e.value) v.on(p)];
      c.drawPath(
        Path()..addPolygon(pts, false),
        Paint()
          ..color = hue.withValues(alpha: .6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      for (final p in pts) {
        c.drawCircle(p, 1.4, Paint()..color = hue);
      }
    }
    for (final e in stations.entries) {
      // For a picked relation: where each layer stands at each of its keyframes, joined by straight lines and ringed.
      final hue = v.world.things[e.key]?.$2 ?? WsT.accent, pts = [for (final p in e.value) v.on(p)];
      c.drawPath(
        Path()..addPolygon(pts, false),
        Paint()
          ..color = hue.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      for (final p in pts) {
        c.drawCircle(
          p,
          5,
          Paint()
            ..color = hue
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
    // The layers, with the picked one ringed.
    for (final e in v.world.things.entries) {
      final at = v.on(e.value.$1);
      c.drawCircle(at, 4, Paint()..color = e.value.$2);
      // The outline keeps a dark layer visible on the dark map.
      c.drawCircle(
        at,
        4,
        Paint()
          ..color = Grey.g56
          ..style = PaintingStyle.stroke
          ..strokeWidth = .75,
      );
      if (e.key == selected) {
        c.drawCircle(
          at,
          8,
          Paint()
            ..color = WsT.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }
    // The axes gizmo: a line to the end of each axis and a coloured ball with its letter. Tapping a ball looks from that side.
    const hue = {'x': Color(0xFFFF3352), 'y': Color(0xFF8BDC00), 'z': Color(0xFF2890FF)};
    final mid = v.axisMiddle;
    for (final e in v.axisEnds.entries) {
      c.drawLine(
        mid,
        e.value,
        Paint()
          ..color = hue[e.key]!
          ..strokeWidth = 1.5,
      );
      c.drawCircle(mid - (e.value - mid), 3, Paint()..color = hue[e.key]!.withValues(alpha: .4)); // The opposite end, faint.
    }
    for (final e in v.axisEnds.entries) {
      c.drawCircle(e.value, 7, Paint()..color = hue[e.key]!);
      toolText(c, e.key.toUpperCase(), e.value, T.micro(const Color(0xFF111111)).copyWith(fontWeight: FontWeight.w700), ax: .5, ay: .5);
    }
  }

  @override
  bool shouldRepaint(_Map o) => true;
}
