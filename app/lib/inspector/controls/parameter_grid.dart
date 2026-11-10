import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/controls/parameter_tile.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/dice_painter.dart';

/// An effect's parameters as blocks that fill the panel's width.
///
/// A normal panel shows three blocks across, and a wider one shows more, so thirty parameters stay a short list.
/// The order is the shader's. A block that needs room, such as a point, a size or a choice, takes two columns.
class ParameterGrid extends StatelessWidget {
  const ParameterGrid(this.params, {super.key});
  final List<Parameter> params;

  /// How many columns the block for [p] takes.
  static int span(Parameter p) => switch (p.look) {
    ParameterLook.point || ParameterLook.size || ParameterLook.choice => 2,
    _ => 1,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final g = InspectorSkin.tileGap;
      final cols = math.max(
        1,
        ((box.maxWidth + g) / (InspectorSkin.tileMin + g)).floor(),
      );
      final rows = <List<Parameter>>[[]];
      var used = 0;
      for (final p in params) {
        final s = math.min(span(p), cols);
        if (used + s > cols) {
          rows.add([]);
          used = 0;
        }
        rows.last.add(p);
        used += s;
      }
      // A row cut short by a wide block stretches to the edge, so the grid has no holes. Only the last row may end early.
      Widget row(List<Parameter> ps, bool last) {
        final filled = ps.fold<int>(0, (a, p) => a + math.min(span(p), cols));
        return Row(
          children: [
            for (var i = 0; i < ps.length; i++) ...[
              if (i > 0) SizedBox(width: g),
              Expanded(
                flex: math.min(span(ps[i]), cols),
                child: ParameterTile(ps[i]),
              ),
            ],
            if (last && filled < cols) ...[
              SizedBox(width: g),
              Spacer(flex: cols - filled),
            ],
          ],
        );
      }

      return Padding(
        padding: EdgeInsets.only(top: Shape.s(4)),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) SizedBox(height: g),
              row(rows[i], i == rows.length - 1),
            ],
          ],
        ),
      );
    },
  );
}

/// Parses `#RRGGBB` into an opaque colour, or returns null if [s] is not in that form.
Color? hexControls(String? s) =>
    s != null && RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(s)
    ? Color(int.parse(s.substring(1), radix: 16) | 0xFF000000)
    : null;

/// The default value of every id a parameter owns, for a fresh layer and for Reset.
Map<String, double> paramDefaults(Parameter p) => switch (p.look) {
  ParameterLook.point ||
  ParameterLook.size => {'v_${p.id}.x': p.def, 'v_${p.id}.y': p.defY},
  ParameterLook.color => const {},
  _ => {'v_${p.id}': p.def},
};

/// A colour parameter's default as #RRGGBB, from its 0–1 components.
String paramColor(FieldDeclaration d) {
  final c = [
    for (final s in d.attrs['default'] ?? const <String>[])
      double.tryParse(s) ?? 1,
  ];
  int ch(int i) => ((c.elementAtOrNull(i) ?? 1) * 255).round().clamp(0, 255);
  return '#${[ch(0), ch(1), ch(2)].map((e) => e.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
}

/// A small colour chip: one colour from [hex], or a gradient through [ramp].
class Swatch extends StatelessWidget {
  const Swatch(this.hex, {super.key, this.ramp});
  final String? hex;

  /// Colours in order, drawn as a strip from the first to the last. When set, [hex] is ignored.
  final List<String>? ramp;
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: Shape.z(16),
      height: Shape.z(16),
      decoration: BoxDecoration(
        gradient: ramp == null
            ? null
            : LinearGradient(colors: [for (final h in ramp!) hexControls(h)!]),
        color: ramp == null ? hexControls(hex) ?? Grey.g26 : null,
        borderRadius: BorderRadius.all(Shape.r(4)),
        border: Border.all(color: Grey.g38),
      ),
    ),
  );
}

/// Plus and minus buttons for a small whole number, stacked to stay one block tall.
/// The number itself is the field beside them.
class Steps extends StatelessWidget {
  const Steps({super.key, required this.id, required this.p});
  final String id;
  final Parameter p;
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), doc = x.doc, v = doc.get(id) ?? p.def;
    Widget btn(String s, double by) => Pressable(
      onTap: () => doc.set(id, p.typed(v + by)),
      builder: (_, h) => Container(
        width: InspectorSkin.glyph,
        height: (InspectorSkin.tile - 2 - 8 - 2) / 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: h ? Grey.g38 : Grey.g20,
          borderRadius: BorderRadius.all(Shape.r(4)),
        ),
        child: Text(
          s,
          style: TextStyles.label(Grey.g91)
              .copyWith(fontWeight: FontWeight.w700, height: 1),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn('+', 1),
        SizedBox(height: Shape.s(2)),
        btn('−', -1),
      ],
    );
  }
}

/// A seed's re-roll button: clicking the die picks another random value. The number stays editable beside it.
class Dice extends StatelessWidget {
  const Dice({super.key, required this.id, required this.p});
  final String id;
  final Parameter p;
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), doc = x.doc;
    return Pressable(
      onTap: () {
        // With no declared top, a roll stays where a 32-bit float still holds every whole number (IEEE 754 binary32, 2^24).
        final v = doc.get(id) ?? 0, hi = p.max ?? 16777216, lo = p.min ?? 0;
        doc.set(id, (lo + (v * 7919 + 104729) % (hi - lo + 1)).roundToDouble());
      },
      builder: (_, h) => CustomPaint(
        size: const Size(22, 22),
        painter: DicePainter(
          h ? Grey.g95 : Grey.g76,
          (doc.get(id) ?? 0).round() % 6 + 1,
        ),
      ),
    );
  }
}
