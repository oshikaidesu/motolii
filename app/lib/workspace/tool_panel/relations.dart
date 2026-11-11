// The Relations tab: the layers seen from outside the camera, as the Depth tab shows depth.
// It draws every layer where it is (including off camera), the camera's frame, and each relation as its leader's ring
// with a thread to each layer it moves.
// The user views it from the front or top, or turns it by dragging. Tapping picks a layer or a relation, which the inspector shows.
import 'package:motolii/workspace/tool_panel/relations_world.dart';
import 'package:motolii/workspace/tool_panel/relations_map.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/tool_strip.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/workspace/edits/make_relation.dart';
import 'package:motolii/widgets/two_finger_gestures.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii_document.dart';
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
  (int, Map<String, List<MapPoint3>>)? _paths;
  int? _pathsAsked;
  Object? _stationsAsked;

  /// A picked relation's layers at the time of each of its keyframes, in time order.
  /// These are the shapes the relation passes through, not the path between them.
  /// They are times other than the one the preview shows, so they are requested from the engine (another isolate) and shown when they arrive.
  (Object, Map<String, List<MapPoint3>>)? _stations;
  Map<String, List<MapPoint3>> _stationsOf(WorkspaceController ws) {
    final m = ws.inside, r = int.tryParse(ws.selected ?? '');
    final at = (ws.rev, ws.selected);
    if (_stations?.$1 == at || _stationsAsked == at || m == null) {
      return _stations?.$2 ?? const {};
    }
    _stationsAsked = at;
    final moments = r != null && m.word(r, 'kind') == 'behaviour'
        ? ({for (final n in m.moving(r)) ...m.keyTimes(r, n)}.toList()..sort())
        : <double>[];
    final members = [
      for (final s
          in r == null ? const <String>[] : m.word(r, 'members').split(' '))
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
                for (final t in members)
                  '$t': [
                    for (final _ in moments) (x: next(), y: next(), z: next()),
                  ],
              },
            ),
          );
        });
    return _stations?.$2 ?? const {};
  }

  Map<String, List<MapPoint3>> _pathsOf(WorkspaceController ws) {
    final m = ws.inside;
    if (_paths?.$1 == ws.rev || _pathsAsked == ws.rev || m == null) {
      return _paths?.$2 ?? const {};
    }
    final rev = _pathsAsked = ws.rev;
    const steps = 60;
    final things = [
      for (final l in ws.layers)
        if (int.tryParse(l.id) case final t?
            when m.word(t, 'kind') != 'behaviour' &&
                m.word(t, 'kind') != 'camera')
          t,
    ];
    m
        .shownAt([
          for (final t in things)
            for (var k = 0; k <= steps; k++)
              for (final n in const ['x', 'y', 'z'])
                (
                  t,
                  n,
                  k /
                      steps *
                      WorkspaceController.duration /
                      WorkspaceController.fps,
                ),
        ])
        .then((v) {
          if (!mounted) return;
          var i = 0;
          double next() => v[i++] ?? 0;
          final out = <String, List<MapPoint3>>{};
          for (final t in things) {
            final way = [
              for (var k = 0; k <= steps; k++)
                (x: next(), y: next(), z: next()),
            ];
            // Keep only the layers that move.
            if (way.any(
              (p) =>
                  (p.x - way.first.x).abs() +
                      (p.y - way.first.y).abs() +
                      (p.z - way.first.z).abs() >
                  1e-4,
            )) {
              out['$t'] = way;
            }
          }
          setState(() => _paths = (rev, out));
        });
    return _paths?.$2 ?? const {};
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      WorkspaceScope.read(context).on[WorkspaceAspect.document],
      WorkspaceScope.read(context).on[WorkspaceAspect.picked],
      // Changes with the frame the preview shows, which decides where the layers are.
      WorkspaceScope.read(context).seen,
    ]),
    builder: (context, _) {
      final ws = WorkspaceScope.read(context),
          world = MapWorld.of(ws),
          together = relatableLayers(ws).length,
          many = together > 1,
              // One layer takes a relation too: on its copies, letters or words (putRelation).
              can =
              many || int.tryParse(ws.selected ?? '') != null;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ToolStrip(
            left: [
              Chip(
                label: 'Relations · ${world.relations.length}',
                look: ChipLook.flat(WindowTokens.toneGroup),
              ),
            ],
          ),
          ColoredBox(
            // The row names what the tab is for in the words that do it, as the top of the preview does.
            // Blender's Constraints tab also holds its own Add menu.
            color: WindowTokens.card,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                WindowTokens.inset,
                0,
                WindowTokens.inset,
                Shape.s(5),
              ),
              child: Wrap(
                spacing: Shape.s(4),
                runSpacing: Shape.s(4),
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    many
                        ? '$together picked'
                        : can
                        ? 'On its copies, letters or words'
                        : 'Pick a layer',
                    style: TextStyles.micro(Grey.g63),
                  ),
                  for (final k in relationChoices(ws))
                    GestureDetector(
                      key: ValueKey('ws-tab-relate-$k'),
                      onTap: can ? () => putRelation(ws, k) : null,
                      child: IntrinsicWidth(
                        child: Chip(
                          label: relationLabel(k),
                          look: ChipLook.flat(
                            can ? WindowTokens.accent : Grey.g38,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: WindowTokens.gutter),
          Expanded(
            child: ColoredBox(
              color: WindowTokens.card,
              child: LayoutBuilder(
                builder: (context, box) {
                  final view = MapView(
                    world,
                    box.biggest,
                    _yaw,
                    _pitch,
                    paths: _pathsOf(ws),
                    zoom: _zoom,
                  );
                  // Two fingers on a trackpad turn the view, as in Blender, through the drag handler below. A pinch zooms in.
                  return TwoFingerGestures(
                    onWheel: (d) => setState(
                      () => _zoom = (_zoom * math.exp(-d.dy / 300)).clamp(
                        .3,
                        8.0,
                      ),
                    ),
                    onPinch: (by, _) =>
                        setState(() => _zoom = (_zoom * by).clamp(.3, 8.0)),
                    child: GestureDetector(
                      key: const ValueKey('ws-relations-map'),
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (d) => setState(() {
                        _yaw += d.delta.dx * .01;
                        _pitch = (_pitch - d.delta.dy * .01).clamp(
                          -math.pi / 2,
                          math.pi / 2,
                        );
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
                        if (view.hit(d.localPosition) case final id?) {
                          ws.select(id);
                        }
                      },
                      child: CustomPaint(
                        size: box.biggest,
                        painter: RelationsMapPainter(view, ws.selected, {
                          ?ws.selected: ?_pathsOf(ws)[ws.selected],
                        }, _stationsOf(ws)),
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
