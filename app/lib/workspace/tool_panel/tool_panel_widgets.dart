// The tool panel's shared small things: a tool's sticker, and the round
// touchables the tool panel's bodies use (chip, icon button, scrub field, readout).
import 'package:flutter/widgets.dart';

import '../dock/dock_glyphs.dart';

import '../../widgets/text_gestures.dart';
import '../../skin/tokens.dart';
import '../window/panes.dart';
import '../state/state.dart';
import '../../widgets/two_fingers.dart';

WsPane? panelTool(Ws ws, String name) => ws.tools.where((t) => t.name == name).firstOrNull;

/// A tool's sticker: a flat tile of its hue with the glyph knocked out in dark ink.
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
          ? Center(child: Text(name.characters.first, style: T.micro(WsT.onAccent))) // (a tool of your own: its first letter)
          : DockGlyph(g, size: size, color: WsT.onAccent),
    );
  }
}

/// A painted glyph for an [IconPress] tile: fills the tile, in the ink the press gives.
Widget Function(Color) paintInk(CustomPainter Function(Color ink) glyph) =>
    (ink) => SizedBox.expand(child: CustomPaint(painter: glyph(ink)));

/// A field you scrub sideways: label left, value right, a fill bar shows where the value sits in its range.
class ToolScrub extends StatefulWidget {
  const ToolScrub({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.format,
    this.perPx = 1,
  });
  final String label;
  final double value, min, max, perPx;
  final ValueChanged<double> onChanged;
  final String Function(double) format;
  @override
  State<ToolScrub> createState() => _ToolScrubState();
}

class _ToolScrubState extends State<ToolScrub> {
  bool _hot = false, _drag = false, _typing = false;
  final _words = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus || !_typing) return;
      setState(() => _typing = false);
      if (wsNumber(_words.text) case final v?) widget.onChanged(v.clamp(widget.min, widget.max));
    });
  }

  @override
  void dispose() {
    _words.dispose();
    _focus.dispose();
    super.dispose();
  }

  // (pressed, it is written: as the window's other numbers. Its number alone, all of it picked: what is typed takes its place)
  void _write() {
    final now = RegExp(r'-?[\d.]+').stringMatch(widget.format(widget.value)) ?? '';
    _words.value = TextEditingValue(
      text: now,
      selection: TextSelection(baseOffset: 0, extentOffset: now.length),
    );
    setState(() => _typing = true);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget, f = ((w.value - w.min) / (w.max - w.min)).clamp(0.0, 1.0);
    final live = _hot || _drag;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      onEnter: (_) => setState(() => _hot = true),
      onExit: (_) => setState(() => _hot = false),
      child: GestureDetector(
        supportedDevices: wsPressing,
        behavior: HitTestBehavior.opaque,
        onTap: !_typing ? _write : null,
        onHorizontalDragStart: (_) => setState(() => _drag = true),
        onHorizontalDragUpdate: (d) => w.onChanged((w.value + d.delta.dx * w.perPx).clamp(w.min, w.max)),
        onHorizontalDragEnd: (_) => setState(() => _drag = false),
        child: Container(
          height: Shape.z(22),
          decoration: BoxDecoration(color: live ? WsT.raised : WsT.well, borderRadius: BorderRadius.all(Shape.r(WsT.radius))),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                left: 4,
                right: 4,
                bottom: 2,
                height: Shape.z(2),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: f,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: _drag ? WsT.accent : WsT.accent, borderRadius: BorderRadius.all(Shape.r(1))),
                  ),
                ),
              ),
              Positioned.fill(
                left: 7,
                right: 7,
                child: Row(
                  children: [
                    Text(w.label, style: T.label(Grey.g63)),
                    SizedBox(width: Shape.s(4)),
                    Expanded(
                      child: FittedBox(
                        // (a number wider than its field is drawn smaller, never cut)
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: _typing
                            ? SizedBox(
                                width: Shape.z(44),
                                child: TextGestures(
                                  field: (k) => EditableText(
                                    key: k,
                                    rendererIgnoresPointer: true,
                                    controller: _words,
                                    focusNode: _focus,
                                    style: T.value(Grey.g100).copyWith(fontSize: T.px(10.5)),
                                    cursorColor: WsT.accent,
                                    backgroundCursorColor: Grey.g38,
                                    selectionColor: WsT.accent.withValues(alpha: .3),
                                    textAlign: TextAlign.right,
                                    maxLines: 1,
                                    onSubmitted: (_) => _focus.unfocus(),
                                  ),
                                ),
                              )
                            : Text(w.format(w.value), maxLines: 1, style: T.value(_drag ? Grey.g100 : Grey.g91).copyWith(fontSize: T.px(10.5))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
