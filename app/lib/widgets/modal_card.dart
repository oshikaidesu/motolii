// A dialog over the window, and the pieces that fill it: a dimmed scrim that closes the dialog when it is pressed, a card in the middle
// with a title, a labelled group of chips, and a labelled dropdown. The size box and the render box are made of these.
import 'dart:math' as math;

import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/context_menu.dart' show PressOutside;
import 'package:motolii/widgets/disclosure_triangle.dart';

/// A dialog card over a scrim. It closes itself the way a Mac or Windows dialog does: a press on the scrim, Esc and Cmd+. call [onClose],
/// and the keyboard focus goes back to where it was when it closes. Flutter's own Shortcuts and DismissIntent carry the keys.
/// A text field inside takes the focus itself; otherwise the card holds it, so Esc is heard either way.
class ModalCard extends StatefulWidget {
  const ModalCard({
    super.key,
    required this.title,
    required this.onClose,
    required this.children,
    this.cardKey,
    this.across = CrossAxisAlignment.start,
  });

  /// The heading of the card.
  final String title;

  /// What a press on the scrim, Esc and Cmd+. do.
  final VoidCallback onClose;

  /// What the card holds under its heading, and how it lines them up across the card.
  final List<Widget> children;
  final CrossAxisAlignment across;

  /// The key of the card itself, for the tests to find it by.
  final Key? cardKey;

  @override
  State<ModalCard> createState() => _ModalCardState();
}

class _ModalCardState extends State<ModalCard> {
  final _keys = FocusNode(debugLabel: 'dialog');
  // The widget that had the keyboard focus before the dialog opened, given it back on close.
  final _was = FocusManager.instance.primaryFocus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_inside(FocusManager.instance.primaryFocus)) {
        _keys.requestFocus();
      }
    });
  }

  bool _inside(FocusNode? n) {
    for (var p = n; p != null; p = p.parent) {
      if (p == _keys) return true;
    }
    return false;
  }

  @override
  void dispose() {
    _keys.dispose();
    _was?.requestFocus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: const {
      SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      SingleActivator(LogicalKeyboardKey.period, meta: true): DismissIntent(),
    },
    child: Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (_) {
            widget.onClose();
            return null;
          },
        ),
      },
      child: Focus(
        focusNode: _keys,
        child: Stack(
          children: [
            Positioned.fill(
              child: NakedButton(
                onPressed: widget.onClose,
                mouseCursor: SystemMouseCursors.basic,
                enableFeedback: false,
                child: const ColoredBox(color: Color(0x88000000)),
              ),
            ),
            Center(
              child: Container(
                key: widget.cardKey,
                width: Shape.z(380),
                padding: EdgeInsets.all(Shape.s(16)),
                decoration: BoxDecoration(
                  color: WindowTokens.card,
                  borderRadius: Shape.round(8),
                  border: Border.all(color: WindowTokens.line),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: widget.across,
                  children: [
                    Text(widget.title, style: TextStyles.title(Grey.g95).bold),
                    SizedBox(height: Shape.s(12)),
                    ...widget.children,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A small heading over a row of chips that wraps.
class ChipGroup extends StatelessWidget {
  const ChipGroup(this.label, this.chips, {super.key});
  final String label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyles.label(Grey.g56)),
      SizedBox(height: Shape.s(6)),
      Wrap(spacing: Shape.s(6), runSpacing: Shape.s(6), children: chips),
    ],
  );
}

/// A label beside a dropdown (an HTML `<select>`): a long list of choices that a short list would show as chips.
/// It uses naked_ui's NakedSelect, as [Chooser] does: the arrow keys move through the list, Return picks, Esc closes,
/// and it opens upward where there is no room below. Each option is a `(value, label)`; [value] is the chosen one.
class MenuRow<T> extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.menuKey,
  });
  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T>? onChanged;
  final Key? menuKey;

  static const _itemH = 24.0, _maxItems = 8;

  String get _shown =>
      options.where((o) => o.$1 == value).map((o) => o.$2).firstOrNull ??
      options.firstOrNull?.$2 ??
      '';

  Widget _list() => Container(
    padding: EdgeInsets.all(Shape.s(3)),
    decoration: BoxDecoration(
      color: Grey.g15,
      borderRadius: Shape.round(8),
      border: Border.all(color: Grey.g26),
      boxShadow: WindowTokens.lift,
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: Shape.z(_maxItems * _itemH)),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemExtent: Shape.z(_itemH),
        itemCount: options.length,
        itemBuilder: (_, i) => NakedSelectOption<T>(
          value: options[i].$1,
          builder: (_, st, _) {
            final sel = options[i].$1 == value,
                on = st.isHovered || st.isFocused;
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
          },
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: TextStyles.label(Grey.g56)),
      SizedBox(width: Shape.s(12)),
      SizedBox(
        width: Shape.z(130),
        child: NakedSelect<T>(
          value: value,
          onChanged: (v) {
            if (v != null) onChanged?.call(v);
          },
          useRootOverlay: true,
          closeOnClickOutside: false,
          consumeOutsideTaps: false,
          positioning: OverlayPositionConfig(sideOffset: Shape.s(4)),
          overlayBuilder: (context, info) => PressOutside(
            group: info.tapRegionGroupId,
            shut: () => MenuController.maybeOf(context)?.close(),
            child: SizedBox(
              width: math.max(info.anchorRect.width, Shape.z(130)),
              child: _list(),
            ),
          ),
          builder: (_, st, _) => Container(
            key: menuKey,
            height: Shape.z(26),
            padding: EdgeInsets.symmetric(horizontal: Shape.s(8)),
            decoration: BoxDecoration(
              color: st.isHovered || st.isOpen ? Grey.g10 : WindowTokens.well,
              borderRadius: Shape.round(6),
              border: Border.all(
                color: st.isOpen ? Grey.g63 : WindowTokens.line,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _shown,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.name(Grey.g91),
                  ),
                ),
                DisclosureTriangle(open: true, hot: st.isOpen),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
