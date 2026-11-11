// A dialog over the window, and the pieces that fill it: a dimmed scrim that closes the dialog when it is pressed, a card in the middle
// with a title, and a labelled group of chips. The size box and the render box are made of these.
import 'package:flutter/widgets.dart';

import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

class ModalCard extends StatelessWidget {
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

  /// What a press on the scrim does.
  final VoidCallback onClose;

  /// What the card holds under its heading, and how it lines them up across the card.
  final List<Widget> children;
  final CrossAxisAlignment across;

  /// The key of the card itself, for the tests to find it by.
  final Key? cardKey;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: NakedButton(
          onPressed: onClose,
          mouseCursor: SystemMouseCursors.basic,
          enableFeedback: false,
          child: const ColoredBox(color: Color(0x88000000)),
        ),
      ),
      Center(
        child: Container(
          key: cardKey,
          width: Shape.z(380),
          padding: EdgeInsets.all(Shape.s(16)),
          decoration: BoxDecoration(
            color: WindowTokens.card,
            borderRadius: BorderRadius.all(Shape.r(8)),
            border: Border.all(color: WindowTokens.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: across,
            children: [
              Text(
                title,
                style: TextStyles.title(Grey.g95)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: Shape.s(12)),
              ...children,
            ],
          ),
        ),
      ),
    ],
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
