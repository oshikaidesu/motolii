// What the Transform card holds inside its frame: Space, the preview and After Effects' Transform rows under one
// X / Y / Z heading. Restored from 52289b693~1 (inspector_direct_transform.dart, inspector_transform_rows.dart),
// each number now the panel's standard field.
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/card_declaration.dart';
import 'package:motolii/inspector/chooser.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/transform/row_marks.dart';
import 'package:motolii/inspector/transform/transform_canvas.dart';
import 'package:motolii/inspector/transform/transform_layout.dart';
import 'package:motolii/inspector/transform/transform_rows.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable, Segmented;
import 'package:motolii/widgets/media.dart' show glyph;

/// The Transform card's inside. Values of the card it does not draw are left to the card's own blocks below it.
class TransformBody extends StatelessWidget {
  const TransformBody(this.card, {super.key});
  final CardDeclaration card;

  /// The values drawn here. Scale Z is hidden in 2D (screen-attached, no world depth) and shown in 2.5D and 3D.
  /// X/Y Rotation is always shown: 2D rotates in screen space, 2.5D overrides its default camera-facing, 3D turns freely.
  /// (space semantics: kinds.h — 2d not in world; 2.5d a sheet in world, always facing viewer; 3d filmed by camera.)
  static const drawn = {
    'space', 'parent', 'x', 'y', 'z', 'scale_x', 'scale_y', 'scale_z', //
    'rotate_x', 'rotate_y', 'rotate', 'opacity',
  };

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final params = {for (final p in card.params) 'v_${p.id}': p};
    final space = params['v_space'];
    final linked = doc.flags['transform.link'] ?? true;
    Widget field(String id, {ValueChanged<double>? onSet}) =>
        axisField(params, doc, id, onSet: onSet);
    return ListenableBuilder(
      // The marks follow the values while a field or the preview is dragged.
      // v_space is watched so deep/tilted/scale recompute as soon as the mode changes.
      listenable: Listenable.merge([
        for (final id in TransformLayout.watched) doc.watch(id),
        doc.watch('v_opacity'),
        doc.watch('v_parent'),
        doc.watch('v_space'),
      ]),
      builder: (context, _) {
        final word = space?.options.elementAtOrNull(
          (doc.get('v_space') ?? 0).round(),
        );
        final deep = word != null && word.toLowerCase() != '2d';
        final scale = ['v_scale_x', 'v_scale_y', if (deep) 'v_scale_z'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (space != null)
              TransformRow(
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
            const AxisHeader(),
            TransformRow(
              mark: (c, s) => drawMove(c, s, _lit(TransformZone.move)),
              hot: TransformZone.move,
              label: 'Position',
              unit: params['v_x']?.unit ?? '',
              cells: [field('v_x'), field('v_y'), field('v_z')],
            ),
            TransformRow(
              mark: (c, s) => drawScale(
                c,
                s,
                _lit(TransformZone.scale),
                doc.get('v_scale_x') ?? 100,
                doc.get('v_scale_y') ?? 100,
              ),
              hot: TransformZone.scale,
              label: 'Scale',
              unit: params['v_scale_x']?.unit ?? '',
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
            TransformRow(
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
                field('v_rotate_x'),
                field('v_rotate_y'),
                field('v_rotate'),
              ],
            ),
            if (params['v_opacity'] case final op?)
              TransformRow(
                mark: (c, s) =>
                    drawOpacity(c, s, Grey.g76, doc.get('v_opacity') ?? 100),
                label: 'Opacity',
                unit: op.unit,
                cells: [field('v_opacity')],
              ),
            if (params['v_parent'] case final p?)
              TransformRow(
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
        );
      },
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
