// What the Transform card holds inside its frame: Space, the preview and After Effects' Transform rows under one
// X / Y / Z heading. Restored from 52289b693~1 (inspector_direct_transform.dart, inspector_transform_rows.dart),
// each number now the panel's standard field.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/chooser.dart';
import 'package:motolii/inspector/controls/inspector_number_field.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/rows/row_info.dart';
import 'package:motolii/inspector/transform/row_marks.dart';
import 'package:motolii/inspector/transform/transform_canvas.dart';
import 'package:motolii/inspector/transform/transform_layout.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable, Segmented;
import 'package:motolii/widgets/media.dart' show glyph;

/// The Transform card's inside. Values of the card it does not draw are left to the card's own blocks below it.
class TransformBody extends StatelessWidget {
  const TransformBody(this.card, {super.key});
  final CardDeclaration card;

  /// The values drawn here. A 2D layer's Scale Z and X and Y Rotation stay out of sight until they are set or the layer
  /// leaves 2D, as in After Effects' Transform of a 2D layer.
  static const drawn = {
    'space', 'parent', 'x', 'y', 'z', 'scale_x', 'scale_y', 'scale_z', //
    'rotate_x', 'rotate_y', 'rotate', 'opacity',
  };

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final params = {for (final p in card.params) 'v_${p.id}': p};
    bool has(String id) => params.containsKey(id);
    bool moved(String id) =>
        (doc.get(id) ?? 0) != (doc.numberDefaults[id] ?? 0);
    final space = params['v_space'];
    final word = space?.options.elementAtOrNull(
      (doc.get('v_space') ?? 0).round(),
    );
    final deep = word != null && word.toLowerCase() != '2d';
    final linked = doc.flags['transform.link'] ?? true;
    final scale = [
      for (final a in const ['x', 'y', 'z'])
        if (has('v_scale_$a') && (a != 'z' || deep || moved('v_scale_z')))
          'v_scale_$a',
    ];
    final tilted = deep || moved('v_rotate_x') || moved('v_rotate_y');
    Widget field(String id, {ValueChanged<double>? onSet}) => RowInfo(
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
    return ListenableBuilder(
      // The marks follow the values while a field or the preview is dragged.
      listenable: Listenable.merge([
        for (final id in TransformLayout.watched) doc.watch(id),
        doc.watch('v_opacity'),
        doc.watch('v_parent'),
      ]),
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (space != null)
            _Row(
              label: 'Space',
              cells: [
                Segmented(
                  key: const ValueKey('choice:v_space'),
                  items: space.options,
                  index: (doc.get('v_space') ?? 0).round().clamp(
                    0,
                    space.options.length - 1,
                  ),
                  onChanged: (i) => doc.set('v_space', i.toDouble()),
                  glyphs: [for (final o in space.options) _spaceGlyph(o)],
                ),
              ],
            ),
          TransformCanvas(params: params, deep: deep, linked: linked),
          SizedBox(height: InspectorSkin.titleGap),
          const _AxisHeader(),
          if (has('v_x'))
            _Row(
              mark: (c, s) => drawMove(c, s, _lit(TransformZone.move)),
              hot: TransformZone.move,
              label: 'Position',
              unit: params['v_x']!.unit,
              cells: [
                for (final a in const ['x', 'y', 'z'])
                  if (has('v_$a')) field('v_$a'),
              ],
            ),
          if (scale.isNotEmpty)
            _Row(
              mark: (c, s) => drawScale(
                c,
                s,
                _lit(TransformZone.scale),
                doc.get('v_scale_x') ?? 100,
                doc.get('v_scale_y') ?? 100,
              ),
              hot: TransformZone.scale,
              label: 'Scale',
              unit: params[scale.first]!.unit,
              trail: _Link(
                on: linked,
                onTap: () => doc.flag('transform.link', !linked),
              ),
              cells: [
                for (final id in scale)
                  field(
                    id,
                    onSet: linked
                        ? (v) => _scaleLinked(doc, scale, id, v, params)
                        : null,
                  ),
              ],
            ),
          if (has('v_rotate'))
            _Row(
              mark: (c, s) => drawRotation(
                c,
                s,
                _lit(TransformZone.rotate),
                doc.get('v_rotate') ?? 0,
              ),
              hot: TransformZone.rotate,
              label: 'Rotation',
              unit: params['v_rotate']!.unit,
              cells: [
                if (tilted) ...[
                  for (final a in const ['v_rotate_x', 'v_rotate_y'])
                    if (has(a)) field(a),
                ],
                field('v_rotate'),
              ],
            ),
          if (has('v_opacity'))
            _Row(
              mark: (c, s) =>
                  drawOpacity(c, s, Grey.g76, doc.get('v_opacity') ?? 100),
              label: 'Opacity',
              unit: params['v_opacity']!.unit,
              cells: [field('v_opacity')],
            ),
          if (params['v_parent'] case final p?)
            _Row(
              mark: (c, s) => drawChain(
                c,
                s,
                (doc.get('v_parent') ?? 0) > 0 ? Grey.g76 : Grey.g44,
              ),
              label: 'Parent',
              cells: [
                SizedBox(
                  height: InspectorSkin.cell,
                  child: Chooser(id: 'v_parent', options: p.options),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _lit(TransformZone z) =>
      transformHot.value == z.id ? z.color : Grey.g76;
}

/// After Effects' Scale with Constrain Proportions: a typed or dragged value sets its axis and moves the others by the
/// same factor; from zero, every axis takes the value.
void _scaleLinked(
  InspectorValues doc,
  List<String> axes,
  String id,
  double v,
  Map<String, Parameter> params,
) {
  final old = doc.get(id) ?? 100;
  doc.setMany({
    for (final a in axes)
      a: a == id
          ? v
          : params[a]!.typed(old == 0 ? v : (doc.get(a) ?? 100) * v / old),
  });
}

void Function(Canvas, Paint) _spaceGlyph(String word) => (c, st) {
  Path poly(List<Offset> p) => Path()..addPolygon(p, true);
  switch (word.toLowerCase()) {
    case '2d':
      c.drawRect(const Rect.fromLTWH(2, 1.5, 12, 11), st);
    case '2.5d':
      c.drawPath(
        poly(const [
          Offset(5, 2),
          Offset(15, 2),
          Offset(11, 12),
          Offset(1, 12),
        ]),
        st,
      );
    default:
      c.drawPath(
        poly(const [
          Offset(1, 4.5),
          Offset(10, 4.5),
          Offset(10, 13),
          Offset(1, 13),
        ]),
        st,
      );
      c.drawPath(
        poly(const [
          Offset(1, 4.5),
          Offset(5, 1),
          Offset(14, 1),
          Offset(10, 4.5),
        ]),
        st,
      );
      c.drawPath(
        poly(const [
          Offset(10, 4.5),
          Offset(14, 1),
          Offset(14, 9.5),
          Offset(10, 13),
        ]),
        st,
      );
  }
};

/// The width before a row's cells: its mark, its name and its unit.
double get _lead => Shape.z(108);

/// One Transform row: a mark, the name (lit in its handle's colour while that handle is hot), the unit, then the cells
/// laid on the X / Y / Z columns. Hovering the row lights its handle on the preview.
class _Row extends StatelessWidget {
  const _Row({
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
                width: _lead,
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
class _AxisHeader extends StatelessWidget {
  const _AxisHeader();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(width: _lead),
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

/// Scale's link: a closed chain while the sides scale together, a broken one while each is free.
class _Link extends StatelessWidget {
  const _Link({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    toggled: on,
    label: 'Link',
    child: Pressable(
      key: const ValueKey('transform:link'),
      onTap: onTap,
      builder: (_, h) => glyph(
        Shape.z(18),
        (c, s) => drawChain(
          c,
          s,
          on ? (h ? Grey.g100 : Grey.g91) : (h ? Grey.g76 : Grey.g44),
          open: !on,
          scale: .6,
          width: 1.2,
        ),
        (on, h),
      ),
    ),
  );
}
