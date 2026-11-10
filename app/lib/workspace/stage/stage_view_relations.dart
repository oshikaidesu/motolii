// What is picked together and the relation picked, over the stage.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge, Chip, ChipLook, Hov;
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/timeline_painters.dart' show TpGlyph;
import 'package:motolii/widgets/two_fingers.dart';
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/stage/stage_view.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// Marks drawn over the stage for the selected layers and the selected relation.
/// - Several layers selected: a ring on each, and along the top the relations they can be given together.
/// - A relation selected: its shape (a ring, a row's line, or how far a push reaches) and handles for its centre and size.
///   Each layer it moves gets a ring and an x that removes it; the leader wears a crown, and another layer's crown makes it the leader.
///   Along the top are its name and the Release button.
/// - One layer selected: the relations it belongs to, as outlined tags beside it.
class RelationMarks extends StatelessWidget {
  const RelationMarks({super.key, required this.scene, required this.v, required this.lasso});
  final ArtScene scene;
  final StageViewport v;
  final List<Offset>? lasso;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      WsScope.read(context).on[WsAspect.document],
      WsScope.read(context).on[WsAspect.picked],
      WsScope.read(context).seen,
    ]), // Where the layers are in the preview shown.
    builder: (context, _) {
      final ws = WsScope.read(context), m = ws.inside;
      Offset? on(String id) => scene.box(id) == null ? null : v.toScreen(scene.box(id)!.c);
      final picked = [
        for (final id in ws.many)
          if (on(id) case final p?) p,
      ];
      final together = wsRelatable(ws);
      final rel = int.tryParse(ws.selected ?? ''), kind = rel == null || m == null ? '' : m.word(rel, 'file');
      final isRelation = rel != null && m != null && m.word(rel, 'kind') == 'behaviour' && wsRelations.contains(kind);
      final members = [
        for (final id in wsMembersOf(ws))
          if (on(id) case final p?) (id, p),
      ];
      final now = m?.now ?? 0;
      // Converts between a point in stage units and a point on the screen.
      Offset screen(double x, double y) => v.toScreen(Offset(WsArt.comp.width / 2 + x * m!.point, WsArt.comp.height / 2 - y * m.point));
      (double, double) units(Offset p) {
        final c = v.toComp(p);
        return ((c.dx - WsArt.comp.width / 2) / m!.point, (WsArt.comp.height / 2 - c.dy) / m.point);
      }

      final shape = <_Shape>[];
      final handles = <Widget>[];
      String? leader;
      if (isRelation) {
        double val(String n, [double or = 0]) => m.value(rel, n, now) ?? or;
        final off = val('visible', 1) <= .5;
        leader = val('leader') > 0 ? '${val('leader').round()}' : null;
        // For a ring or a row, the middle is the leader's position and the centre is an offset from it.
        final lead = kind == 'around' || kind == 'row' ? int.tryParse(leader ?? '') : null;
        final lx = lead == null ? 0.0 : m.shows(lead, 'x', now)?.$1 ?? 0, ly = lead == null ? 0.0 : m.shows(lead, 'y', now)?.$1 ?? 0;
        final cx = val('centre_x') + lx, cy = val('centre_y') + ly, mid = screen(cx, cy), px = m.point * v.s;
        Widget handle(String key, Offset at, void Function((double, double) u) dragUpdate) => Positioned(
          left: at.dx - 7,
          top: at.dy - 7,
          child: GestureDetector(
            supportedDevices: wsPressing,
            key: ValueKey('ws-relation-$key'),
            onPanStart: (_) => m.take(rel),
            onPanUpdate: (d) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) dragUpdate(units(box.globalToLocal(d.globalPosition)));
            },
            onPanEnd: (_) => ws.after(m.later('drag_end', number: 1), (_, _) => ws.reread()),
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: WsT.onAccent,
                shape: BoxShape.circle,
                border: Border.all(color: WsT.accent, width: 2),
              ),
              child: CustomPaint(painter: _GlyphPaint(key == 'centre' ? 'cross' : 'arrow', WsT.accent)),
            ),
          ),
        );
        if (kind == 'around') {
          final r = val('radius', .5), turn = val('offset') + .5 / math.max(1, members.length), tilt = val('tilt') * math.pi / 180;
          if (tilt.abs() < 1e-6 || members.length < 3) {
            shape.add(_Shape.ring(mid, r * px, off: off));
          } else {
            // Tilted, the layers are spread in depth, so draw a line through their on-screen positions in order, closing the loop.
            for (var k = 0; k < members.length; k++) {
              shape.add(_Shape.line(members[k].$2, members[(k + 1) % members.length].$2, off: off));
            }
          }
          // With a leader the leader is the centre, so there is no centre handle; the user drags the leader itself.
          handles
            ..addAll([
              if (lead == null)
                handle(
                  'centre',
                  mid,
                  (u) => m
                    ..dragUpdate('centre_x', u.$1 - lx)
                    ..dragUpdate('centre_y', u.$2 - ly),
                ),
            ])
            ..add(
              handle(
                'size',
                screen(cx + r * math.sin(turn * 2 * math.pi), cy + r * math.cos(turn * 2 * math.pi) * math.cos(tilt)),
                (u) => m.dragUpdate('radius', math.sqrt(math.pow(u.$1 - cx, 2) + math.pow((u.$2 - cy) / math.max(.2, math.cos(tilt).abs()), 2))),
              ),
            );
        } else if (kind == 'row') {
          final gap = val('gap', .2), n = math.max(1, m.word(rel, 'members').split(' ').length), half = gap * (n - 1) / 2;
          shape.add(_Shape.line(screen(cx - half, cy), screen(cx + half, cy), off: off));
          // The handles sit above the line so they do not cover the layers in the row.
          const above = Offset(0, -30);
          handles
            ..addAll([
              if (lead == null)
                handle('centre', mid + above, (u) {
                  final (_, lift) = units(above);
                  final (_, zero) = units(Offset.zero);
                  m
                    ..dragUpdate('centre_x', u.$1 - lx)
                    ..dragUpdate('centre_y', u.$2 - (lift - zero) - ly);
                }),
            ])
            ..add(handle('size', screen(cx + half, cy) + above, (u) => m.dragUpdate('gap', math.max(0, u.$1 - cx) * 2 / math.max(1, n - 1))));
        } else if (kind == 'push' && leader != null && on(leader) != null) {
          final l = on(leader)!, r = val('radius', .5);
          shape.add(_Shape.ring(l, r * px, off: off));
          handles.add(
            handle('size', l + Offset(r * px, 0), (u) {
              final (lx, ly) = units(l);
              m.dragUpdate('radius', math.sqrt(math.pow(u.$1 - lx, 2) + math.pow(u.$2 - ly, 2)));
            }),
          );
        }
      }
      final tags = wsRelationsOf(ws), sel = ws.selected == null ? null : on(ws.selected!);
      // A layer is selected: draw the shape of each relation it belongs to, including its leader's ring while it is dragged.
      if (sel != null && m != null && !isRelation)
        for (final r in tags.map(int.parse)) {
          double val(String n, [double or = 0]) => m.value(r, n, now) ?? or;
          final px = m.point * v.s, l = val('leader') > 0 ? on('${val('leader').round()}') : null, off = val('visible', 1) <= .5;
          switch (m.word(r, 'file')) {
            case 'around':
              final lid = val('leader') > 0 ? val('leader').round() : null,
                  lx = lid == null ? 0.0 : m.shows(lid, 'x', now)?.$1 ?? 0,
                  ly = lid == null ? 0.0 : m.shows(lid, 'y', now)?.$1 ?? 0;
              final pts = [
                for (final s in m.word(r, 'members').split(' '))
                  if (on(s) case final p?) p,
              ];
              if (val('tilt').abs() > 1e-6 && pts.length > 2) {
                for (var k = 0; k < pts.length; k++) {
                  shape.add(_Shape.line(pts[k], pts[(k + 1) % pts.length], off: off));
                }
              } else {
                shape.add(_Shape.ring(screen(val('centre_x') + lx, val('centre_y') + ly), val('radius', .5) * px, off: off));
              }
            case 'row':
              final half = val('gap', .2) * (m.word(r, 'members').split(' ').length - 1) / 2;
              shape.add(_Shape.line(screen(val('centre_x') - half, val('centre_y')), screen(val('centre_x') + half, val('centre_y')), off: off));
            case 'push' when l != null:
              shape.add(_Shape.ring(l, val('radius', .5) * px, off: off));
          }
        }
      return Stack(
        children: [
          IgnorePointer(
            child: CustomPaint(size: Size.infinite, painter: _MarksPainter(lasso, [...picked, for (final (_, p) in members) p], shape)),
          ),
          ...handles,
          for (final (id, p) in members) ...[
            Positioned(
              left: p.dx + 12,
              top: p.dy - 24,
              child: Badge.round(WsT.accent, onTap: () => wsFree(ws, id), key: ValueKey('ws-free-$id'), mark: _GlyphPaint('x', WsT.onAccent)),
            ), // Removes this layer from the relation where it stands; the others stay.
            if ((kind == 'follow' || kind == 'push') && id != leader)
              Positioned(
                left: p.dx - 24,
                top: p.dy - 24,
                child: Badge.round(
                  WsT.body.withValues(alpha: .7),
                  onTap: () => wsLead(ws, id),
                  key: ValueKey('ws-lead-$id'),
                  mark: _GlyphPaint('crown', Grey.g63),
                ),
              ), // Makes this layer the leader without moving anything.
          ],
          if (on(leader ?? '') case final l? when leader != null)
            Positioned(
              left: l.dx - 24,
              top: l.dy - 24,
              child: Badge.round(WsT.accent, onTap: () {}, key: const ValueKey('ws-leader'), mark: _GlyphPaint('crown', WsT.onAccent)),
            ), // The leader.
          // The middle of a ring or a row may be a layer: show a faint crown on each other layer, and clicking one makes it the middle.
          if (isRelation && (kind == 'around' || kind == 'row'))
            for (final l in ws.layers)
              if (l.id != leader && l.id != '$rel' && !members.any((e) => e.$1 == l.id) && m.word(int.parse(l.id), 'kind') != 'behaviour' && on(l.id) != null)
                Positioned(
                  left: on(l.id)!.dx - 24,
                  top: on(l.id)!.dy - 24,
                  child: Badge.round(
                    WsT.body.withValues(alpha: .7),
                    onTap: () => ws.after(m.later('set', layer: rel, name: 'leader', number: double.parse(l.id)), (_, _) => ws.reread()),
                    key: ValueKey('ws-lead-${l.id}'),
                    mark: _GlyphPaint('crown', Grey.g63),
                  ),
                ),
          // Selected one by one, the first layer will lead a Follow or a Push; show its crown before the relation exists.
          if (!isRelation && ws.manyInOrder && ws.many.length > 1 && on(ws.many.first) != null)
            Positioned(
              left: on(ws.many.first)!.dx - 24,
              top: on(ws.many.first)!.dy - 24,
              child: Badge.round(WsT.body.withValues(alpha: .7), onTap: () {}, key: const ValueKey('ws-leader-to-be'), mark: _GlyphPaint('crown', Grey.g63)),
            ),
          // Tags for the relations the selected layer belongs to, the top one first. Clicking a tag selects that relation.
          if (sel != null && tags.isNotEmpty)
            Positioned(
              left: sel.dx + 20,
              top: sel.dy + 18,
              child: Row(
                children: [
                  for (final r in tags)
                    Chip(
                      label: wsRelationWord(wsRelationOf(m!, int.parse(r))),
                      look: ChipLook.relate,
                      on: r == wsWinner(ws),
                      onTap: () => ws.select(r),
                      key: ValueKey('ws-in-$r'),
                    ),
                ],
              ),
            ), // The tag of the relation in effect is filled; the others, under it or switched off, are outlined.
          // Along the top, never over a layer. Layers showing nothing now still count: a relation goes by property values.
          if (lasso == null && (together.length > 1 || isRelation))
            Positioned(
              left: v.area.left,
              right: v.area.right - v.area.width,
              top: v.area.top + 8,
              child: Center(
                child: Wrap(
                  // There is one chip per file in relations/; a narrow stage wraps them onto more lines.
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: Shape.s(4),
                  children: together.length > 1
                      ? [
                          Chip(label: '${together.length} picked', look: ChipLook.said),
                          for (final k in wsRelationChoices(ws))
                            Chip(label: wsRelationWord(k), look: ChipLook.relate, on: true, onTap: () => wsRelate(ws, k), key: ValueKey('ws-relate-$k')),
                        ]
                      : [
                          Chip(label: '${wsRelationWord(wsRelationOf(m!, rel!))} · ${wsMembersOf(ws).length}', look: ChipLook.said),
                          Chip(
                            label: wsRelationWord('eye'),
                            look: ChipLook.relate,
                            on: true,
                            onTap: () => wsSwitch(ws),
                            glyph: (_) => Glyph(
                              (m.value(rel, 'visible', 0) ?? 1) > .5 ? TpGlyph.eye : TpGlyph.eyeOff,
                              color: WsT.onAccent,
                              size: Shape.z(12),
                              fade: true,
                            ),
                            key: const ValueKey('ws-relation-switch'),
                          ), // The eye, as on the relation's row: when shut, what lies beneath shows.
                          Chip(
                            label: wsRelationWord('bake'),
                            look: ChipLook.relate,
                            on: true,
                            onTap: () => wsRelease(ws),
                            key: const ValueKey('ws-relate-release'),
                          ),
                          Chip(
                            label: wsRelationWord('delete'),
                            look: ChipLook.relate,
                            on: true,
                            onTap: () => ws.after(
                              m.later('remove', layer: rel),
                              (_, _) => ws
                                ..select(null)
                                ..reread(),
                            ),
                            key: const ValueKey('ws-relate-delete'),
                          ), // Placed beside the bake chip as Blender places Apply and Delete. Bake keeps the layers where they show and removes the relation; delete returns them to their own values.
                        ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// A relation's shape on the stage: a ring (centre and radius) or a line.
class _Shape {
  _Shape.ring(this.a, this.r, {this.off = false}) : b = null;
  _Shape.line(this.a, Offset this.b, {this.off = false}) : r = 0;
  final Offset a;
  final Offset? b;
  final double r;

  /// True when the relation's eye is shut; the shape is drawn faint.
  final bool off;
}

/// Paints the lasso the user is drawing, a ring around each marked layer, and each relation shape as a thin dashed line.
class _MarksPainter extends CustomPainter {
  _MarksPainter(this.lasso, this.at, this.shape);
  final List<Offset>? lasso;
  final List<Offset> at;
  final List<_Shape> shape;
  @override
  void paint(Canvas c, Size s) {
    final ink = linePaint(WsT.accent, 1.5);
    if (lasso case final l? when l.length > 1) c.drawPath(Path()..addPolygon(l, false), ink);
    for (final p in at) {
      c.drawCircle(p, 14, ink);
    }
    for (final sh in shape) {
      final thin = linePaint(WsT.accent.withValues(alpha: sh.off ? .25 : .8));
      final path = sh.b == null
          ? (Path()..addOval(Rect.fromCenter(center: sh.a, width: 2 * sh.r, height: 2 * sh.r)))
          : (Path()
              ..moveTo(sh.a.dx, sh.a.dy)
              ..lineTo(sh.b!.dx, sh.b!.dy));
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 9) {
          c.drawPath(m.extractPath(d, math.min(d + 5, m.length)), thin);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MarksPainter o) => true;
}

/// The relations the selected layer belongs to, at the top of its inspector, the one in effect first (as Blender stacks constraints).
/// Each row shows an on/off dot, the relation's kind and its leader, and an x that removes the layer from the relation.
/// Clicking a row selects that relation.
class WsRelationStack extends StatelessWidget {
  const WsRelationStack({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([WsScope.read(context).on[WsAspect.document], WsScope.read(context).on[WsAspect.picked]]),
    builder: (context, _) => _built(context),
  ); // Listens on its own so the inspector is not rebuilt when a value of another layer changes.

  Widget _built(BuildContext context) {
    final ws = WsScope.read(context), m = ws.inside, t = ws.selected;
    if (m == null || t == null) return const SizedBox.shrink();
    final rels = wsRelationsOf(ws), top = wsWinner(ws);
    if (rels.isEmpty) return const SizedBox.shrink();
    String nameOf(int i) => '${ws.layers.indexWhere((l) => l.id == '$i') + 1}. ${ws.layers.where((l) => l.id == '$i').firstOrNull?.name ?? ''}';
    return Container(
      key: const ValueKey('ws-relation-stack'),
      padding: EdgeInsets.fromLTRB(Shape.s(10), Shape.s(8), Shape.s(10), Shape.s(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rels)
            () {
              final id = int.parse(r), kind = m.word(id, 'file'), on = (m.value(id, 'visible', 0) ?? 1) > .5;
              final lead = (m.value(id, 'leader', 0) ?? 0).round(), leads = '$lead' == t;
              final ink = r == top ? Grey.g95 : Grey.g56;
              return Hov(
                key: ValueKey('ws-stack-$r'),
                cursor: SystemMouseCursors.basic,
                onTap: () => ws.select(r),
                builder: (_, _) => Padding(
                  padding: EdgeInsets.symmetric(vertical: Shape.s(3)),
                  child: Row(
                    children: [
                      Container(
                        width: Shape.z(6),
                        height: Shape.z(6),
                        decoration: BoxDecoration(
                          color: on ? ink : const Color(0x00000000),
                          border: Border.all(color: ink),
                          shape: BoxShape.circle,
                        ),
                      ), // Filled when the relation is switched on. Its eye is on the relation's own row and bar.
                      SizedBox(width: Shape.s(8)),
                      Text('${kind[0].toUpperCase()}${kind.substring(1)}', style: T.label(ink)),
                      SizedBox(width: Shape.s(8)),
                      Expanded(
                        child: Text(
                          leads
                              ? 'leads it'
                              : lead > 0
                              ? nameOf(lead)
                              : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: T.label(Grey.g56),
                        ),
                      ),
                      if (!leads)
                        Hov(
                          key: ValueKey('ws-stack-free-$r'),
                          cursor: SystemMouseCursors.basic,
                          onTap: () => ws.after(m.later('free', layer: int.parse(t), number: id.toDouble()), (_, _) => ws.reread()),
                          builder: (_, _) => Text('×', style: T.label(Grey.g56)),
                        ),
                    ],
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

/// A small mark drawn as a path so no font has to carry it: a cross (centre), an arrow (size), an x (remove) or a crown (leader).
class _GlyphPaint extends CustomPainter {
  _GlyphPaint(this.what, this.ink);
  final String what;
  final Color ink;
  @override
  void paint(Canvas c, Size s) {
    final m = s.center(Offset.zero), r = s.shortestSide * .28;
    final pen = Paint()
      ..color = ink
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (what) {
      case 'cross':
        c
          ..drawLine(m - Offset(r, 0), m + Offset(r, 0), pen)
          ..drawLine(m - Offset(0, r), m + Offset(0, r), pen);
      case 'arrow':
        c
          ..drawLine(m - Offset(r, 0), m + Offset(r, 0), pen)
          ..drawLine(m + Offset(r, 0), m + Offset(r * .4, -r * .6), pen)
          ..drawLine(m + Offset(r, 0), m + Offset(r * .4, r * .6), pen);
      case 'x':
        c
          ..drawLine(m - Offset(r, r), m + Offset(r, r), pen)
          ..drawLine(m - Offset(r, -r), m + Offset(r, -r), pen);
      case 'crown':
        c.drawPath(
          Path()..addPolygon([
            m + Offset(-r * 1.2, r * .8),
            m + Offset(-r * 1.2, -r * .6),
            m + Offset(-r * .5, 0),
            m + Offset(0, -r),
            m + Offset(r * .5, 0),
            m + Offset(r * 1.2, -r * .6),
            m + Offset(r * 1.2, r * .8),
          ], true),
          Paint()..color = ink,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPaint o) => o.what != what || o.ink != ink;
}

/// The pill at the bottom-left of the viewport: the zoom and the pointer position in composition pixels.
class Hud extends StatelessWidget {
  Hud({super.key, required this.scale, required this.cursor});
  final double scale;
  final ValueNotifier<Offset?> cursor;
  @override
  Widget build(BuildContext context) => Container(
    height: StageTokens.hud,
    padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
    decoration: BoxDecoration(color: WsT.card, borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('${(scale * 100).round()}%', style: T.value(Grey.g95)),
        Container(
          width: 1,
          height: Shape.z(10),
          margin: EdgeInsets.symmetric(horizontal: Shape.s(8)),
          color: WsT.line,
        ),
        ValueListenableBuilder<Offset?>(
          valueListenable: cursor,
          builder: (_, p, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (l, n) in [('X ', p?.dx), ('Y ', p?.dy)]) ...[
                Text(l, style: T.micro(Grey.g56)),
                SizedBox(
                  width: Shape.z(34),
                  child: Text(n == null ? '—' : '${n.round()}', style: T.value(n == null ? Grey.g56 : Grey.g91)),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// The navigator: the whole frame in miniature, the part the viewport shows outlined. Shown only when zoomed past fit.
class StageNavigator extends StatelessWidget {
  const StageNavigator({super.key, required this.scene, required this.view, this.texture});
  final ArtScene scene;
  final StageViewport view;

  /// The engine's preview of the whole frame, drawn under the outline. It is the same texture the stage shows.
  final int? texture;
  @override
  Widget build(BuildContext context) {
    final h = StageTokens.mapW * WsArt.comp.height / WsArt.comp.width;
    return Container(
      width: StageTokens.mapW + 8,
      height: h + 8,
      padding: EdgeInsets.all(Shape.s(4)),
      color: WsT.card,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (texture != null) Texture(textureId: texture!, filterQuality: FilterQuality.medium),
          CustomPaint(painter: _MapPainter(scene, Rect.fromPoints(view.toComp(view.area.topLeft), view.toComp(view.area.bottomRight)))),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.scene, this.shown);
  final ArtScene scene;
  final Rect shown;
  @override
  void paint(Canvas c, Size s) {
    final k = s.width / WsArt.comp.width;
    c.save();
    c.clipRect(Offset.zero & s);
    c.scale(k);
    c.restore();
    final r = Rect.fromLTRB(shown.left * k, shown.top * k, shown.right * k, shown.bottom * k).intersect(Offset.zero & s);
    c.drawRect(r.deflate(.75), linePaint(WsT.accent, 1.5));
  }

  @override
  bool shouldRepaint(_MapPainter o) => o.scene != scene || o.shown != shown;
}

// ---- the preview and what sits on it ----------------------------------------------------------------------------------

Paint linePaint(Color c, [double w = 1]) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..color = c;

/// What one painter draws: everything (including the stand-in art), or one side of the engine's preview.
/// With the preview in the composition, [under] is what lies beneath it (surround, captions), [over] what lies above (grid, guides, selection).
enum ViewPart { all, under, over }

class PointsPainter extends CustomPainter {
  PointsPainter(this.at, this.handles);
  final List<Offset> at;
  final List<(Offset, Offset)> handles;
  @override
  void paint(Canvas c, Size _) {
    final edge = linePaint(WsT.accent), inside = Paint()..color = const Color(0xFFFFFFFF);
    for (final (h, o) in handles) {
      if ((h - o).distance < 1) continue;
      c
        ..drawLine(o, h, edge)
        ..drawCircle(h, 3, inside)
        ..drawCircle(h, 3, edge);
    }
    for (final p in at) {
      final r = Rect.fromCenter(center: p, width: Shape.z(6), height: Shape.z(6));
      c
        ..drawRect(r, inside)
        ..drawRect(r, edge);
    }
  }

  @override
  bool shouldRepaint(PointsPainter o) => !listEquals(o.at, at) || !listEquals(o.handles, handles);
}
