// What is picked together and the relation picked, over the stage.
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart'
    show Badge, Chip, ChipLook, Pressable;
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/timeline_painters.dart' show TimelineGlyphs;
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/workspace/stage/stage_viewport.dart';
import 'package:motolii/workspace/stage/view_painter.dart';
import 'package:motolii/workspace/state/art_scene.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// Marks drawn over the stage for the selected layers and the selected relation.
/// - Several layers selected: a ring on each, and along the top the relations they can be given together.
/// - A relation selected: each layer it moves gets a ring and an x that removes it. If the relation has a Leader, the
///   leader wears a crown, and another layer's crown makes it the leader. Along the top are its name and the Release button.
/// - One layer selected: the relations it belongs to, as outlined tags beside it.
class RelationMarks extends StatelessWidget {
  const RelationMarks({
    super.key,
    required this.scene,
    required this.v,
    required this.lasso,
  });
  final ArtScene scene;
  final StageViewport v;
  final List<Offset>? lasso;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      WorkspaceScope.read(context).on[WorkspaceAspect.document],
      WorkspaceScope.read(context).on[WorkspaceAspect.picked],
      WorkspaceScope.read(context).seen,
    ]), // Where the layers are in the preview shown.
    builder: (context, _) {
      final ws = WorkspaceScope.read(context), m = ws.inside;
      Offset? on(String id) =>
          scene.box(id) == null ? null : v.toScreen(scene.box(id)!.c);
      final picked = [for (final id in ws.many) ?on(id)];
      final together = relatableLayers(ws);
      final rel = int.tryParse(ws.selected ?? ''),
          kind = rel == null || m == null ? '' : m.word(rel, 'file');
      final isRelation =
          rel != null &&
          m != null &&
          m.word(rel, 'kind') == 'behaviour' &&
          relationKinds.contains(kind);
      final members = [
        for (final id in relationMembers(ws))
          if (on(id) case final p?) (id, p),
      ];
      // The layer a relation with a Leader leads from, if the selected one has it.
      final leader = isRelation && relationLeader(m, rel) > 0
          ? '${relationLeader(m, rel)}'
          : null;
      final hasLeader = isRelation && m.values(rel).contains('js_leader');
      final tags = relationsOfSelected(ws),
          sel = ws.selected == null ? null : on(ws.selected!);
      return Stack(
        children: [
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: _MarksPainter(lasso, [
                ...picked,
                for (final (_, p) in members) p,
              ]),
            ),
          ),
          for (final (id, p) in members) ...[
            Positioned(
              left: p.dx + 12,
              top: p.dy - 24,
              child: Badge.round(
                WindowTokens.accent,
                onTap: () => freeFromRelation(ws, id),
                key: ValueKey('ws-free-$id'),
                mark: _GlyphPainter('x', WindowTokens.onAccent),
              ),
            ), // Removes this layer from the relation where it stands; the others stay.
          ],
          if (on(leader ?? '') case final l? when leader != null)
            Positioned(
              left: l.dx - 24,
              top: l.dy - 24,
              child: Badge.round(
                WindowTokens.accent,
                onTap: () {},
                key: const ValueKey('ws-leader'),
                mark: _GlyphPainter('crown', WindowTokens.onAccent),
              ),
            ), // The leader.
          // A relation with a Leader: show a faint crown on each other layer, and clicking one makes it the leader without moving anything.
          if (hasLeader)
            for (final l in ws.layers)
              if (l.id != leader &&
                  l.id != '$rel' &&
                  m.word(int.parse(l.id), 'kind') != 'behaviour' &&
                  on(l.id) != null)
                Positioned(
                  left: on(l.id)!.dx - 24,
                  top: on(l.id)!.dy - 24,
                  child: Badge.round(
                    WindowTokens.body.withValues(alpha: .7),
                    onTap: () => makeRelationLeader(ws, l.id),
                    key: ValueKey('ws-lead-${l.id}'),
                    mark: _GlyphPainter('crown', Grey.g63),
                  ),
                ),
          // Selected one by one, the first layer will lead a relation that has a Leader; show its crown before the relation exists.
          if (!isRelation &&
              ws.manyInOrder &&
              ws.many.length > 1 &&
              on(ws.many.first) != null)
            Positioned(
              left: on(ws.many.first)!.dx - 24,
              top: on(ws.many.first)!.dy - 24,
              child: Badge.round(
                WindowTokens.body.withValues(alpha: .7),
                onTap: () {},
                key: const ValueKey('ws-leader-to-be'),
                mark: _GlyphPainter('crown', Grey.g63),
              ),
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
                      label: relationLabel(relationKindOf(m!, int.parse(r))),
                      look: ChipLook.relate,
                      on: r == relationInEffect(ws),
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
                          Chip(
                            label: '${together.length} picked',
                            look: ChipLook.said,
                          ),
                          for (final k in relationChoices(ws))
                            Chip(
                              label: relationLabel(k),
                              look: ChipLook.relate,
                              on: true,
                              onTap: () => makeRelation(ws, k),
                              key: ValueKey('ws-relate-$k'),
                            ),
                        ]
                      : [
                          Chip(
                            label:
                                '${relationLabel(relationKindOf(m!, rel!))} · ${relationMembers(ws).length}',
                            look: ChipLook.said,
                          ),
                          Chip(
                            label: relationLabel('eye'),
                            look: ChipLook.relate,
                            on: true,
                            onTap: () => toggleRelation(ws),
                            glyph: (_) => Glyph(
                              (m.value(rel, 'visible', 0) ?? 1) > .5
                                  ? TimelineGlyphs.eye
                                  : TimelineGlyphs.eyeOff,
                              color: WindowTokens.onAccent,
                              size: Shape.z(12),
                              fade: true,
                            ),
                            key: const ValueKey('ws-relation-switch'),
                          ), // The eye, as on the relation's row: when shut, what lies beneath shows.
                          Chip(
                            label: relationLabel('bake'),
                            look: ChipLook.relate,
                            on: true,
                            onTap: () => releaseRelation(ws),
                            key: const ValueKey('ws-relate-release'),
                          ),
                          Chip(
                            label: relationLabel('delete'),
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

/// Paints the lasso the user is drawing and a ring around each marked layer.
class _MarksPainter extends CustomPainter {
  _MarksPainter(this.lasso, this.at);
  final List<Offset>? lasso;
  final List<Offset> at;
  @override
  void paint(Canvas c, Size s) {
    final ink = linePaint(WindowTokens.accent, 1.5);
    if (lasso case final l? when l.length > 1) {
      c.drawPath(Path()..addPolygon(l, false), ink);
    }
    for (final p in at) {
      c.drawCircle(p, 14, ink);
    }
  }

  @override
  bool shouldRepaint(_MarksPainter o) => true;
}

/// The relations the selected layer belongs to, at the top of its inspector, the one in effect first (as Blender stacks constraints).
/// Each row shows an on/off dot, the relation's kind and its leader, and an x that removes the layer from the relation.
/// Clicking a row selects that relation.
class RelationStack extends StatelessWidget {
  const RelationStack({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      WorkspaceScope.read(context).on[WorkspaceAspect.document],
      WorkspaceScope.read(context).on[WorkspaceAspect.picked],
    ]),
    builder: (context, _) => _built(context),
  ); // Listens on its own so the inspector is not rebuilt when a value of another layer changes.

  Widget _built(BuildContext context) {
    final ws = WorkspaceScope.read(context), m = ws.inside, t = ws.selected;
    if (m == null || t == null) return const SizedBox.shrink();
    final rels = relationsOfSelected(ws), top = relationInEffect(ws);
    if (rels.isEmpty) return const SizedBox.shrink();
    String nameOf(int i) =>
        '${ws.layers.indexWhere((l) => l.id == '$i') + 1}. ${ws.layers.where((l) => l.id == '$i').firstOrNull?.name ?? ''}';
    return Container(
      key: const ValueKey('ws-relation-stack'),
      padding: EdgeInsets.fromLTRB(
        Shape.s(10),
        Shape.s(8),
        Shape.s(10),
        Shape.s(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rels)
            () {
              final id = int.parse(r),
                  kind = relationLabel(relationKindOf(m, id)),
                  on = (m.value(id, 'visible', 0) ?? 1) > .5;
              final lead = relationLeader(m, id), leads = '$lead' == t;
              final ink = r == top ? Grey.g95 : Grey.g56;
              return Pressable(
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
                      Text(kind, style: TextStyles.label(ink)),
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
                          style: TextStyles.label(Grey.g56),
                        ),
                      ),
                      if (!leads)
                        Pressable(
                          key: ValueKey('ws-stack-free-$r'),
                          cursor: SystemMouseCursors.basic,
                          onTap: () => ws.after(
                            m.later(
                              'free',
                              layer: int.parse(t),
                              number: id.toDouble(),
                            ),
                            (_, _) => ws.reread(),
                          ),
                          builder: (_, _) =>
                              Text('×', style: TextStyles.label(Grey.g56)),
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

/// A small mark drawn as a path so no font has to carry it: an x (remove) or a crown (leader).
class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.what, this.ink);
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
  bool shouldRepaint(_GlyphPainter o) => o.what != what || o.ink != ink;
}
