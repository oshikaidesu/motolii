// The reorderable operator stack on the Paths card. Each parent carries its
// subs as a set; dragging a parent moves its subs with it.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;

/// The reorderable list of active operators.
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
  final List<String> Function(String) subsOf;
  final void Function(int index, String id) onRemoveAt;
  final void Function(int from, int to) onReorder;

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
            final id = order[i];
            // The parent carries the drag handle and the remove button; its subs
            // ride beneath it in the same item, so they move and go as a set.
            return InspectorScope(
              key: ValueKey('$id:$i'),
              doc: scope.doc,
              tick: scope.tick,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PathsStackItem(
                    index: i,
                    id: id,
                    param: params[id],
                    doc: doc,
                    onRemove: () => onRemoveAt(i, id),
                  ),
                  for (final sub in subsOf(id))
                    PathsStackItem(
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
}

/// One row on the operator stack: drag handle, label, number field, remove button.
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
      decoration: BoxDecoration(color: Grey.g10, borderRadius: Shape.round(6)),
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
