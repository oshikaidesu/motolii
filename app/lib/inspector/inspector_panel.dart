import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/widgets.dart';

import '../skin/tokens.dart';
import 'inspector_parts.dart';

// ---- 13. the whole panel ----------------------------------------------------------------------------------------------
// contract: one rule for every card. A card is what the inside declares (card_table.h, sent by motolii_cards and
// written as a WGSL uniform struct by workspace/inspector_feed/cards.dart), drawn by [ValuesCard] as an effect is: no card is named here.

// (under its effects, as Alight Motion's list ends: after the last card the host says is an effect (doc_cards_of lays
//  them before what it may do besides); none on it, at the end)
int _addAt(Doc doc) {
  final at = doc.cards.lastIndexWhere((c) => doc.movable.contains(c.name)) + 1;
  return at > 0 ? at : doc.cards.length;
}

/// Alight Motion's Add Effect, under a thing's effects: the shelf of them, ready to be searched.
class AddEffectRow extends StatelessWidget {
  const AddEffectRow({super.key});
  @override
  Widget build(BuildContext context) {
    final doc = Ctx.of(context).doc;
    final names = [
      'fx',
      'fx_off',
      for (final c in doc.cards)
        if (doc.movable.contains(c.name))
          for (final p in c.params) p.id,
    ];
    Widget word(String key, String word, VoidCallback? does) => Hov(
      key: ValueKey(key),
      onTap: does,
      builder: (_, h) => Padding(
        padding: EdgeInsets.only(left: Shape.s(10)),
        child: Text(word, style: T.label(h ? Grey.g95 : Grey.g56)),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: Pop.gap),
      child: Row(
        children: [
          Expanded(
            child: Hov(
              key: const ValueKey('add-effect'),
              onTap: doc.onAddEffect,
              builder: (_, h) => Container(
                height: Pop.cell,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: h ? Grey.g20 : Pop.well, borderRadius: BorderRadius.all(Shape.r(6))),
                child: Text('+ Add Effect', style: T.label(h ? Grey.g95 : Grey.g76)),
              ),
            ),
          ),
          // (Alight Motion's Copy Effects and Paste Effects: its whole stack, the knobs with it)
          if (doc.movable.isNotEmpty)
            if (doc.onCardCopy case final copy?) word('effects-copy', 'Copy all', () => copy(names)),
          if (doc.onCardPaste case final paste?) word('effects-paste', 'Paste', paste),
          if (doc.moreCards.isNotEmpty && doc.onMoreCard != null) ...[
            // (what Alight Motion shows for its kind is all that is there unasked: the rest by name)
            SizedBox(width: Shape.s(10)),
            CardMore(name: 'More', word: 'More', items: [for (final title in doc.moreCards) (title, title, () => doc.onMoreCard!(title))]),
          ],
        ],
      ),
    );
  }
}

/// The Inspector: one scrolling stack of the host's cards. Needs an InspHost above it.
class InspectorPanel extends StatefulWidget {
  const InspectorPanel({super.key, this.width = 372, this.height = 720});
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
    final doc = Ctx.of(context).doc, k = doc.kind;
    final body = <Widget>[
      if (k == Kind.none)
        const EmptyState()
      else ...[
        // contract: one stack: the host's cards, Transform first, then the effects on it, then what it may do besides (Premiere Pro's Effect Controls: the effects put on under Motion and Opacity); every titled card folds on its own.
        for (final (i, c) in doc.cards.indexed) ...[if (doc.onAddEffect != null && i == _addAt(doc)) const AddEffectRow(), ValuesCard(c)],
        if (doc.onAddEffect != null && _addAt(doc) >= doc.cards.length) const AddEffectRow(),
      ],
    ];
    final panel = Focus(
      focusNode: _node,
      child: Listener(
        onPointerDown: (_) => WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_node.hasFocus) _node.requestFocus();
        }),
        child: Container(
          width: widget.width,
          height: widget.height,
          color: Grey.g07,
          // (only the cards in sight are built: a stage with seventy effects on it builds as one with seven; a text just
          //  placed waits for its card, out of sight under Transform: built for it, the box then scrolls itself to the caret)
          child: Column(
            children: [
              // (the name and Animate all stay where they are, the cards going by under them: Alight Motion's key button stands in the panel's frame, outside what scrolls, LayerTools.kt LayerPanel)
              if (k != Kind.none) Padding(padding: EdgeInsets.fromLTRB(Pop.gap, Pop.gap, Pop.gap, 0), child: const InspHeader()),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: EdgeInsets.all(Pop.gap),
                  scrollCacheExtent: textToType ? const ScrollCacheExtent.pixels(4000) : null,
                  children: body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final floated = Overlay.maybeOf(context) == null ? Overlay.wrap(child: panel) : panel;
    return Pop(child: floated);
  }
}
