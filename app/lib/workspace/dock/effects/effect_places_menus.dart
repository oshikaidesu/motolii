// The menus of the Effects shelf's list of places: the + at the head of the decks, the Favorites row and a deck row, and pasting a deck
// code. They are only lists of items; opening one, and the naming field of a row, are the list's own (effect_places.dart).
import 'package:flutter/services.dart';

import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';

class EffectPlacesMenus {
  const EffectPlacesMenus({
    required this.c,
    required this.known,
    required this.put,
    required this.naming,
    required this.newDeck,
    required this.saving,
  });
  final ShelfContext c;

  /// Every id the shelf knows now, to tell which effects of a pasted deck this machine lacks.
  final Set<String> known;

  /// Puts the effect with this id in the deck.
  final void Function(EffectDeck d, String id) put;

  /// Starts editing a deck's name, or its search words, in its row.
  final void Function(EffectDeck d, {bool search}) naming;

  /// Adds a new deck and starts editing its name.
  final void Function({DeckThing? thing, String words}) newDeck;

  /// Tells the list that the Favorites going into the deck being named are [held]; they are cleared once it is named.
  final void Function(List<String> held) saving;

  /// Adds a deck from a deck code copied from elsewhere. Effects this machine lacks are kept and marked,
  /// as Hearthstone does when it reads a deck code.
  Future<void> paste() async {
    final d = deckRead(
      (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '',
    );
    if (d == null) {
      c.ws.notice = 'No deck code to paste';
      return;
    }
    deckSettle(d, known);
    final away = d.things.where((t) => !known.contains(t.id)).length;
    c.set(() {
      d.name = deckName(d.name);
      effectDecks().add(d);
      effectDecksKeep();
      c.mem.fxPlace = '@${d.name}';
    });
    c.ws.notice = away > 0
        ? 'Added ${d.name}: $away not on this machine'
        : 'Added ${d.name}';
  }

  /// The + at the head of the decks. It opens a menu, like Spotify's Create and Lightroom's Collections +.
  List<ContextMenuItem> plus() {
    final q = c.query.trim();
    return [
      ContextMenuItem('New Deck', newDeck),
      if (q.isNotEmpty)
        ContextMenuItem('New Deck from “$q”', () => newDeck(words: q)),
      ContextMenuItem('Paste Deck Code', paste),
    ];
  }

  /// The menu item that sets the deck an effect's right-click adds to. It is on the row's own context menu.
  /// Choosing it again returns the target to the Favorites. Lightroom Classic has the same Set as Target Collection
  /// item, on the Quick Collection too, and unchecking it works the same way.
  ContextMenuItem _aim(EffectDeck? d) => ContextMenuItem(
    'Set as Target Deck',
    () => c.set(() => effectTargetSet(d?.target == true ? null : d)),
    keys: effectTarget() == d ? '✓' : '',
  );

  /// The context menu of the Favorites row, modeled on Lightroom Classic's menu on the Quick Collection:
  /// Set as Target Collection, Save Quick Collection… and Clear Quick Collection
  /// (Adobe's "Work with photo collections"; Thomas Fitzgerald's "Quick Lightroom Tip: Clear Quick Collection", 2016).
  ///
  /// Save turns the starred effects into a deck, opens it, and starts editing its name, as New Deck from the + does.
  /// Once the deck is named, the Favorites are emptied for the next batch, as Lightroom does while
  /// "Clear Quick Collection After Saving" is on. Here the name is edited in the row, so there is no dialog to turn that off.
  /// Escape cancels: no deck is made and the Favorites stay as they were.
  /// The whole Favorites list is saved, whatever is searched, as Lightroom does from a filtered view.
  /// Only this shelf's effects are used, because the Fonts shelf's stars are stored in the same file.
  List<ContextMenuItem> favorites() {
    final held = [
      for (final id in c.mem.starred)
        if (known.contains(id)) id,
    ];
    return [
      _aim(null),
      const ContextMenuItem.rule(),
      ContextMenuItem(
        'Save Favorites…',
        held.isEmpty
            ? null
            : () {
                final d = EffectDeck(deckName('Deck'));
                c.set(() {
                  effectDecks().add(d);
                  c.mem.fxPlace = '@${d.name}';
                });
                for (final id in held) {
                  put(d, id);
                }
                saving(held);
                naming(d);
              },
      ),
      ContextMenuItem(
        'Clear Favorites',
        held.isEmpty ? null : () => c.unstar(held),
      ),
    ];
  }

  /// The context menu of a deck row, like Ableton's label menu (Rename, color) and Lightroom's Edit Smart Collection.
  List<ContextMenuItem> deck(EffectDeck d) => [
    _aim(d),
    const ContextMenuItem.rule(),
    ContextMenuItem('Rename…', () => naming(d)),
    ContextMenuItem('Edit Search…', () => naming(d, search: true)),
    ContextMenuItem('Copy Deck Code', () {
      Clipboard.setData(ClipboardData(text: deckCode(d)));
      c.ws.notice = 'Copied ${d.name}: Paste Deck Code on the + brings it back';
    }),
    const ContextMenuItem.rule(),
    ContextMenuItem(
      'Delete',
      () => c.set(() {
        effectDecks().remove(d);
        effectDecksKeep();
      }),
    ),
  ];
}
