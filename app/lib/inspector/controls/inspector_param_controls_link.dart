import 'package:flutter/widgets.dart';

import '../../skin/tokens.dart';
import '../inspector_parts.dart';

/// The panels that own lists (fonts, colours, eases). The Inspector shows what is set and sends you there; it never holds the list.
enum LinkTo {
  fonts('Browser', 'Fonts'),
  colors('Browser', 'Colors');

  const LinkTo(this.panel, this.shelf);
  final String panel, shelf;
  String get route => panel == shelf ? panel : '$panel › $shelf';
}

/// The value line of a block tile that is chosen elsewhere: the value, then where it is chosen.
class LinkLine extends StatelessWidget {
  const LinkLine({super.key, required this.to, required this.value, required this.id});
  final LinkTo to;
  final String value, id;
  @override
  Widget build(BuildContext context) {
    final x = Ctx.of(context);
    return Hov(
      key: ValueKey('link:${to.name}:$id'),
      onTap: () {
        x.doc.s2['route.at'] = id; // (the slot it is aimed at: the host may say the panel's pick to it)
        x.doc.str('route', to.route);
      },
      builder: (_, h) => SizedBox(
        height: Shape.z(18),
        child: Row(
          children: [
            Expanded(
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: blockValue(Grey.g95)),
            ),
            Flexible(
              child: Text(to.shelf, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.micro(h ? Grey.g95 : Grey.g56)),
            ), // (a narrow tile: cut short as its value is, never over the edge)
            SizedBox(width: Shape.s(2)),
            CustomPaint(size: const Size(7, 7), painter: _LinkArrowPaint(h ? Grey.g95 : Grey.g56)),
          ],
        ),
      ),
    );
  }
}

class _LinkArrowPaint extends CustomPainter {
  const _LinkArrowPaint(this.c);
  final Color c;
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = c
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(1, s.height - 1), Offset(s.width - 1, 1), p)
      ..drawPath(
        Path()
          ..moveTo(s.width * .35, 1)
          ..lineTo(s.width - 1, 1)
          ..lineTo(s.width - 1, s.height * .65),
        p,
      );
  }

  @override
  bool shouldRepaint(_LinkArrowPaint o) => o.c != c;
}
