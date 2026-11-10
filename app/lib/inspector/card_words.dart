import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/widgets/more_menu.dart';

/// The Copy, Paste and Reset words in the head of a layer's own card, acting on the values [ids] as they are (like After Effects' Reset).
class CardWords extends StatelessWidget {
  const CardWords(this.name, this.ids, {super.key, this.more = const []});
  final String name;
  final List<String> ids;

  /// Extra items listed under the card's ⋮ menu.
  final List<(String, String, VoidCallback)> more;
  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (word, does) in [
          if (doc.actions.onCardCopy case final copy?)
            ('Copy', () => copy(ids)),
          if (doc.actions.onCardPaste case final paste?) ('Paste', paste),
          if (doc.actions.onCardReset case final reset?)
            ('Reset', () => reset(ids)),
        ])
          Padding(
            padding: EdgeInsets.only(right: Shape.s(6)),
            child: Chip(
              key: ValueKey('card-${word.toLowerCase()}:$name'),
              label: word,
              onTap: does,
              look: ChipLook.word,
            ),
          ),
        if (more.isNotEmpty) CardMore(name: name, items: more),
      ],
    );
  }
}
