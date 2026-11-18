// The effects shelf's place list: All, Recent, Favorites, In This Video, user decks and packs.
// When narrow, folds to one row; tap to expand.
import 'package:motolii/workspace/dock/effects/effect_places_menus.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/context_menu.dart';
import 'package:motolii/widgets/controls.dart' show IconPress;
import 'package:motolii/widgets/text_gestures.dart' show TypedField;
import 'package:motolii/workspace/dock/common/folder_row.dart';
import 'package:motolii/workspace/dock/common/shelf_section.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

/// Default height when over the tiles. Double-click the grip to reset.
const defaultEffectListHeight = 176.0;

class EffectPlaces extends StatefulWidget {
  const EffectPlaces(
    this.c, {
    super.key,
    required this.narrow,
    required this.counts,
    required this.packs,
    required this.decks,
    required this.put,
    required this.known,
    required this.carried,
    this.mapped = false,
    this.held = const [],
    this.covers = const {},
  });
  final ShelfContext c;

  /// Whether the list is laid over the tiles rather than beside them.
  final bool narrow;

  /// How many results each of All, Recent, ★ and In video holds.
  final Map<String, int> counts;

  /// How many effects each pack holds.
  final Map<String, int> packs;

  /// How many effects each deck holds.
  final Map<EffectDeck, int> decks;

  /// Puts the effect with this id into the deck.
  final void Function(EffectDeck, String id) put;

  /// The ids of all effects the shelf knows. A pasted deck is checked against them.
  final Set<String> known;

  /// The effect id of each tile being dragged, by its drag data. A row takes a dropped tile through it.
  final Expando<String> carried;

  /// Whether the shelf shows the map. The whole map is shown, and the selected deck stays open under its row.
  final bool mapped;

  /// On the map, the effects the open deck holds, shown under its row.
  final List<Widget> held;

  /// A deck's cover picture made of its first four effects.
  final Map<String, Widget> covers;
  @override
  State<EffectPlaces> createState() => EffectPlacesState();
}

class EffectPlacesState extends State<EffectPlaces> {
  final _menu = GlobalKey<ContextMenuState>();
  // The deck whose name or search words is being edited inline.
  EffectDeck? _naming;
  // _folded: whether the list was folded before naming began, so it can fold again afterwards.
  bool _search = false, _folded = false;
  // Favorites to move into the deck once it is named. Cleared after naming.
  List<String>? _saving;
  // What is typed in the field right now, so the hint can show while it is empty.
  final _typed = ValueNotifier<String>('');

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void naming(EffectDeck d, {bool search = false}) {
    final now = search ? d.words : d.name, c = widget.c;
    _folded = !c.mem.fxListOpen;
    c.set(() => (_naming = d, _search = search, c.mem.fxListOpen = true));
    _typed.value = now;
  }

  /// Commits what the field said ([said] is null when Esc cancelled it).
  void _named(String? said) {
    final d = _naming, c = widget.c;
    if (d == null || !mounted) return;
    if (said == null && _saving != null) {
      // Escape during Save Favorites… cancels it.
      c.set(() => (effectDecks().remove(d), c.mem.fxPlace = '★'));
      _saving = null;
    }
    final now = (said ?? (_search ? d.words : d.name)).trim();
    c.set(() {
      if (_search) {
        d.words = now;
      } else if (now.isNotEmpty && now != d.name) {
        final open = c.mem.fxPlace == '@${d.name}';
        d.name = deckName(now);
        if (open) c.mem.fxPlace = '@${d.name}';
      }
      effectDecksKeep();
      _naming = null;
      if (_folded) c.mem.fxListOpen = false;
    });
    if (_saving case final s?) c.unstar(s);
    _saving = null;
  }

  /// Adds a new deck and starts editing its name at once.
  /// [words] is saved as the deck's search, so matching effects join automatically.
  void newDeck({DeckThing? thing, String words = ''}) {
    final c = widget.c,
        d = EffectDeck(
          deckName(words.isEmpty ? 'Deck' : words),
          words: words,
          things: [?thing],
        );
    c.set(() {
      effectDecks().add(d);
      effectDecksKeep();
      if (thing == null) c.mem.fxPlace = '@${d.name}';
    });
    if (words.isNotEmpty) c.clearSearch();
    naming(d);
  }

