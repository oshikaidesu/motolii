import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/empty_state.dart';
import 'package:motolii/inspector/inspector_header.dart';
import 'package:motolii/inspector/inspector_scope.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';
import 'package:motolii/inspector/values_card.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook, Pressable;
import 'package:motolii/widgets/more_menu.dart';
import 'package:motolii/widgets/text_gestures.dart';

// Every card follows one rule. The engine declares the cards (card_table.h, sent by motolii_cards and
// written as a WGSL uniform struct by workspace/inspector_feed/cards.dart), and [ValuesCard] draws each one the way it draws an effect.
// No card is named in this file.

// Where the Add Effect row goes: after the last card that is an effect, as Alight Motion's list ends.
// doc_cards_of lays the effects out before the other cards. With no effect, it goes at the end.
int _addAt(InspectorValues doc) {
  final at =
      doc.cards.lastIndexWhere((c) => doc.layer.movable.contains(c.name)) + 1;
  return at > 0 ? at : doc.cards.length;
}

/// The Add Effect row under a layer's effects, as in Alight Motion. It opens the shelf of effects with search ready.
class AddEffectRow extends StatelessWidget {
  const AddEffectRow({super.key});
  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc;
    final names = [
      'fx',
      'fx_off',
      for (final c in doc.cards)
        if (doc.layer.movable.contains(c.name))
          for (final p in c.params) p.id,
    ];
    Widget word(String key, String word, VoidCallback? does) => Padding(
      padding: EdgeInsets.only(left: Shape.s(10)),
      child: Chip(
        key: ValueKey(key),
        label: word,
        onTap: does,
        look: ChipLook.word,
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: InspectorSkin.gap),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              key: const ValueKey('add-effect'),
              onTap: doc.actions.onAddEffect,
              builder: (_, h) => Container(
                height: InspectorSkin.cell,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: h ? Grey.g20 : InspectorSkin.well,
                  borderRadius: BorderRadius.all(Shape.r(6)),
                ),
                child: Text(
                  '+ Add Effect',
                  style: TextStyles.label(h ? Grey.g95 : Grey.g76),
                ),
              ),
            ),
          ),
          // Copy and paste the whole effect stack with its parameters, as Alight Motion's Copy Effects and Paste Effects do.
          if (doc.layer.movable.isNotEmpty)
            if (doc.actions.onCardCopy case final copy?)
              word('effects-copy', 'Copy all', () => copy(names)),
          if (doc.actions.onCardPaste case final paste?)
            word('effects-paste', 'Paste', paste),
          if (doc.layer.moreCards.isNotEmpty &&
              doc.actions.onMoreCard != null) ...[
            // As in Alight Motion, only the cards for the layer's kind show by default. The rest are listed by name here.
            SizedBox(width: Shape.s(10)),
            CardMore(
              name: 'More',
              word: 'More',
              items: [
                for (final title in doc.layer.moreCards)
                  (title, title, () => doc.actions.onMoreCard!(title)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The Inspector: one scrolling stack of the app's cards. Needs an InspectorHost above it.
class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key, required this.width, required this.height});
  final double width, height;
  @override
  State<InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel> {
  final _node = FocusNode(debugLabel: 'inspector');
  final _scroll = ScrollController();

  @override
  void dispose() {
    _node.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = InspectorScope.of(context).doc, k = doc.kind;
    final body = <Widget>[
      if (k == Kind.none)
        const EmptyState()
      else ...[
        // One stack: Transform first, then the layer's effects, then the other cards. Premiere Pro's Effect Controls lists effects under Motion and Opacity the same way.
        // Every titled card folds on its own.
        for (final (i, c) in doc.cards.indexed) ...[
          if (doc.actions.onAddEffect != null && i == _addAt(doc))
            const AddEffectRow(),
          ValuesCard(c),
        ],
        if (doc.actions.onAddEffect != null && _addAt(doc) >= doc.cards.length)
          const AddEffectRow(),
      ],
    ];
    final panel = Focus(
      focusNode: _node,
      child: TapRegion(
        onTapInside: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_node.hasFocus) _node.requestFocus();
        }),
        child: Container(
          width: widget.width,
          height: widget.height,
          color: Grey.g07,
          // Only the cards in view are built, so seventy effects cost no more than seven.
          // A newly placed text layer waits for its card, which is out of view under Transform.
          // The cache extent below builds it anyway, and its box then scrolls itself to the caret.
          child: Column(
            children: [
              // The name and Animate button stay put while the cards scroll under them.
              // Alight Motion's keyframe button also sits outside the scrolling area (LayerTools.kt, LayerPanel).
              if (k != Kind.none)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    InspectorSkin.gap,
                    InspectorSkin.gap,
                    InspectorSkin.gap,
                    0,
                  ),
                  child: const InspectorHeader(),
                ),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.all(InspectorSkin.gap),
                  scrollCacheExtent: textToType
                      ? const ScrollCacheExtent.pixels(4000)
                      : null,
                  children: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final floated = Overlay.maybeOf(context) == null
        ? Overlay.wrap(child: panel)
        : panel;
    return floated;
  }
}
