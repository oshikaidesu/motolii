// The Paths card's inside: a sample shape showing what the active operators do, a reorderable stack of those operators,
// and a picker grouped by kind to add more. The stack's order is display only; the engine applies them in its own
// fixed order. Points and inner sit below the stack as they define the shape, not an operator added on top.
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// The Paths card's inside (see host_cards.dart).
class PathsBody extends StatefulWidget {
  const PathsBody(this.card, {super.key});
  final CardDeclaration card;

  static const Set<String> drawn = {
    'points',
    'inner',
    'round',
    'bloat',
    'offset',
    'zigzag',
    'zigzag_ridges',
    'zigzag_smooth',
    'rough',
    'rough_detail',
    'resample',
    'fill_rule',
    'morph',
    'morph_to',
    'morph_steps',
    'trail',
    'trail_length',
    'trim',
    'trim_begin',
    'trim_offset',
  };

  // Default value set when the user adds an operator, chosen so the effect is visible immediately.
  static const _defaults = <String, double>{
    'round': 0.15,
    'bloat': 0.3,
    'offset': 3.0,
    'zigzag': 2.0,
    'zigzag_ridges': 8.0,
    'zigzag_smooth': 0.5,
    'rough': 0.1,
    'rough_detail': 0.1,
    'resample': 100.0,
    'fill_rule': 1.0,
    'morph': 0.5,
    'morph_to': 1.0,
    'morph_steps': 10.0,
    'trail': 1.0,
    'trail_length': 1.0,
    'trim': 0.8,
    'trim_begin': 0.0,
    'trim_offset': 0.0,
  };

  // The order operators appear in the picker, grouped. A sub-parameter (one the
  // engine folds under another, carried by Parameter.fold — in Paths only Zig
  // zag's Ridges and Smooth) is left out of the picker and shown under its
  // parent instead; the rest stand on their own.
  static const _groups = [
    (
      'Deform',
      ['round', 'bloat', 'offset', 'zigzag', 'zigzag_ridges', 'zigzag_smooth'],
    ),
    ('Texture', ['rough', 'rough_detail', 'resample', 'fill_rule']),
    ('Path', ['morph', 'morph_to', 'morph_steps', 'trail', 'trail_length']),
    ('Animate', ['trim', 'trim_begin', 'trim_offset']),
  ];

  // All stackable operators in their default order.
  static const _stackable = [
    'round',
    'bloat',
    'offset',
    'zigzag',
    'zigzag_ridges',
    'zigzag_smooth',
    'rough',
    'rough_detail',
    'resample',
    'fill_rule',
    'morph',
    'morph_to',
    'morph_steps',
    'trail',
    'trail_length',
    'trim',
    'trim_begin',
    'trim_offset',
  ];

  @override
  State<PathsBody> createState() => _PathsBodyState();
}

class _PathsBodyState extends State<PathsBody> {
  // The parents and standalone operators on the stack, in order. Each parent's
  // subs come with it (PathsBody._subs); they are not held here.
  List<String> _order = [];
  bool _initialized = false;
  bool _picking = false;

  Map<String, Parameter> get _params => {
    for (final p in widget.card.params) p.id: p,
  };

  // The sub-parameters the engine folds under [id] (Parameter.fold == its label):
  // in Paths, Zig zag's Ridges and Smooth. Empty for an operator that stands alone.
  List<String> _subsOf(String id) {
    final label = _params[id]?.label;
    if (label == null) return const [];
    return [
      for (final p in widget.card.params)
        if (p.fold == label) p.id,
    ];
  }

  // A sub folds under another operator, so it never sits on the stack or shows
  // in the picker on its own; it rides under its parent.
  bool _isSub(String id) => _params[id]?.fold != null;

  void _init(InspectorValues doc) {
    if (_initialized) return;
    _initialized = true;
    // Only parents and standalone operators sit on the stack; a sub shows under
    // its parent, so an orphan sub left in the document is ignored here.
    _order = [
      for (final id in PathsBody._stackable)
        if (!_isSub(id) && (doc.get('v_$id') ?? 0) != 0.0) id,
    ];
  }

