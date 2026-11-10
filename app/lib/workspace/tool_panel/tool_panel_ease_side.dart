// The controls beside the Ease graph, laid out as in AbsentMotion's EasingPanel.kt (Apache-2.0): a left column with
// reverse and a menu, and a narrow row of easing shapes without names. The layout and behavior are ported; the colors are this app's.
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/controls.dart' show Hov, IconPress;
import 'package:motolii/widgets/media.dart' show Draw, glyph;

import 'package:motolii/inspector/inspector_card.dart' show CardMore;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_ease_cards.dart' show easeIsTurned, easeTurn;
import 'package:motolii/workspace/tool_panel/tool_panel_easing_presets.dart';
import 'package:motolii/workspace/tool_panel/tool_panel_widgets.dart';
import 'package:motolii/workspace/state/state.dart';

/// The easing shapes shown in one row, one click each.
/// They are Alight Motion's, in the order of AbsentMotion's EasingCatalog.families, with the four Beziers first.
/// The second row of AbsentMotion's panel is not needed because the shelf holds the rest.
const easeShapes = ['Linear', 'In', 'Out', 'In-out', 'Bounce', 'Elastic', 'Cyclic', 'Random', 'Steps', 'ElasticSteps'];

/// How many shapes a row of [length] shows: as many as fit at a good size, at least seven, plus part of the next one.
/// The cut-off shape tells the user there is more to scroll to.
double easeFits(double length) => (length / Shape.z(34)).floorToDouble().clamp(7, easeShapes.length) + .45;

/// Whether [e] is a Linear or Bezier curve.
bool easeIsBezier(Ease e) => const {'Linear', 'Bezier'}.contains(said(e).split(' ').first);

/// The row of shapes, followed by Hold, which is reached by scrolling.
List<Ease> easeRow(List<Ease> ways) {
  Ease? named(String n) => easingPresets.where((p) => p.name == n).firstOrNull ?? ways.where((w) => w.name == n).firstOrNull;
  return [for (final n in easeShapes) ?named(n), easingPreset('Hold')];
}

/// The easings from the app and the project that are not one of the shapes. They go on the shelf (tool_panel_ease_shelf.dart).
List<Ease> easeOthers(List<Ease> ways) => [
  for (final w in ways)
    if (!easeShapes.contains(w.name)) w,
];

/// Whether [now] is this shape, as in AbsentMotion's EasingCatalog.matches: a Bezier matches by its numbers, any other kind by its name.
bool _isOf(Ease shape, Ease now) {
  final word = said(now), base = easeIsTurned(word) ? easeTurn(word) : word;
  return easeIsBezier(shape) ? shape == now : said(shape).split(' ').first == base.split(' ').first;
}

/// The row beside the graph. Clicking a shape applies it to the keyframe interval, and clicking Linear straightens a curve.
class EaseShapes extends StatelessWidget {
  const EaseShapes({super.key, required this.ease, required this.shapes, required this.side, required this.onPick, this.across = false});

  /// The current easing.
  final Ease ease;
  final double side;

  /// Whether the row lies horizontally under the graph, which is used in a tall pane.
  final bool across;
  final List<Ease> shapes;

  /// Called with the shape the user clicked.
  final ValueChanged<Ease> onPick;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: WsT.card,
    child: LayoutBuilder(
      builder: (_, box) => ListView(
        scrollDirection: across ? Axis.horizontal : Axis.vertical,
        itemExtent: (across ? box.maxWidth : box.maxHeight) / easeFits(across ? box.maxWidth : box.maxHeight),
        children: [
          for (final e in shapes)
            EasingPresetTile(
              e,
              key: ValueKey('ease.${e.name}'),
              on: _isOf(e, ease),
              side: side,
              // Clicking the shape already in use does nothing, so its own numbers are kept.
              onTap: () => _isOf(e, ease) && !(easeIsBezier(e) && said(e) != said(ease)) ? null : onPick(e),
            ),
        ],
      ),
    ),
  );
}

/// The left column: a reverse button, and a ⋯ menu to copy and paste the curve.
/// The menu has Alight Motion's Copy Curve, Paste Curve and Paste Curve to All Keyframes, and this app's own Jump
/// (easeJump in tool_panel_ease_state.dart). Enable Overshoot is among the numbers instead.
class EaseLeft extends StatelessWidget {
  const EaseLeft({super.key, this.onReverse, required this.menu});

  /// Called to reverse the easing. Null when the easing cannot be reversed.
  final VoidCallback? onReverse;
  final List<(String, String, VoidCallback)> menu;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: WsT.card,
    child: Column(
      children: [
        const Spacer(flex: 2),
        Expanded(
          child: Center(
            child: Hov(
              key: const ValueKey('ease-reverse'),
              onTap: onReverse,
              builder: (_, h) =>
                  glyph(Shape.z(18), (cv, s) => _drawReverse(cv, s, onReverse == null ? Grey.g38 : (h ? Grey.g95 : Grey.g76)), (onReverse == null, h)),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: CardMore(name: 'Ease', word: '⋯', above: true, big: true, items: menu),
          ),
        ),
      ],
    ),
  );
}

// The reverse arrows, from AbsentMotion's EasingIcons.kt REVERSE_ARROWS.
void _drawReverse(Canvas c, Size s, Color ink) {
  c.scale(s.width / 24);
  c.drawPath(
    Path()
      ..moveTo(16, 3)
      ..lineTo(20, 7)
      ..lineTo(16, 11)
      ..moveTo(20, 7)
      ..lineTo(4, 7)
      ..moveTo(8, 21)
      ..lineTo(4, 17)
      ..lineTo(8, 13)
      ..moveTo(4, 17)
      ..lineTo(20, 17),
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

/// The arrow in a bottom corner of the graph that moves to the previous or next curve (AbsentMotion's StretchButton).
class EaseStep extends StatelessWidget {
  const EaseStep({super.key, required this.span, required this.back});
  final EaseSpan? span;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final s = span, ws = WsScope.of(context, {WsAspect.document});
    final keys = s == null ? const <int>[] : ([...s.layer.keys]..sort());
    final to = s == null
        ? null
        : back
        ? keys.where((f) => f < s.from).lastOrNull
        : (keys.any((f) => f > s.to) ? s.to : null);
    return to == null
        ? const SizedBox.shrink()
        : IconPress(
            paintInk((ink) => Draw((cv, s) => drawEaseChevron(cv, s, ink, back), (ink, back))),
            rest: WsT.well,
            ink: Grey.g76,
            key: ValueKey(back ? 'ease-previous' : 'ease-next'),
            size: Shape.z(18),
            onTap: () => ws.pickKey((layer: s!.layer.id, frame: to)),
          );
  }
}

/// Draws a chevron pointing back (left) or forward (right).
void drawEaseChevron(Canvas c, Size s, Color ink, bool back) {
  final x = back ? s.width * .6 : s.width * .4, d = back ? -s.width * .2 : s.width * .2;
  c.drawPath(
    Path()
      ..moveTo(x, s.height * .25)
      ..lineTo(x + d, s.height / 2)
      ..lineTo(x, s.height * .75),
    Paint()
      ..color = ink
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}
