// Small parts shared by the tool panel: a tool's sticker, the strip over a tool's body,
// a readout, and helpers for drawing text and dashed lines in a painter.
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/app_glyphs.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/window/panes.dart';
import 'package:motolii/workspace/state/state.dart';

/// The tool named [name], or null if there is none.
WsPane? panelTool(Ws ws, String name) => ws.tools.where((t) => t.name == name).firstOrNull;

/// A tool's sticker: a flat tile in its colour with the glyph knocked out in dark ink.
class ToolSticker extends StatelessWidget {
  const ToolSticker(this.name, {super.key, this.size = 16});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) {
    final tool = panelTool(WsScope.read(context), name);
    final tone = name == 'Tools' ? Grey.g76 : tool?.tone ?? Grey.g63;
    final g = name == 'Tools' ? DockG.tools : tool?.glyph;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(size * .3)),
      child: g == null
          // A tool the user made shows its first letter.
          ? Center(child: Text(name.characters.first, style: T.micro(WsT.onAccent)))
          : Glyph(g, size: size, color: WsT.onAccent),
    );
  }
}

/// A painted glyph for an [IconPress] tile: fills the tile, in the ink the press gives.
Widget Function(Color) paintInk(CustomPainter Function(Color ink) glyph) =>
    (ink) => SizedBox.expand(child: CustomPaint(painter: glyph(ink)));

/// The strip over a tool's body: what it works on at the left (cut off, never wrapped, when narrow), actions at the right.
class ToolStrip extends StatelessWidget {
  const ToolStrip({super.key, required this.left, this.right = const [], this.height, this.color, this.line = false, this.gap});
  final List<Widget> left, right;
  final double? height, gap;
  final Color? color;
  final bool line;
  @override
  Widget build(BuildContext context) => Container(
    height: height ?? Shape.z(26),
    padding: EdgeInsets.symmetric(horizontal: WsT.inset),
    decoration: BoxDecoration(
      color: color ?? WsT.card,
      border: line ? Border(top: BorderSide(color: WsT.line)) : null,
    ),
    child: Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(children: left),
          ),
        ),
        if (right.isNotEmpty) SizedBox(width: gap ?? WsT.gap),
        ...right,
      ],
    ),
  );
}

/// A big number with its unit and a quiet line under it.
class ToolReadout extends StatelessWidget {
  const ToolReadout({super.key, required this.value, this.unit = '', this.sub});
  final String value, unit;
  final String? sub;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: T.value(Grey.g95).copyWith(fontSize: T.px(18), fontWeight: FontWeight.w700, letterSpacing: -.5),
          ),
          if (unit.isNotEmpty) ...[SizedBox(width: Shape.s(2)), Text(unit, style: T.label(Grey.g63))],
        ],
      ),
      if (sub != null) ...[SizedBox(height: Shape.s(3)), Text(sub!, style: T.label(Grey.g56))],
    ],
  );
}

/// Draws a line of text in a painter, anchored by [ax] / [ay] (0 left/top, 1 right/bottom).
void toolText(Canvas c, String s, Offset at, TextStyle st, {double ax = 0, double ay = 0}) {
  final tp = lineText(s, st);
  tp.paint(c, at - Offset(tp.width * ax, tp.height * ay));
  tp.dispose();
}

/// A straight dashed line from [p] to [q]: [on] long, [off] apart.
void dashed(Canvas c, Offset p, Offset q, Color ink, double wide, double on, double off) {
  final line = Paint()
        ..color = ink
        ..strokeWidth = wide,
      far = (q - p).distance;
  for (var d = 0.0; d < far; d += on + off) {
    c.drawLine(Offset.lerp(p, q, d / far)!, Offset.lerp(p, q, ((d + on) / far).clamp(0.0, 1.0))!, line);
  }
}