  // Adding an operator turns on its folded subs too, each at its default, as one
  // gesture (only Zig zag has any; everything else adds just itself).
  void _add(InspectorValues doc, String id) {
    if (_order.contains(id)) return;
    doc.beginGesture();
    for (final x in [id, ..._subsOf(id)]) {
      doc.set('v_$x', PathsBody._defaults[x] ?? 1.0);
    }
    doc.endGesture();
    setState(() {
      _order = [..._order, id];
      _picking = false;
    });
  }

  // Removing an operator turns off its folded subs with it.
  void _remove(InspectorValues doc, String id) {
    doc.beginGesture();
    for (final x in [id, ..._subsOf(id)]) {
      doc.set('v_$x', 0.0);
    }
    doc.endGesture();
    setState(
      () => _order = [
        for (final p in _order)
          if (p != id) p,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    _init(doc);
    final params = _params;
    final listenables = [
      for (final id in PathsBody._stackable) doc.watch('v_$id'),
      doc.watch('v_points'),
      doc.watch('v_inner'),
    ];
    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final round = doc.get('v_round') ?? 0;
        final points = (doc.get('v_points') ?? 4).round();
        final inner = doc.get('v_inner') ?? 0;
        final shape = doc.strings['shape'] ?? '';
        final svgPath = doc.actions.shapeSvg?.call() ?? '';
        return Padding(
          padding: EdgeInsets.only(bottom: Shape.s(6)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Preview(
                round: round,
                points: points,
                inner: inner,
                shape: shape,
                svgPath: svgPath,
              ),
              SizedBox(height: Shape.s(8)),
              if (_order.isNotEmpty) _buildStack(doc, params),
              _buildAddButton(doc, params),
              SizedBox(height: Shape.s(8)),
              _buildShapeRows(doc, params),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStack(InspectorValues doc, Map<String, Parameter> params) {
    // ReorderableListView measures item heights itself; no SizedBox needed.
    // Items that move into an Overlay during drag still need their InspectorScope.
    final scope = InspectorScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableList(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _order.length,
          onReorderItem: (from, to) {
            setState(() {
              final item = _order.removeAt(from);
              _order.insert(to, item);
            });
          },
          itemBuilder: (ctx, i) {
            final id = _order[i];
            // The parent carries the drag handle and the remove button; its subs
            // ride beneath it in the same item, so they move and go as a set.
            return InspectorScope(
              key: ValueKey(id),
              doc: scope.doc,
              tick: scope.tick,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StackItem(
                    index: i,
                    id: id,
                    param: params[id],
                    doc: doc,
                    onRemove: () => _remove(doc, id),
                  ),
                  for (final sub in _subsOf(id))
                    _StackItem(
                      index: i,
                      id: sub,
                      param: params[sub],
                      doc: doc,
                      onRemove: () {},
                      isSub: true,
                    ),
                ],
              ),
            );
          },
        ),
        SizedBox(height: Shape.s(2)),
      ],
    );
  }

  Widget _buildAddButton(InspectorValues doc, Map<String, Parameter> params) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Pressable(
          onTap: () => setState(() => _picking = !_picking),
          builder: (_, hot) => Container(
            height: Shape.z(28),
            decoration: BoxDecoration(
              color: hot ? Grey.g15 : null,
              borderRadius: BorderRadius.all(Shape.r(6)),
              border: Border.all(
                color: _picking ? Grey.g38 : Grey.g20,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              '+ operator',
              style: TextStyles.label(_picking ? Grey.g76 : Grey.g44),
            ),
          ),
        ),
        if (_picking) _buildPicker(doc, params),
      ],
    );
  }

  Widget _buildPicker(InspectorValues doc, Map<String, Parameter> params) {
    return Container(
      margin: EdgeInsets.only(top: Shape.s(2)),
      padding: EdgeInsets.all(Shape.s(4)),
      decoration: BoxDecoration(
        color: Grey.g10,
        borderRadius: BorderRadius.all(Shape.r(8)),
        border: Border.all(color: Grey.g20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (group, ids) in PathsBody._groups)
            ..._buildPickerGroup(doc, group, ids),
        ],
      ),
    );
  }

  List<Widget> _buildPickerGroup(
    InspectorValues doc,
    String group,
    List<String> ids,
  ) {
    final available = [
      for (final id in ids)
        if (!_order.contains(id) && !_isSub(id)) id,
    ];
    if (available.isEmpty) return [];
    return [
      Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(6),
          vertical: Shape.s(3),
        ),
        child: Text(group, style: TextStyles.label(Grey.g44)),
      ),
      for (final id in available)
        Pressable(
          onTap: () => _add(doc, id),
          builder: (_, hot) => Container(
            height: Shape.z(26),
            padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
            decoration: BoxDecoration(
              color: hot ? Grey.g20 : null,
              borderRadius: BorderRadius.all(Shape.r(5)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              id.replaceAll('_', ' '),
              style: TextStyles.name(hot ? Grey.g91 : Grey.g76),
            ),
          ),
        ),
    ];
  }

  Widget _buildShapeRows(InspectorValues doc, Map<String, Parameter> params) {
    final pointsP = params['points'];
    final innerP = params['inner'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (pointsP != null)
          RowInfo(
            keys: doc.keys['v_points'] ?? KeyframeState.off,
            child: InspectorNumberField(
              pointsP,
              key: const ValueKey('paths:points'),
              id: 'v_points',
              caption: 'Points',
            ),
          ),
        if (innerP != null)
          RowInfo(
            keys: doc.keys['v_inner'] ?? KeyframeState.off,
            child: InspectorNumberField(
              innerP,
              key: const ValueKey('paths:inner'),
              id: 'v_inner',
              caption: 'Inner',
            ),
          ),
      ],
    );
  }
}

