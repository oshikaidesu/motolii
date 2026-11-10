// The Tool Panel's Blend tool: lists the layers, front layer first, with the blend mode of each.
// Each mode is drawn as two overlapping discs, and the overlap shows the resulting color.
// Clicking a layer name selects it. Expanding a row shows every blend mode of that layer and the engine's Blending card (blend, clip).
// The list of modes comes from the engine (motolii_words); this file only draws them.
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Hov, IconPress;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart' show NakedFocusableDetector;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/paint_helpers.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/workspace/workspace.dart' show LayerCards;

/// The Blend tool: one row per layer, front layer first.
class BlendTool extends StatelessWidget {
  const BlendTool({super.key});
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked});
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: WsT.gap, vertical: Shape.s(6)),
      children: [for (final l in ws.layers) _Row(l, picked: l.id == ws.selected)],
    );
  }
}

/// One layer's row: name, current blend mode, and a button that expands the list of all modes.
class _Row extends StatefulWidget {
  const _Row(this.l, {required this.picked});
  final WsLayer l;
  final bool picked;
  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _open = false;
  String? _hover;
  @override
  Widget build(BuildContext context) {
    final l = widget.l, ws = WsScope.of(context, {WsAspect.document}), m = ws.inside, t = int.tryParse(l.id);
    final ways = m == null || t == null ? const <String>[] : m.words(t, 'blend');
    final now = ways.isEmpty ? '' : (m!.word(t!, 'blend').isEmpty ? ways.first : m.word(t, 'blend'));
    void say(String name, String word) {
      if (m != null && t != null) ws.after(m.later('say', layer: t, name: name, word: word));
    }

    final row = Container(
      height: Shape.z(34),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
      decoration: BoxDecoration(color: widget.picked ? WsT.well : null, borderRadius: BorderRadius.all(Shape.r(5))),
      child: Row(
        children: [
          Container(
            width: Shape.z(4),
            height: Shape.z(18),
            decoration: BoxDecoration(color: wsTone(l.kind), borderRadius: BorderRadius.all(Shape.r(2))),
          ),
          SizedBox(width: Shape.s(8)),
          Expanded(
            child: Hov(
              cursor: SystemMouseCursors.basic,
              onTap: () => ws.select(l.id),
              builder: (_, _) => Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.name(ways.isEmpty ? Grey.g56 : Grey.g91)),
            ),
          ),
          if (ways.isNotEmpty) ...[
            // The mode is also shown as text because two small icons can look alike.
            SizedBox(
              width: Shape.z(74),
              child: Text(
                now.replaceAll('_', ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: T.micro(now == 'normal' ? Grey.g56 : Grey.g91),
              ),
            ),
            SizedBox(width: Shape.s(4)),
            IconPress(
              paintInk((ink) => _Way(now, ink)),
              rest: WsT.well,
              ink: Grey.g76,
              key: ValueKey('blend.${l.id}'),
              size: Shape.z(24),
              on: _open,
              onTap: () => setState(() => _open = !_open),
            ),
          ],
        ],
      ),
    );
    if (!_open || ways.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(bottom: Shape.s(3)),
        child: row,
      );
    }
    // Group the modes as After Effects does: normal, darker, lighter, contrast, difference, color.
    // A mode that is in none of the groups goes with normal.
    final groups = <List<String>>[[], [], [], [], [], []];
    for (final w in ways) {
      groups[_group(w)].add(w);
    }
    for (final (k, g) in groups.indexed) {
      g.sort((x, y) => _order[k].indexOf(x).compareTo(_order[k].indexOf(y)));
    }
    return Padding(
      padding: EdgeInsets.only(bottom: Shape.s(3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          Padding(
            padding: EdgeInsets.fromLTRB(Shape.s(18), Shape.s(4), Shape.s(6), Shape.s(2)),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (k, g) in groups.indexed)
                  if (g.isNotEmpty) ...[
                    if (k > 0) SizedBox(width: Shape.s(8)),
                    for (final w in g)
                      NakedFocusableDetector(
                        canRequestFocus: false,
                        onHoverChange: (over) => setState(() => _hover = over ? w : null),
                        child: IconPress(
                          paintInk((ink) => _Way(w, ink)),
                          rest: WsT.well,
                          ink: Grey.g76,
                          key: ValueKey('blend.${l.id}.$w'),
                          size: Shape.z(26),
                          on: w == now,
                          onTap: () => say('blend', w),
                        ),
                      ),
                  ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Shape.s(20), Shape.s(2), Shape.s(6), Shape.s(4)),
            child: Text((_hover ?? now).replaceAll('_', ' '), style: T.micro(Grey.g76)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(Shape.s(18), 0, Shape.s(6), Shape.s(2)),
            child: LayerCards(layer: l.id, only: const ['Blending']),
          ),
        ],
      ),
    );
  }
}

