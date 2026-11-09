// Controls. One rule: the value is the loudest thing in a control, the chrome around it is grey, the family colour marks only what it belongs to.
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../skin/tokens.dart';

class PillSwitch extends StatelessWidget {
  const PillSwitch({super.key, required this.on, this.fam = Fam.scatter});
  final bool on;
  final Fam fam;

  /// Fine, not heavy (critique, 4 passes): a 28x16 track; off = a grey thumb on g20; on = an accent TINT with a 1px accent edge and a light thumb, never a solid accent block.
  @override
  Widget build(BuildContext context) => AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      width: Shape.z(28),
      height: Shape.z(16),
      padding: EdgeInsets.all(Shape.s(2)),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? Role.of(C.mode.withValues(alpha: .30), Grey.g20) : Grey.g20,
        borderRadius: BorderRadius.all(Shape.r(8)),
        border: Border.all(color: on ? Role.of(Role.selected.withValues(alpha: .85), Role.mode) : Grey.g26, width: 1),
      ),
      child: Container(
        width: Shape.z(10),
        height: Shape.z(10),
        decoration: BoxDecoration(color: on ? Role.of(Grey.g95, Role.mode) : Grey.g56, shape: BoxShape.circle),
      ),
  );
}

class Segmented extends StatelessWidget {
  const Segmented({super.key, required this.items, required this.index, this.onChanged, this.accent, this.expand = false});
  final List<String> items;
  final int index;
  final Color? accent;
  final bool expand;
  final ValueChanged<int>? onChanged;

  /// One selected style across the lab: a g20 pill with g95 text and a 1px accent underline (critique 2026-10-02: four selected styles were found).
  @override
  Widget build(BuildContext context) {
    Widget seg(int i) => NakedToggleOption<int>(
      value: i,
      enableFeedback: false,
      semanticLabel: items[i],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(horizontal: expand ? Shape.s(6) : Shape.s(12)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: i == index ? Grey.g20 : null,
          borderRadius: BorderRadius.all(Shape.r(5)),
          border: Border(bottom: BorderSide(color: i == index ? (accent ?? Role.selected) : const Color(0x00000000), width: 1)),
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
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [for (var i = 0; i < items.length; i++) expand ? Expanded(child: seg(i)) : seg(i)],
      ),
    ),
    );
  }
}
