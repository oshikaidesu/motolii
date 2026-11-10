import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Hov;
import 'package:motolii/widgets/float_shut.dart';
import 'package:motolii/widgets/menu.dart' show ContextMenuItem, ContextMenuList;

/// The ⋮ button of an effect card, like AbsentMotion's EffectHeader More.
///
/// It opens a short list over the panel, styled like Chooser's lists, of the other things the user can do with the card.
/// Picking an item runs it and closes the list.
class CardMore extends StatefulWidget {
  const CardMore({super.key, required this.name, required this.items, this.word = '⋮', this.above = false, this.big = false});
  final String name, word;

  /// [above] opens the list upward, for a button at the foot of the window (AbsentMotion's AboveAnchor).
  final bool above, big;
  final List<(String key, String label, VoidCallback does)> items;
  @override
  State<CardMore> createState() => _CardMoreState();
}

class _CardMoreState extends State<CardMore> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();
  // Opened upward because there is no room below, as TinyMenuAt does.
  bool _up = false;

  void _open() {
    final box = context.findRenderObject()! as RenderBox;
    final foot = box.localToGlobal(box.size.bottomLeft(Offset.zero)).dy;
    setState(() => _up = foot + widget.items.length * Shape.z(22) + 2 * Shape.s(3) + 2 > MediaQuery.sizeOf(context).height);
    _portal.toggle();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _link,
    child: OverlayPortal.targetsRootOverlay(
      controller: _portal,
      overlayChildBuilder: (_) => Align(
        alignment: Alignment.topLeft,
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: widget.above
              ? Alignment.topLeft
              : _up
              ? Alignment.topRight
              : Alignment.bottomRight,
          followerAnchor: widget.above
              ? Alignment.bottomLeft
              : _up
              ? Alignment.bottomRight
              : Alignment.topRight,
          child: FloatShut(
            shut: _portal.hide,
            group: _link,
            child: ContextMenuList(
              items: [for (final (k, l, f) in widget.items) ContextMenuItem(l, f, id: 'card-$k:${widget.name}')],
              close: _portal.hide,
              max: MediaQuery.sizeOf(context).height * .5,
              width: Shape.z(150),
            ),
          ),
        ),
      ),
      child: TapRegion(
        // A press on the ⋮ itself is not an outside tap, so the ⋮ closes the list instead of it closing and reopening.
        groupId: _link,
        child: Hov(
          key: ValueKey('card-more:${widget.name}'),
          onTap: widget.items.isEmpty ? null : _open,
          builder: (_, h) => Padding(
            padding: EdgeInsets.only(right: Shape.s(6)),
            child: Text(
              widget.word,
              style: T
                  .label(
                    h
                        ? Grey.g95
                        : widget.big
                        ? Grey.g76
                        : Grey.g56,
                  )
                  .copyWith(fontSize: widget.big ? T.px(20) : null, fontWeight: widget.big ? FontWeight.w700 : null),
            ),
          ),
        ),
      ),
    ),
  );
}
