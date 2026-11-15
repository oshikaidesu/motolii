import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart'
    show NakedSelect, NakedSelectOption, OverlayPositionConfig;

import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/context_menu.dart' show PressOutside;
import 'package:motolii/widgets/disclosure_triangle.dart';

/// A dropdown for choosing one of [options]. The value under [id] is the option's index, kept once, in numbers,
/// as a segmented control keeps it; the words are only what [options] says that index is.
///
/// A short list belongs in a segmented control and a long one opens a list. It never cycles with previous and next buttons.
/// naked_ui's NakedSelect (the select of the W3C ARIA Authoring Practices) owns the keys, the outside press, the focus and the placing:
/// the arrow keys move through the list, Return picks, Esc closes, and it opens upward where there is no room below.
class Chooser extends StatefulWidget {
  const Chooser({super.key, required this.id, required this.options});
  final String id;
  final List<String> options;
  @override
  State<Chooser> createState() => ChooserState();
}

class ChooserState extends State<Chooser> {
  static const _itemH = 22.0, _maxItems = 8;

  int _index(InspectorValues doc) =>
      (doc.get(widget.id) ?? 0).round().clamp(0, widget.options.length - 1);

  Widget _list(int cur) => Container(
    padding: EdgeInsets.all(Shape.s(3)),
    decoration: BoxDecoration(
      color: Grey.g15,
      borderRadius: Shape.round(8),
      border: Border.all(color: Grey.g26),
      boxShadow: [
        BoxShadow(
          color: ColorTheme.of('Shadow', const Color(0x99000000)),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: _maxItems * _itemH),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemExtent: _itemH,
        itemCount: widget.options.length,
        itemBuilder: (_, i) => NakedSelectOption<int>(
          value: i,
          builder: (_, st, _) {
            final sel = i == cur, on = st.isHovered || st.isFocused;
            return Container(
              padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
              decoration: BoxDecoration(
                color: on ? Grey.g26 : (sel ? Grey.g20 : null),
                borderRadius: Shape.round(5),
              ),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.options[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.name(sel || on ? Grey.g95 : Grey.g76),
                    ),
                  ),
                  if (sel)
                    Container(
                      width: Shape.z(5),
                      height: Shape.z(5),
                      decoration: BoxDecoration(
                        color: Grey.g95,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final x = InspectorScope.of(context), cur = _index(x.doc);
    return NakedSelect<int>(
      value: cur,
      onChanged: (i) {
        if (i != null) x.doc.set(widget.id, i.toDouble());
      },
      // Uses the root overlay, so a list that extends beyond its pane still receives pointer events.
      useRootOverlay: true,
      // Closing is done by PressOutside, the same as every menu: a left press outside closes it and does nothing else.
      closeOnClickOutside: false,
      consumeOutsideTaps: false,
      positioning: OverlayPositionConfig(sideOffset: Shape.s(4)),
      overlayBuilder: (context, info) => PressOutside(
        group: info.tapRegionGroupId,
        shut: () => MenuController.maybeOf(context)?.close(),
        child: SizedBox(
          width: math.max(info.anchorRect.width, 160),
          child: _list(cur),
        ),
      ),
      builder: (_, st, _) => Container(
        height: InspectorSkin.cell,
        padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
        decoration: BoxDecoration(
          color: st.isHovered || st.isOpen ? Grey.g10 : InspectorSkin.well,
          borderRadius: Shape.round(6),
          border: Border.all(
            color: st.isOpen ? Grey.g63 : const Color(0x00000000),
          ),
        ),
        // The mark at the right shows that this is a menu, so no extra label is needed.
        child: Row(
          children: [
            // The default value (the first option) is dim. A chosen one is bright.
            Expanded(
              child: Text(
                widget.options[cur],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.name(cur == 0 ? Grey.g56 : Grey.g91),
              ),
            ),
            DisclosureTriangle(open: true, hot: st.isOpen),
          ],
        ),
      ),
    );
  }
}
