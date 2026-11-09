import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/controls/inspector_param_controls_tile.dart';

import '../../skin/tokens.dart';
import '../inspector_parts.dart';

/// An effect's parameters as blocks that fill the panel's width: three across in a normal panel, more when it is widened,
/// so thirty parameters stay a short list. Order is the shader's; a block that needs room (a point, a size, a choice) takes two.
class ParamGrid extends StatelessWidget {
  const ParamGrid(this.fx, this.params, {super.key});
  final String fx;
  final List<Param> params;

  static int span(Param p) => switch (p.look) {
    ParamLook.point || ParamLook.size || ParamLook.choice => 2,
    _ => 1,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final g = Pop.tileGap;
      final cols = math.max(1, ((box.maxWidth + g) / (Pop.tileMin + g)).floor());
      final rows = <List<Param>>[[]];
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
      // contract: a row cut short by a wide block stretches to the edge, so the grid never shows holes; only the last row may end early
      Widget row(List<Param> ps, bool last) {
        final filled = ps.fold<int>(0, (a, p) => a + math.min(span(p), cols));
        return Row(
          children: [
            for (var i = 0; i < ps.length; i++) ...[
              if (i > 0) SizedBox(width: g),
              Expanded(
                flex: math.min(span(ps[i]), cols),
                child: ParamTile(fx, ps[i]),
              ),
            ],
            if (last && filled < cols) ...[SizedBox(width: g), Spacer(flex: cols - filled)],
          ],
        );
      }

      return Padding(
        padding: EdgeInsets.only(top: Shape.s(4)),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[if (i > 0) SizedBox(height: g), row(rows[i], i == rows.length - 1)],
          ],
        ),
      );
    },
  );
}

/// The default value of every id a parameter owns, for a fresh layer and for Reset.
Map<String, double> paramDefaults(String fx, Param p) => switch (p.look) {
  ParamLook.point || ParamLook.size => {'${fx}_${p.id}.x': p.def, '${fx}_${p.id}.y': p.defY},
  ParamLook.color => const {},
  _ => {'${fx}_${p.id}': p.def},
};

/// A colour parameter's default as #RRGGBB, from its 0–1 components.
String paramColor(Decl d) {
  final c = [for (final s in d.attrs['default'] ?? const <String>[]) double.tryParse(s) ?? 1];
  int ch(int i) => ((c.elementAtOrNull(i) ?? 1) * 255).round().clamp(0, 255);
  return '#${[ch(0), ch(1), ch(2)].map((e) => e.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';
}
