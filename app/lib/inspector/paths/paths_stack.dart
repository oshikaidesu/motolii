// The reorderable operator stack on the Paths card. Supports both plain
// operator ids ("round") and per-instance prefixed ids ("a1b2c3:round") so
// duplicate operators carry independent sliders and keyframes.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show Draw;

/// Splits an entry like `"a1b2c3:round"` into `("a1b2c3:", "round")`, or
/// `"round"` into `("", "round")`.
(String prefix, String base) splitPathOpId(String entry) {
  final i = entry.indexOf(':');
  if (i < 0) return ('', entry);
  return (entry.substring(0, i + 1), entry.substring(i + 1));
}

/// The reorderable list of active path operators.
class PathsStack extends StatelessWidget {
  const PathsStack({
    required this.order,
    required this.params,
    required this.doc,
    required this.subsOf,
    required this.onRemoveAt,
    required this.onReorder,
    super.key,
  });

  final List<String> order;
  final Map<String, Parameter> params;
  final InspectorValues doc;
  final List<String> Function(String entry) subsOf;
  final void Function(int index, String entry) onRemoveAt;
  final void Function(int from, int to) onReorder;

  Parameter? _paramFor(String id) {
    if (params[id] case final exact?) return exact;
    final (_, base) = splitPathOpId(id);
    return params[base];
  }

  @override
  Widget build(BuildContext context) {
    // Items that move into an Overlay during drag still need their InspectorScope.
    final scope = InspectorScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReorderableList(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.length,
          onReorderItem: (from, to) => onReorder(from, to),
          itemBuilder: (ctx, i) {
            final entry = order[i];
            return InspectorScope(
              key: ValueKey('op:$entry:$i'),
              doc: scope.doc,
              tick: scope.tick,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PathsStackItem(
                    index: i,
                    id: entry,
                    param: _paramFor(entry),
                    doc: doc,
                    onRemove: () => onRemoveAt(i, entry),
                  ),
                  for (final sub in subsOf(entry))
                    PathsStackItem(
                      index: i,
                      id: sub,
                      param: _paramFor(sub),
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
}

/// One slim 32px row on the operator stack: vector 6-dot grip, capitalized
/// label, compact number field, and vector × matching Fill's stroke rows.
class PathsStackItem extends StatelessWidget {
  const PathsStackItem({
    required this.index,
    required this.id,
    required this.param,
    required this.doc,
    required this.onRemove,
    this.isSub = false,
    super.key,
  });

  final int index;
  final String id;
  final Parameter? param;
  final InspectorValues doc;
  final VoidCallback onRemove;
  final bool isSub;

  String _labelOf(Parameter p) {
    if (p.label.isNotEmpty) return p.label;
    final (_, base) = splitPathOpId(id);
    final raw = isSub
        ? base.split('_').skip(1).join(' ')
        : base.replaceAll('_', ' ');
    return raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = param;
    if (p == null) return const SizedBox.shrink();
    final label = _labelOf(p);
    return Container(
      height: Shape.z(32),
      margin: EdgeInsets.only(bottom: Shape.s(2)),
      padding: EdgeInsets.only(right: Shape.s(2)),
      decoration: BoxDecoration(color: Grey.g10, borderRadius: Shape.round(6)),
      child: Row(
        children: [
          if (isSub)
            SizedBox(width: Shape.z(24))
          else
            ReorderableDragStartListener(
              index: index,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: SizedBox(
                  width: Shape.z(24),
                  height: Shape.z(32),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(6, 10),
                      painter: Draw(
                        (c, s) => _drawGripDots(c, s, Grey.g44),
                        index,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: Shape.z(72),
            child: Padding(
              padding: EdgeInsets.only(left: isSub ? Shape.s(8) : 0),
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
          if (isSub)
            SizedBox(width: Shape.z(24))
          else
            Pressable(
              key: ValueKey('paths-remove:$id'),
              onTap: onRemove,
              builder: (_, hot) => SizedBox(
                width: Shape.z(24),
                height: Shape.z(24),
                child: Center(
                  child: CustomPaint(
                    size: const Size(8, 8),
                    painter: Draw(
                      (c, s) => _drawThinCross(c, s, hot ? Grey.g91 : Grey.g44),
                      hot,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void _drawGripDots(Canvas c, Size s, Color color) {
  final p = Paint()..color = color;
  const r = 1.05;
  for (final y in [1.5, s.height * 0.5, s.height - 1.5]) {
    c
      ..drawCircle(Offset(1.4, y), r, p)
      ..drawCircle(Offset(s.width - 1.4, y), r, p);
  }
}

void _drawThinCross(Canvas c, Size s, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;
  c
    ..drawLine(Offset(1, 1), Offset(s.width - 1, s.height - 1), p)
    ..drawLine(Offset(s.width - 1, 1), Offset(1, s.height - 1), p);
}
