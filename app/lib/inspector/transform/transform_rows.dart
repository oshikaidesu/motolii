// The rows of the Transform card and its Anchor: a mark, a name, a unit, then one-row fields on the X / Y / Z columns.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/inspector/transform/transform_canvas.dart'
    show transformHot;
import 'package:motolii/inspector/transform/transform_layout.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/media.dart' show glyph;

/// One row high, one axis of a value: the panel's standard number field, named by the X / Y / Z heading above it.
Widget axisField(
  Map<String, Parameter> params,
  InspectorValues doc,
  String id, {
  ValueChanged<double>? onSet,
}) => RowInfo(
  keys: doc.keys[id] ?? KeyframeState.off,
  child: InspectorNumberField(
    params[id]!,
    key: ValueKey('transform:$id'),
    id: id,
    caption: '',
    compact: true,
    onSet: onSet,
  ),
);

/// The width before a row's cells: its mark, its name and its unit.
double get rowLead => Shape.z(108);

/// One Transform row: a mark, the name (lit in its handle's colour while that handle is hot), the unit, then the cells
/// laid on the X / Y / Z columns. Hovering the row lights its handle on the preview.
class TransformRow extends StatelessWidget {
  const TransformRow({
    super.key,
    required this.label,
    required this.cells,
    this.mark,
    this.hot,
    this.unit = '',
    this.trail,
  });
  final String label, unit;
  final List<Widget> cells;
  final void Function(Canvas c, Size s)? mark;
  final TransformZone? hot;
  final Widget? trail;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: transformHot,
    builder: (context, lit, _) {
      final on = hot != null && lit == hot!.id;
      return MouseRegion(
        onEnter: (_) => hot == null ? null : transformHot.value = hot!.id,
        onExit: (_) => on ? transformHot.value = null : null,
        child: Padding(
          padding: EdgeInsets.only(top: Shape.s(3)),
          child: Row(
            children: [
              SizedBox(
                width: rowLead,
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: mark == null
                          ? null
                          : Center(
                              child: glyph(Shape.z(20), mark!, (
                                lit,
                                label,
                                Object.hashAll(
                                  InspectorScope.read(context)
                                      .doc
                                      .numbers
                                      .values,
                                ),
                              )),
                            ),
                    ),
                    SizedBox(width: Shape.s(4)),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyles.label(on ? hot!.color : Grey.g76),
                      ),
                    ),
                    ?trail,
                    if (unit.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(right: Shape.s(6)),
                        child: Text(unit, style: TextStyles.label(Grey.g56)),
                      ),
                  ],
                ),
              ),
              for (final (i, c) in cells.indexed) ...[
                if (i > 0) SizedBox(width: InspectorSkin.tileGap),
                // A lone cell (Rotation in 2D, Opacity, Parent) spans the three columns.
                Expanded(flex: cells.length == 1 ? 3 : 1, child: c),
              ],
              if (cells.length == 2) ...[
                SizedBox(width: InspectorSkin.tileGap),
                const Spacer(),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// X / Y / Z over the columns, in the axis colours.
class AxisHeader extends StatelessWidget {
  const AxisHeader({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: rowLead),
      for (final (i, (a, color)) in [
        ('X', axisX),
        ('Y', axisY),
        ('Z', axisZ),
      ].indexed) ...[
        if (i > 0) SizedBox(width: InspectorSkin.tileGap),
        Expanded(
          child: Text(
            a,
            textAlign: TextAlign.center,
            style: TextStyles.micro(Color.lerp(color, Grey.g100, .3)!)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ],
  );
}