class _StackItem extends StatelessWidget {
  const _StackItem({
    required this.index,
    required this.id,
    required this.param,
    required this.doc,
    required this.onRemove,
    this.isSub = false,
  });
  final int index;
  final String id;
  final Parameter? param;
  final InspectorValues doc;
  final VoidCallback onRemove;
  // A sub rides under its parent: no drag handle, no remove, indented and dim.
  final bool isSub;

  @override
  Widget build(BuildContext context) {
    final p = param;
    if (p == null) return const SizedBox.shrink();
    // A sub reads as the part after its parent's name: 'zigzag_ridges' -> 'ridges'.
    final label = isSub
        ? id.split('_').skip(1).join(' ')
        : id.replaceAll('_', ' ');
    return Container(
      height: Shape.z(32),
      margin: EdgeInsets.only(bottom: Shape.s(2)),
      decoration: BoxDecoration(
        color: Grey.g10,
        borderRadius: BorderRadius.all(Shape.r(6)),
      ),
      child: Row(
        children: [
          // The parent drags the whole set; a sub has no handle of its own.
          if (isSub)
            SizedBox(width: Shape.z(28))
          else
            ReorderableDragStartListener(
              index: index,
              child: SizedBox(
                width: Shape.z(28),
                child: Center(
                  child: Text('⠿', style: TextStyles.label(Grey.g56)),
                ),
              ),
            ),
          SizedBox(
            width: Shape.z(68),
            child: Padding(
              padding: EdgeInsets.only(left: isSub ? Shape.s(10) : 0),
              child: Text(
                label,
                style: TextStyles.label(isSub ? Grey.g56 : Grey.g76),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            child: RowInfo(
              keys: doc.keys['v_$id'] ?? KeyframeState.off,
              child: InspectorNumberField(
                p,
                key: ValueKey('paths:$id'),
                id: 'v_$id',
                caption: label,
                compact: true,
              ),
            ),
          ),
          // Only the parent removes the set; a sub keeps the row aligned.
          if (isSub)
            SizedBox(width: Shape.z(28))
          else
            Pressable(
              onTap: onRemove,
              builder: (_, hot) => SizedBox(
                width: Shape.z(28),
                child: Center(
                  child: Text(
                    '×',
                    style: TextStyles.label(hot ? Grey.g76 : Grey.g44),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.round,
    required this.points,
    required this.inner,
    required this.shape,
    required this.svgPath,
  });
  final double round;
  final int points;
  final double inner;
  final String shape;
  final String svgPath;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: CustomPaint(
      key: const ValueKey('paths-preview'),
      size: Size.fromHeight(Shape.z(60)),
      painter: _PreviewPaint(
        round: round,
        points: points,
        inner: inner,
        shape: shape,
        svgPath: svgPath,
      ),
    ),
  );
}

class _PreviewPaint extends CustomPainter {
  const _PreviewPaint({
    required this.round,
    required this.points,
    required this.inner,
    required this.shape,
    required this.svgPath,
  });
  final double round;
  final int points;
  final double inner;
  final String shape;
  final String svgPath;

  // The engine's outline (motolii_shape_svg: SVG path data) as a Path fitted into a 2 [r] box about ([cx], [cy]).
  // The outline is meant to be a unit high about the origin, but a strong deform (a large round, a rough edge) carries
  // it well past that, so its real bounds are measured and scaled to fit rather than assumed. Null when it is not path data.
  Path? _parseSvg(double cx, double cy, double r) {
    final unit = Path();
    try {
      writeSvgPathDataToPath(svgPath, _IntoPath(unit));
    } catch (_) {
      return null;
    }
    final b = unit.getBounds();
    if (b.isEmpty) return null;
    final k = r * 2 / math.max(b.width, b.height);
    return unit.transform(
      Float64List.fromList([
        k,
        0,
        0,
        0,
        0,
        k,
        0,
        0,
        0,
        0,
        1,
        0,
        cx - b.center.dx * k,
        cy - b.center.dy * k,
        0,
        1,
      ]),
    );
  }

  Path _fallbackPath(double cx, double cy, double r) {
    final path = Path();
    final isRect = shape == 'rect' && points == 4 && inner <= 0;
    if (points == 0 || points >= 50) {
      path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    } else if (isRect || points < 3) {
      final rr = math.min(round * r * 2, r * 0.49);
      path.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
          Radius.circular(rr),
        ),
      );
    } else {
      final rr = round.clamp(0.0, 0.49) * r;
      final step = 2 * math.pi / points;
      final start = -math.pi / 2;
      for (var i = 0; i < points; i++) {
        final a = start + step * i;
        final x = cx + r * math.cos(a), y = cy + r * math.sin(a);
        if (i == 0) {
          path.moveTo(x, y);
        } else if (rr > 0) {
          final prev = start + step * (i - 1);
          final mx = cx + r * math.cos(prev + step / 2) * 0.95;
          final my = cy + r * math.sin(prev + step / 2) * 0.95;
          path.quadraticBezierTo(mx, my, x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
    }
    return path;
  }

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, Shape.r(8)),
      Paint()..color = Grey.g07,
    );
    final cx = s.width / 2, cy = s.height / 2;
    final r = math.min(s.width, s.height) * 0.32;
    final path =
        (svgPath.isNotEmpty ? _parseSvg(cx, cy, r) : null) ??
        _fallbackPath(cx, cy, r);
    c.drawPath(
      path,
      Paint()
        ..color = Grey.g15
        ..style = PaintingStyle.fill,
    );
    c.drawPath(
      path,
      Paint()
        ..color = Accent.fill.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_PreviewPaint o) =>
      o.round != round ||
      o.points != points ||
      o.inner != inner ||
      o.shape != shape ||
      o.svgPath != svgPath;
}

/// What path_parsing reads of an SVG path, drawn into a Flutter [Path].
class _IntoPath extends PathProxy {
  _IntoPath(this.path);
  final Path path;
  @override
  void moveTo(double x, double y) => path.moveTo(x, y);
  @override
  void lineTo(double x, double y) => path.lineTo(x, y);
  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);
  @override
  void close() => path.close();
}
