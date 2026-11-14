import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart'
    show OverlayAlignment, OverlayPositionConfig, OverlaySide;

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Pressable;
import 'package:motolii/widgets/context_menu.dart'
    show ContextMenuItem, MenuHost;

/// The ⋮ button of an effect card, like AbsentMotion's EffectHeader More.
///
/// It opens a short list over the panel, styled like Chooser's lists, of the other things the user can do with the card.
/// Picking an item runs it and closes the list.
class CardMore extends StatefulWidget {
  const CardMore({
    super.key,
    required this.name,
    required this.items,
    this.word = '⋮',
    this.above = false,
    this.big = false,
  });
  final String name, word;

  /// [above] opens the list upward, for a button at the foot of the window (AbsentMotion's AboveAnchor).
  final bool above, big;
  final List<(String key, String label, VoidCallback does)> items;
  @override
  State<CardMore> createState() => _CardMoreState();
}

class _CardMoreState extends State<CardMore> {
  final _m = MenuController();

  @override
  Widget build(BuildContext context) => MenuHost(
    controller: _m,
    useRootOverlay: true,
    items: [
      for (final (k, l, f) in widget.items)
        ContextMenuItem(l, f, id: 'card-$k:${widget.name}'),
    ],
    width: Shape.z(150),
    // Below the button with the right edges together, or above it for a button at the foot of the window; the library flips it where there is no room.
    positioning: OverlayPositionConfig(
      side: widget.above ? OverlaySide.top : OverlaySide.bottom,
      alignment: widget.above ? OverlayAlignment.start : OverlayAlignment.end,
    ),
    child: Pressable(
      key: ValueKey('card-more:${widget.name}'),
      onTap: widget.items.isEmpty
          ? null
          : () => _m.isOpen ? _m.close() : _m.open(),
      builder: (_, h) => Padding(
        padding: EdgeInsets.only(right: Shape.s(6)),
        child: Text(
          widget.word,
          style:
              TextStyles.label(
                h
                    ? Grey.g95
                    : widget.big
                    ? Grey.g76
                    : Grey.g56,
              ).copyWith(
                fontSize: widget.big ? TextStyles.px(20) : null,
                fontWeight: widget.big ? FontWeight.w700 : null,
              ),
        ),
      ),
    ),
  );
}
