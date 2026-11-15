// A dialog over the window, and the pieces that fill it: a dimmed scrim that closes the dialog when it is pressed, a card in the middle
// with a title, and a labelled group of chips. The size box and the render box are made of these.
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

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
