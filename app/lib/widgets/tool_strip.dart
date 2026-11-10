// The strip over a tool's body and the big-number readout.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

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
