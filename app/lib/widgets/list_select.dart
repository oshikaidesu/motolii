// A dropdown (an HTML `<select>`) and the list it opens: the one list every menu of choices in the window shows.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart'
    show
        NakedSelect,
        NakedSelectOption,
        NakedSelectState,
        OverlayPositionConfig;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart' show PressOutside;

/// A dropdown for choosing one of [options], each a `(value, label)`; [value] is the chosen one and [builder] draws
/// what is pressed to open the list.
///
/// naked_ui's NakedSelect (the select of the W3C ARIA Authoring Practices) owns the keys, the focus and the placing:
/// the arrow keys move through the list, Return picks, Esc closes, and it opens upward where there is no room below.
class ListSelect<T> extends StatelessWidget {
  const ListSelect({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    required this.builder,
    required this.itemHeight,
    this.maxItems = 8,
    required this.minWidth,
    this.wider = 0,
    this.hover,
  });
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;
  final ValueWidgetBuilder<NakedSelectState<T>> builder;

  /// The height of one option, and how many are seen before the list scrolls.
  final double itemHeight;
  final int maxItems;

  /// The list is as wide as what opens it plus [wider], and never narrower than [minWidth].
  final double minWidth, wider;

  /// Where the option under the pointer is written while the list is open, null when there is none.
  final ValueNotifier<T?>? hover;

  Widget _option(int i, bool on) {
    final sel = options[i].$1 == value;
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
              options[i].$2,
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
  }

  Widget _list() => Container(
    padding: EdgeInsets.all(Shape.s(3)),
    decoration: BoxDecoration(
      color: Grey.g15,
      borderRadius: Shape.round(8),
      border: Border.all(color: Grey.g26),
      boxShadow: WindowTokens.lift,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxItems * itemHeight),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemExtent: itemHeight,
        itemCount: options.length,
        itemBuilder: (_, i) => NakedSelectOption<T>(
          value: options[i].$1,
          builder: (_, st, _) {
            final row = _option(i, st.isHovered || st.isFocused);
            final over = hover;
            if (over == null) return row;
            return MouseRegion(
              onEnter: (_) => over.value = options[i].$1,
              // Leaving the whole list clears it below, so one option clears only what is still its own.
              onExit: (_) {
                if (over.value == options[i].$1) over.value = null;
              },
              child: row,
            );
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => NakedSelect<T>(
    value: value,
    onChanged: (v) {
      hover?.value = null;
      if (v != null) onChanged(v);
    },
    // Uses the root overlay, so a list that extends beyond its pane still receives pointer events.
    useRootOverlay: true,
    // Closing is done by PressOutside, the same as every menu: a left press outside closes it and does nothing else.
    closeOnClickOutside: false,
    consumeOutsideTaps: false,
    positioning: OverlayPositionConfig(sideOffset: Shape.s(4)),
    overlayBuilder: (context, info) {
      final list = SizedBox(
        width: math.max(info.anchorRect.width + wider, minWidth),
        child: _list(),
      );
      return PressOutside(
        group: info.tapRegionGroupId,
        shut: () {
          hover?.value = null;
          MenuController.maybeOf(context)?.close();
        },
        child: hover == null
            ? list
            : MouseRegion(onExit: (_) => hover?.value = null, child: list),
      );
    },
    builder: builder,
  );
}