  void _open(Offset at, List<ContextMenuItem> items) {
    final box = _menu.currentContext?.findRenderObject() as RenderBox?;
    _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, items);
  }

  /// The menus' items. This list owns the naming field.
  late final menus = EffectPlacesMenus(
    c: widget.c,
    known: widget.known,
    put: widget.put,
    naming: naming,
    newDeck: newDeck,
    saving: (held) => _saving = held,
  );

  void _openFavorites(Offset at) => _open(at, menus.favorites());

  /// The + at the head of the decks.
  void _plus(BuildContext at) => _open(
    (at.findRenderObject() as RenderBox).localToGlobal(Offset.zero),
    menus.plus(),
  );

  // Inline name field for a deck row.
  Widget _field(EffectDeck d) => Container(
    color: Grey.g91,
    padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
    alignment: Alignment.centerLeft,
    child: Stack(
      alignment: Alignment.centerLeft,
      children: [
        if (_search)
          ValueListenableBuilder(
            valueListenable: _typed,
            builder: (_, text, _) => text.isEmpty
                ? IgnorePointer(
                    child: Text(
                      'Search words, #tags',
                      maxLines: 1,
                      style: TextStyles.name(Grey.g56),
                    ),
                  )
                : const SizedBox(),
          ),
        // Return commits, Esc cancels (says null).
        TypedField(
          key: const ValueKey('ws-fx-naming'),
          text: _search ? d.words : d.name,
          style: TextStyles.name(Grey.g13),
          cursor: Grey.g13,
          backgroundCursor: Grey.g38,
          selection: Grey.g63,
          take: true,
          escapes: true,
          onPick: (v) => _typed.value = v.text,
          onDone: _named,
        ),
      ],
    ),
  );

  EffectDeck? _deckAt(String place) =>
      widget.decks.keys.where((d) => '@${d.name}' == place).firstOrNull;

  /// Name, glyph and count for a row.
  (String, AppGlyphs, int?) _said(String place) {
    final p = widget.counts, deck = _deckAt(place);
    return switch (place) {
      'Recent' => ('Recent', AppGlyphs.time, p[place]),
      '★' => ('Favorites', AppGlyphs.star, p[place]),
      'In video' => ('In This Video', AppGlyphs.video, p[place]),
      'Mine' => ('Mine', AppGlyphs.person, p[place]),
      'Packs' => ('Packs', AppGlyphs.folder, widget.packs.length),
      _ when deck != null => (
        deck.name,
        deck.words.isEmpty ? AppGlyphs.list : AppGlyphs.search,
        widget.decks[deck],
      ),
      _ when place.startsWith('/') => (
        place.substring(1),
        AppGlyphs.folder,
        widget.packs[place.substring(1)],
      ),
      _ => ('All Effects', AppGlyphs.effects, p['All']),
    };
  }

  /// One row. [cover] is a deck's picture.
  Widget _row(
    String place, {
    int depth = 0,
    bool? open,
    VoidCallback? onTap,
    ValueChanged<Offset>? menu,
    Widget? field,
    bool lit = false,
    Widget? cover,
  }) {
    final c = widget.c,
        here = c.mem.fxPlace == place || lit,
        to = effectTarget();
    final (name, g, n) = _said(place);
    final aim = place == (to == null ? '★' : '@${to.name}');
    // The target deck is marked with a + after its name.
    Widget named(TextStyle s) => Row(
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: s,
          ),
        ),
        if (aim) Text(' +', key: const ValueKey('ws-fx-target'), style: s),
      ],
    );
    return folderRow(
      key: ValueKey('ws-fx-place-$place'),
      here: here,
      glyph: g,
      name: named,
      depth: depth,
      open: open,
      count: n,
      cover: cover,
      field: field,
      sub:
          '${g == AppGlyphs.search ? 'By words · ' : ''}${n ?? 0} ${n == 1 ? 'effect' : 'effects'}',
      onMenu: menu,
      onTap:
          onTap ??
          () => c.set(() => (c.mem.fxPlace = place, c.mem.fxListOpen = false)),
    );
  }

  Widget _deck(EffectDeck d) => _into(
    d,
    (over) => _row(
      '@${d.name}',
      field: _naming == d ? _field(d) : null,
      lit: over,
      menu: (at) => _open(at, menus.deck(d)),
      cover: widget.covers['@${d.name}'],
    ),
  );

  /// Makes the row accept a dragged tile. Dropped on [d] → into that deck; on Favorites ([d] null) → starred.
  Widget _into(EffectDeck? d, Widget Function(bool over) row) =>
      DragTarget<VoidCallback>(
        onWillAcceptWithDetails: (o) => widget.carried[o.data] != null,
        onAcceptWithDetails: (o) {
          final id = widget.carried[o.data]!;
          d != null
              ? widget.put(d, id)
              : widget.c.starred(id)
              ? null
              : widget.c.star(id);
        },
        builder: (context, over, _) => row(over.isNotEmpty),
      );

  /// On the map, the open deck's effects shown under its row. Drop to add.
  Widget _held(EffectDeck? d) => _into(
    d,
    (over) => ColoredBox(
      color: over ? WindowTokens.card : WindowTokens.body,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.held.isNotEmpty
            ? widget.held
            : [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    Shape.s(4) + Shape.z(14),
                    Shape.s(4),
                    WindowTokens.inset,
                    Shape.s(6),
                  ),
                  child: Text(
                    effectTarget() == d
                        ? 'Drag an effect here from the map, or right-click one'
                        : 'Drag an effect here from the map',
                    style: TextStyles.label(Grey.g63),
                  ),
                ),
              ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.c,
        open = c.mem.open.contains('fx:packs'),
        deck = _deckAt(c.mem.fxPlace);
    return ContextMenu(
      key: _menu,
      child: ColoredBox(
        color: WindowTokens.body,
        child:
            widget.narrow &&
                !c.mem.fxListOpen &&
                widget.mapped &&
                (deck != null || c.mem.fxPlace == '★')
            ? Column(
                // Folded to the open deck on the map, with its effects below.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _into(
                    deck,
                    (over) => _row(
                      c.mem.fxPlace,
                      open: false,
                      lit: true,
                      onTap: () => c.set(() => c.mem.fxListOpen = true),
                      menu: (at) => deck == null
                          ? _openFavorites(at)
                          : _open(at, menus.deck(deck)),
                      cover: widget.covers[c.mem.fxPlace],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [_held(deck)],
                    ),
                  ),
                ],
              )
            : widget.narrow && !c.mem.fxListOpen
            ? DragTarget<VoidCallback>(
                // Dragging over it opens the list so the tile can drop on a deck.
                onWillAcceptWithDetails: (_) {
                  c.set(() => c.mem.fxListOpen = true);
                  return false;
                },
                builder: (context, _, _) => _row(
                  c.mem.fxPlace,
                  open: false,
                  lit: true,
                  onTap: () => c.set(() => c.mem.fxListOpen = true),
                  menu: deck != null
                      ? (at) => _open(at, menus.deck(deck))
                      : c.mem.fxPlace == '★'
                      ? (at) => _openFavorites(at)
                      : null,
                ),
              )
            : ListView(
                padding: EdgeInsets.symmetric(vertical: Shape.s(2)),
                children: [
                  _row('All'),
                  _row('Recent'),
                  _into(
                    null,
                    (over) =>
                        _row('★', lit: over, menu: (at) => _openFavorites(at)),
                  ),
                  if (widget.mapped && c.mem.fxPlace == '★') _held(null),
                  _row('In video'),
                  _row('Mine'),
                  ShelfSection(
                    'Decks',
                    trailing: Builder(
                      builder: (b) => IconPress(
                        dockMark(AppGlyphs.plus),
                        key: const ValueKey('ws-fx-deck-new'),
                        tip: 'New Deck',
                        onTap: () => _plus(b),
                      ),
                    ),
                  ),
                  for (final d in widget.decks.keys) ...[
                    _deck(d),
                    if (widget.mapped && c.mem.fxPlace == '@${d.name}')
                      _held(d),
                  ],
                  // The effects bundled by their authors, collapsed
                  _row(
                    'Packs',
                    open: open,
                    onTap: () => c.toggle(c.mem.open, 'fx:packs'),
                  ),
                  if (open)
                    for (final p in widget.packs.keys) _row('/$p', depth: 1),
                ],
              ),
      ),
    );
  }
}
