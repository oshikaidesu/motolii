import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/media.dart' show glyph;
import 'package:motolii/widgets/number_field.dart' show blockValue;

/// The panels that own lists of choices, such as fonts and colours.
/// The Inspector shows the current choice and links to the panel. It never holds the list itself.
enum LinkTo {
  fonts('Browser', 'Fonts'),
  colors('Browser', 'Colors');

  const LinkTo(this.panel, this.shelf);
  final String panel, shelf;
  String get route => panel == shelf ? panel : '$panel › $shelf';
}

/// The value line of a block tile whose value is chosen in another panel: the value, then where to choose it.
class LinkLine extends StatelessWidget {
  const LinkLine({super.key, required this.to, required this.value, required this.id});
  final LinkTo to;
  final String value, id;
  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context);
    return Pressable(
      key: ValueKey('link:${to.name}:$id'),
      onTap: () {
        // Record which parameter the target panel's pick should be applied to.
        x.doc.s2['route.at'] = id;
        x.doc.str('route', to.route);
      },
      builder: (_, h) => SizedBox(
        height: Shape.z(18),
        child: Row(
          children: [
            Expanded(
              child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: blockValue(Grey.g95)),
            ),
            // In a narrow tile the name is cut short like the value, never running over the edge.
            Flexible(
              child: Text(to.shelf, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyles.micro(h ? Grey.g95 : Grey.g56)),
            ),
            SizedBox(width: Shape.s(2)),
            glyph(7, (c, s) => _drawLinkArrow(c, s, h ? Grey.g95 : Grey.g56), h),
          ],
        ),
      ),
    );
  }
}

void _drawLinkArrow(Canvas canvas, Size s, Color c) {
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
