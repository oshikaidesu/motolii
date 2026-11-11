// The effects the shelf lists, as entries. A layer effect, a whole-screen effect, a saved look and the empty effect are told apart only
// here (what a press does, how the tile reads); everything after this treats them alike. The entries for what a deck holds and this
// machine does not have are effectLost.
import 'package:motolii/workspace/dock/effects/effect_commands.dart';
import 'package:motolii/workspace/dock/effects/effect_catalog.dart';
import 'package:motolii/workspace/shelf/shelf_looks.dart';
import 'package:motolii/workspace/shelf/effect_tiles_review.dart';
import 'package:flutter/widgets.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/controls.dart' show Chip, ChipLook;
import 'package:motolii/widgets/media.dart' show Draw;
import 'package:motolii/workspace/dock/common/star_button.dart';
import 'package:motolii/workspace/dock/effects/effect_drawings.dart';
import 'package:motolii/workspace/dock/effects/effects_controller.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/workspace/shelf/empty_effect.dart';
import 'package:motolii/workspace/shelf/shelf_add.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/shelf_tile.dart';
import 'package:motolii/workspace/state/effects.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';

/// The shelf's effects as entries, and what the engine said about each of them by id: a layer effect by its name, a file effect by its file.
class EffectEntries {
  const EffectEntries(this.every, this.seen);
  final List<EffectEntry> every;
  final Map<String, ShelfItem> seen;
}

/// Builds the entries. [tagging] and [renaming] name the tile whose own field is open; [tagged] and [renamed] take what was typed there.
EffectEntries effectEntries({
  required ShelfContext c,
  required EffectsController effects,
  required EffectCommands commands,
  required String? tagging,
  required String? renaming,
  required void Function(String id, String? to) tagged,
  required void Function(String file, String was, String? to) renamed,
}) {
  final ws = c.ws, m = ws.inside!;
  final on = ws.fxOf(ws.selected),
      screen = ws.screenFx,
      picked = int.tryParse(ws.selected ?? '') != null;
  final look = shelfLooks['Effects']!;
  // Overlays on a tile's image, none on a small tile.
  // ON, with its place among the stage's effects, when applied; the reason the sample looks unchanged (FOR SOUND, UNSUPPORTED ...);
  // and the star when starred or hovered.
  List<Widget> Function(bool) marks(
    String id,
    bool small, {
    String? on,
    String? same,
  }) =>
      (h) => [
        if (on != null && !small)
          Positioned(
            left: 3,
            top: 3,
            child: Chip(
              label: on,
              look: ChipLook.tag(WindowTokens.accent, edge: true),
            ),
          ),
        if (same != null && !small)
          Positioned(
            left: 3,
            bottom: 3,
            child: Chip(label: same, look: ChipLook.tag(Grey.g63, edge: true)),
          ), // Shows why the sample is unchanged: what it lacks, or that the engine does not draw it yet.
        if (!small && (c.starred(id) || h))
          Positioned(
            right: 0,
            top: 0,
            child: StarButton(
              key: ValueKey('ws-star-$id'),
              on: c.starred(id),
              onTap: () => c.star(id),
            ),
          ),
      ];
  // What the engine said about each effect, by id: a layer effect by its name, a file effect by its file.
  final seen = <String, ShelfItem>{};
  // Builds one item for any of the three listings; only what really differs by listing is switched on its [from].
  EffectEntry fx(String name, ShelfItem i) {
    final thing = i.from == 'thing',
        screened = i.from == 'screen',
        id = thing ? i.name : i.id;
    final lit = thing ? on.contains(id) : screened && screen.contains(id);
    final apply = commands.chosen(
      id,
      thing
          ? () => ws.fxToggle(id)
          : (screened ? () => ws.screenPut(id) : () => ws.lookPut(id)),
      taken: thing && lit,
    );
    seen[id] = i;
    return (
      id: id,
      name: name,
      label: thing || screened ? i.label : 'Look',
      on: lit,
      apply: apply,
      said: thing
          ? _said(ws, id)
          : !screened
          ? (picked ? 'A look for the picked thing' : 'A look, on a new board')
          : i.same && TileReview.stopped(id).isNotEmpty
          ? 'Stops here: ${TileReview.stopped(id)}'
          : i.same && TileReview.lacks(id).isNotEmpty
          ? 'Needs: ${TileReview.lacks(id)}'
          : i.about.isEmpty
          ? (picked ? 'On the picked thing' : 'On all under it')
          : i.about,
      tile: (small, menu) => ShelfTile(
        ShelfItem(id, name, picture: i.picture),
        look,
        key: small || thing
            ? null
            : ValueKey(screened ? 'ws-screen-$id' : 'ws-look-$name'),
        small: small,
        art: thing && i.picture.isEmpty
            ? paintedArt(Draw((c, _) => drawEffectLook(c, name), name))
            : null, // Without an image, its small drawing.
        picked: c.sel == id,
        lit: lit,
        onTap: () => c.pick(id),
        onApply: apply,
        onMenu: menu,
        onHover: screened ? (h) => ws.tryOn(h ? id : null) : null, // Shows what it does on the selected layer meanwhile (WorkspaceController.tryOn).
        naming: tagging == id
            ? ShelfNameField(
                effects.tags.ownOf('Effects', id).join(' '),
                (to) => tagged(id, to),
              )
            : screened && renaming == id
            ? ShelfNameField(name, (to) => renamed(id, name, to))
            : null,
        over: marks(
          id,
          small,
          on: !lit ? null : (screened ? 'ON ${screen.indexOf(id) + 1}' : 'ON'),
          same: screened && i.same ? TileReview.sameTag(id) : null,
        ),
      ),
    );
  }

  // File effects sorted by name. One the user added and renamed shows the name written beside it (shelf_add.dart).
  final screens = m.items('screen');
  final lined = <(String, ShelfItem)>[
    for (final i in m.items('thing')) (i.name, i),
    ...(effects.byName[screens] ??= ([
      for (final i in screens) (shelfNamed(i.id) ?? i.name, i),
    ]..sort((a, b) => a.$1.toLowerCase().compareTo(b.$1.toLowerCase())))),
    // A saved preset by its name (Save Look). Applying it gives the selected layer its values, effects and keyframes.
    for (final (_, f) in m.presets)
      if (m.item(f) case final i?) (i.name, i),
  ];
  final every = <EffectEntry>[
    // First comes an empty effect. Its code opens on its card, ready for an ISF effect to be pasted in (empty_effect.dart).
    (
      id: 'empty:effect',
      name: 'Empty',
      label: '',
      on: false,
      apply: commands.chosen(
        'empty:effect',
        () => emptyPut(
          ws,
          expression: false,
          told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why',
        ),
      ),
      said: picked
          ? 'An empty effect on the picked thing: paste ISF code into its card'
          : 'An empty effect, on a new board: paste ISF code into its card',
      tile: (small, menu) => ShelfTile(
        ShelfItem('empty:effect', 'Empty'),
        look,
        small: small,
        art: paintedArt(const EmptyLook()),
        picked: c.sel == 'empty:effect',
        onTap: () => c.pick('empty:effect'),
        onApply: commands.chosen(
          'empty:effect',
          () => emptyPut(
            ws,
            expression: false,
            told: (why) => why.isEmpty ? null : ws.notice = 'Not taken: $why',
          ),
        ),
        onMenu: menu,
      ),
    ),
    for (final (n, i) in lined) fx(n, i),
    // There are no motions here: they are expressions, in Create's Expression group.
  ];
  return EffectEntries(every, seen);
}

