// Controls. One rule: the value is the loudest thing in a control, the chrome around it is grey, the family colour marks only what it belongs to.
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../skin/tokens.dart';

class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.index, this.onChanged});
  final List<String> items;
  final int index;
  final ValueChanged<int>? onChanged;

  /// One selected style: a g20 pill with g95 text and a 1px accent underline.
  @override
  Widget build(BuildContext context) {
    Widget seg(int i) => NakedToggleOption<int>(
      value: i,
      enableFeedback: false,
      semanticLabel: items[i],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: i == index ? Grey.g20 : null,
          borderRadius: BorderRadius.all(Shape.r(5)),
          border: Border(bottom: BorderSide(color: i == index ? Role.selected : const Color(0x00000000), width: 1)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(items[i].toUpperCase(), maxLines: 1, softWrap: false, style: T.micro(i == index ? Grey.g95 : Grey.g63).copyWith(letterSpacing: .4)),
        ),
      ),
    );
    return NakedToggleGroup<int>(
      selectedValue: index,
      onChanged: onChanged == null ? null : (v) => v == null ? null : onChanged!(v),
      child: Container(
        height: Shape.z(26),
        padding: EdgeInsets.all(Shape.s(2)),
        decoration: BoxDecoration(color: Grey.g07, borderRadius: BorderRadius.all(Shape.r(7))),
        child: Flex(
          direction: Axis.horizontal,
          children: [for (var i = 0; i < items.length; i++) Expanded(child: seg(i))],
        ),
      ),
    );
  }
}
