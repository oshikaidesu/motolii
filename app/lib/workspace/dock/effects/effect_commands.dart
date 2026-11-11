// What the Effects shelf does when the user acts on an effect: applying it, putting it in a deck or among the favourites, and
// the items of its right-click menu. The shelf's state (which tile is being renamed) and its widgets stay in effects_shelf.dart;
// what the shelf lists is effect_catalog.dart.
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/workspace/dock/effects/effect_catalog.dart';
import 'package:motolii/workspace/dock/effects/effects_controller.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

class EffectCommands {
  const EffectCommands(this.c, this.effects);
  final ShelfContext c;

  /// What the shelf keeps between builds: the latched words, and which effect a dragged tile carries.
  final EffectsController effects;

  WorkspaceController get ws => c.ws;

  // A layer's own effects, presets and motions go on the selected layer, or on a new layer when none is selected.
  // Whole-screen effects go on the selected layer, or on the stage.
  // Applying while words are typed in the search box latches the effect to those words, so it comes first next time.
  VoidCallback chosen(String id, VoidCallback put, {bool taken = false}) {
    void go() {
      // A closure of its own rather than a tear-off, because a dragged tile is identified by it.
      effects.tags.latch('Effects', c.query, id);
      if (!taken) c.set(() => effectUsed(id, words: c.query, chip: c.chip));
      ws.tryOn(null); // Stop previewing the hovered effect first: applying reads the document as it is.
      put();
    }

    effects.carried[go] = id;
    return go;
  }

  // Effects are listed whatever is selected, as After Effects' Effects & Presets panel does.
  // With no layer selected, a layer effect goes on a new layer (WorkspaceController.fxToggle).
  // A screen effect on the stage is taken off by Remove, and a press adds another (WorkspaceController.screenPut).
  VoidCallback? off(EffectEntry e) =>
      ws.screenFx.contains(e.id) ? () => ws.screenToggle(e.id) : null;

  /// Puts the effect in the deck, or takes it out.
  void put(EffectListing l, EffectDeck d, EffectEntry e) => c.set(() {
    d.toggle(e.id, e.name, found: d.words.isNotEmpty && l.found(d.words, e));
    effectDecksKeep();
  });

  // Where one press sends an effect, however many decks exist: the target deck, else Favorites. A notice says where it went.
  // Lightroom Classic does the same with Add to Target Collection (B), using the Quick Collection until a target is set.
  EffectDeck? aim(EffectListing l) {
    final to = effectTarget();
    return to != null && l.deckIds.containsKey(to) ? to : null;
  }

  bool aimed(EffectListing l, EffectEntry e) {
    final to = aim(l);
    return to != null ? l.deckIds[to]!.contains(e.id) : c.starred(e.id);
  }

  void target(EffectListing l, EffectEntry e) {
    final to = aim(l), was = aimed(l, e);
    to != null ? put(l, to, e) : c.star(e.id);
    ws.notice =
        '${was ? 'Removed from' : 'Added to'} ${to?.name ?? 'Favorites'}';
  }

  // Actions on an effect are in its right-click menu and the footer's three-dot button, as in Ableton's item menu.
  // [tags] and [rename] open the tile's own field, and [newDeck] the list's name field; the shelf owns those.
  List<ContextMenuItem> menuItems(
    EffectListing l,
    EffectEntry e, {
    required VoidCallback tags,
    required VoidCallback rename,
    required void Function(DeckThing thing) newDeck,
  }) => [
    if (off(e) case final o?) ...[
      ContextMenuItem('Add Again', e.apply),
      ContextMenuItem('Remove', o),
    ] else
      ContextMenuItem(e.on ? 'Remove' : 'Add', e.apply),
    const ContextMenuItem.rule(),
    ContextMenuItem(
      '${aimed(l, e) ? 'Remove from' : 'Add to'} ${aim(l) == null ? 'Favorites' : 'Target Deck'}',
      () => target(l, e),
      keys: 'B',
    ),
    ContextMenuItem(
      'New Deck…',
      () => newDeck(DeckThing(e.id, e.name, effectSum(e.id))),
    ),
    ContextMenuItem('Tags…', tags),
    if (shelfAdded(e.id)) ...[
      const ContextMenuItem.rule(),
      ContextMenuItem('Rename…', rename),
    ],
    if (effectPack(e.id) case final p? when l.packs.containsKey(p)) ...[
      const ContextMenuItem.rule(),
      ContextMenuItem(
        'Go to Pack: $p',
        () => c.set(() => c.mem.fxPlace = '/$p'),
      ),
    ],
  ];
}
