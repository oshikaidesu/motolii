// Poster forms: the app's controls as a Swiss geometric poster, after Posterlad's Checkers and the Xavito deVito gig poster.
//
// Flat red, yellow, blue, green and pink on paper, with circles, half circles, quarters, triangles, stripes and heavy
// grotesque text. Each control is built from those blocks. Press and hover behaviour comes from naked_ui.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/forms/forms.dart';

const _red = Color(0xFFE5432D), _yellow = Color(0xFFF7D046), _blue = Color(0xFF2A62C9), _green = Color(0xFF6BBF8C), _pink = Color(0xFFF2A7C6);
const _ink = Color(0xFF111111), _paper = Color(0xFFF4F1EA);
const _blocks = [_red, _yellow, _blue, _green, _pink];

/// The poster's shapes, each filling its box.
enum Geo { circle, half, quarter, triangle, stripes, dot }

class GeoPaint extends CustomPainter {
  const GeoPaint(this.geo, this.ink, {this.ground});
  final Geo geo;
  final Color ink;
  final Color? ground;
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s, p = Paint()..color = ink;
    if (ground != null) c.drawRect(r, Paint()..color = ground!);
    c.save();
    c.clipRect(r);
    switch (geo) {
      case Geo.circle:
        c.drawCircle(r.center, s.shortestSide * .38, p);
      case Geo.dot:
        c.drawCircle(r.center, s.shortestSide * .18, p);
      case Geo.half:
        c.drawArc(Rect.fromCenter(center: r.bottomCenter, width: s.width, height: s.width), math.pi, math.pi, true, p);
      case Geo.quarter:
        c.drawArc(Rect.fromCircle(center: r.bottomLeft, radius: s.shortestSide), -math.pi / 2, math.pi / 2, true, p);
      case Geo.triangle:
        c.drawPath(Path()..addPolygon([r.bottomLeft, r.topRight, r.bottomRight], true), p);
      case Geo.stripes:
        final w = s.shortestSide / 5;
        for (var x = -s.height; x < s.width + s.height; x += w * 2) {
          c.drawPath(Path()..addPolygon([Offset(x, s.height), Offset(x + w, s.height), Offset(x + w + s.height, 0), Offset(x + s.height, 0)], true), p);
        }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(GeoPaint o) => o.geo != geo || o.ink != ink || o.ground != ground;
}

TextStyle _word(Color c, double size) => T.name(c).copyWith(fontSize: T.px(size), fontWeight: FontWeight.w800, letterSpacing: -.3, height: 1);

class PosterForms extends Forms {
  const PosterForms();

  /// A yellow block with the label, next to a black square with a paper circle.
  ///
  /// On hover the circle becomes a red quarter. While pressed the whole button sinks.
  @override
  Widget action(BuildContext context, ActionSpec a) => NakedButton(
    onPressed: a.onPressed,
    builder: (context, st, _) => Transform.translate(
      offset: Offset(0, st.isPressed ? 2 : 0),
      child: SizedBox(
        height: Shape.z(30),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: _yellow,
              padding: EdgeInsets.symmetric(horizontal: Shape.s(12)),
              alignment: Alignment.center,
              child: Text(a.label, style: _word(_ink, 14)),
            ),
            SizedBox.square(
              dimension: Shape.z(30),
              child: CustomPaint(painter: GeoPaint(st.isHovered ? Geo.quarter : Geo.circle, st.isHovered ? _red : _paper, ground: _ink)),
            ),
          ],
        ),
      ),
    ),
  );

  /// A black slot with a yellow disc, and ON or OFF in capitals beside it.
  ///
  /// When on, the slot turns green and the disc rolls to the right.
  @override
  Widget onOff(BuildContext context, SwitchSpec s) => NakedToggle(
    value: s.on,
    asSwitch: true,
    enabled: s.enabled,
    onChanged: s.onChanged,
    builder: (context, st, _) => Opacity(
      opacity: s.enabled ? 1 : .4,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.on ? 'ON' : 'OFF', style: _word(_ink, 11)),
          SizedBox(width: Shape.s(6)),
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutBack,
            width: Shape.z(36),
            height: Shape.z(18),
            color: s.on ? _green : _ink,
            alignment: s.on ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox.square(
              dimension: Shape.z(18),
              child: CustomPaint(painter: GeoPaint(Geo.circle, st.isHovered ? _pink : _yellow)),
            ),
          ),
        ],
      ),
    ),
  );

  /// A header of solid colour with the title in heavy black type and a shape at its end.
  ///
  /// The colour is one of the poster blocks, chosen from the title. The rows sit on paper beneath, framed by a black rule.
  @override
  Widget card(BuildContext context, CardSpec c) {
    final title = c.title ?? '', block = _blocks[title.codeUnits.fold(7, (a, b) => (a * 31 + b) & 0xffff) % _blocks.length];
    final geo = Geo.values[(title.length) % Geo.values.length];
    final head = NakedButton(
      onPressed: c.onToggle,
      builder: (context, st, _) => Container(
        height: Shape.z(34),
        color: block,
        padding: EdgeInsets.only(left: Shape.s(10)),
        child: Row(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title, maxLines: 1, style: _word(_ink, 18)),
              ),
            ),
            ?c.trailing,
            SizedBox.square(
              dimension: Shape.z(34),
              child: CustomPaint(painter: GeoPaint(c.open ? geo : Geo.dot, st.isHovered ? _paper : _ink, ground: c.open ? null : _paper)),
            ),
          ],
        ),
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: _paper,
        border: Border.all(color: _ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // A card with no title may still have a head, which is whatever sits at its end.
          if (c.title != null) head else ?c.head,
          if (c.open && c.body.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: Shape.s(10), vertical: Shape.s(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: c.body),
            ),
        ],
      ),
    );
  }
}
