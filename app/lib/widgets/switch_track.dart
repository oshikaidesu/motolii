import 'package:flutter/widgets.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';

/// The 28x16 on/off track.
class PopSwitch extends StatelessWidget {
  const PopSwitch({super.key, required this.on});
  final bool on;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 120),
    curve: Curves.easeOut,
    width: Shape.z(28),
    height: Shape.z(16),
    padding: EdgeInsets.all(Shape.s(2)),
    alignment: on ? Alignment.centerRight : Alignment.centerLeft,
    decoration: BoxDecoration(color: on ? InspectorSkin.accent : Grey.g26, borderRadius: BorderRadius.all(Shape.r(8))),
    child: Container(
      width: Shape.z(12),
      height: Shape.z(12),
      decoration: BoxDecoration(color: on ? InspectorSkin.onAccent : Grey.g63, shape: BoxShape.circle),
    ),
  );
}