/// The entries for what a deck holds and this machine does not have: marked NOT HERE, and a press takes them out of the deck.
List<EffectEntry> effectLost({
  required ShelfContext c,
  required EffectDeck? deck,
  required Set<String> known,
}) {
  final look = shelfLooks['Effects']!;
  return <EffectEntry>[
    if (deck != null && c.query.isEmpty)
      for (final t in deck.things)
        if (!known.contains(t.id))
          (
            id: t.id,
            name: t.name,
            label: 'Not here',
            on: true,
            said: 'Not on this machine',
            apply: () => c.set(() {
              deck.things.remove(t);
              effectDecksKeep();
            }),
            tile: (small, menu) => ShelfTile(
              ShelfItem(t.id, t.name),
              look,
              picked: c.sel == t.id,
              onTap: () => c.pick(t.id),
              onMenu: menu,
              over: (_) => [
                Positioned(
                  left: 3,
                  bottom: 3,
                  child: Chip(
                    label: 'NOT HERE',
                    look: ChipLook.tag(Grey.g63, edge: true),
                  ),
                ),
              ],
            ),
          ),
  ];
}

/// The description of a layer effect: the document's value for it, and what the selected layer has for it now.
String _said(WorkspaceController ws, String name) {
  final m = ws.inside!,
      v = m.layerEffects.firstWhere((e) => e.$1 == name).$2,
      t = int.tryParse(
        ws.selected ?? '',
      ); // The selected layer's id, or null when none is selected.
  final now = t == null ? '' : m.word(t, v);
  return now.isEmpty ? '$v · none on it' : '$v · $now';
}