/// The After Effects group of a blend mode: 0 normal, 1 darker, 2 lighter, 3 contrast, 4 difference, 5 color.
int _group(String w) => _order.indexWhere((g) => g.contains(w)).clamp(0, 5);

/// The After Effects blend mode groups, and the order of the modes within each group.
const _order = [
  ['normal'],
  ['darken', 'multiply', 'color_burn', 'linear_burn', 'darker_color'],
  ['add', 'lighten', 'screen', 'color_dodge', 'lighter_color'],
  ['overlay', 'soft_light', 'hard_light', 'linear_light', 'vivid_light', 'pin_light'],
  ['difference', 'exclusion', 'subtract', 'divide'],
  ['hue', 'saturation', 'color', 'luminosity'],
];

/// Draws a blend mode as two overlapping discs: a warm one below and a cool one above.
/// The overlap uses the color the engine produces for that mode with the same two colors.
class _Way extends CustomPainter {
  _Way(this.way, this.ink);
  final String way;
  final Color ink;
  static const _under = Color(0xFFCC4D33), _over = Color(0xFF3380E6);
  static const _meets = <String, Color>{
    'normal': Color(0xFF3380E6),
    'add': Color(0xFFD193EA),
    'multiply': Color(0xFF27222D),
    'screen': Color(0xFFCE8FE7),
    'darken': Color(0xFF334D33),
    'lighten': Color(0xFFCC80E6),
    'overlay': Color(0xFFAD4D5C),
    'soft_light': Color(0xFFB34D66),
    'hard_light': Color(0xFF524ED7),
    'color_dodge': Color(0xFFFF9BFF),
    'color_burn': Color(0xFF00001D),
    'difference': Color(0xFF9933B3),
    'exclusion': Color(0xFFAD80BD),
    'hue': Color(0xFF397AD2),
    'saturation': Color(0xFFDC4729),
    'color': Color(0xFF2F7CE2),
    'luminosity': Color(0xFFD05137),
    'linear_burn': Color(0xFF00001A),
    'linear_light': Color(0xFF334EFF),
    'vivid_light': Color(0xFF804DFF),
    'pin_light': Color(0xFF664DCD),
    'darker_color': Color(0xFFCC4D33),
    'lighter_color': Color(0xFF3380E6),
    'subtract': Color(0xFF990000),
    'divide': Color(0xFFFF9939),
  };
  @override
  void paint(Canvas c, Size s) {
    final r = s.shortestSide * .27, a = Offset(s.width * .38, s.height / 2), b = Offset(s.width * .62, s.height / 2);
    c.drawCircle(a, r, Paint()..color = _under);
    c.drawCircle(b, r, Paint()..color = _over);
    final lens = Path.combine(
      PathOperation.intersect,
      Path()..addOval(Rect.fromCircle(center: a, radius: r)),
      Path()..addOval(Rect.fromCircle(center: b, radius: r)),
    );
    c.drawPath(lens, Paint()..color = _meets[way] ?? _over);
  }

  @override
  bool shouldRepaint(_Way o) => o.way != way || o.ink != ink;
}
