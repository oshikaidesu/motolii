// The list of places the Effects shelf can look in: All, Recent, Favorites, In This Video, user decks and packs.
// It sits beside or over the tiles and has the shape of the Media shelf's folder tree (dock_files_browser.dart).
// Ableton's browser sidebar lists its Collections this way, Final Cut's Effects browser its categories,
// Spotify its Library and Premiere its bins.
// Clicking a row shows what it holds among the tiles, and the search and the kinds narrow the result within it.
// A pack is never a chip beside the kinds.
// Over the tiles, where the shelf is narrow, the list folds to a single row that says where the shelf is looking.
// Clicking a place there gives the shelf to its contents, and clicking the row brings the list back.
// Alight Motion's browser moves between its categories and a category's effects in the same way (EffectBrowser.kt: 105, 197, 247).
import 'package:motolii/skin/window_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/widgets/text_gestures.dart' show TextGestures;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/workspace/dock/dock_folder_row.dart';
import 'package:motolii/workspace/dock/dock_widgets.dart';
import 'package:motolii/workspace/shelf/effect_decks.dart';
import 'package:motolii/widgets/menu.dart';
import 'package:motolii/workspace/shelf/shelf_context.dart';
import 'package:motolii/workspace/shelf/tile_colors.dart';

const dockFxListHeight = 176.0;

/// Maps the drag data of a tile being dragged (its double-click callback, which is what the canvas takes) to the effect id.
/// See DockHover's Draggable. Dropped on a deck, the effect goes into it, like a track on a Spotify playlist
/// or an effect in a Premiere bin.
final carriedEffect = Expando<String>();

/// The list of places the Effects shelf looks in. See the file header.
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
    this.mapped = false,
    this.held = const [],
    this.covers = const {},
  });
  final DockCtx c;

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

  /// Whether the shelf shows the map. The whole map is shown, and the selected deck stays open under its row.
  final bool mapped;

  /// On the map, the effects the open deck holds, shown under its row.
  final List<Widget> held;

  /// A deck's cover picture made of its first four effects, like a Spotify playlist cover.
  final Map<String, Widget> covers;
  @override
  State<EffectPlaces> createState() => EffectPlacesState();
}

class EffectPlacesState extends State<EffectPlaces> {
  final _menu = GlobalKey<ContextMenuState>();
  // The deck whose name, or search words, is being edited in its row, as with a Finder folder.
  EffectDeck? _naming;
  // _folded: whether the list was folded before naming began, so it can fold again afterwards.
  bool _search = false, _folded = false;
  // The Favorites going into the deck being named. They are cleared once it is named, as in Lightroom's Save.
  List<String>? _saving;
  final _words = TextEditingController();
  late final FocusNode _focus = FocusNode()..addListener(() => _focus.hasFocus ? null : _named());

  @override
  void dispose() {
    _focus.dispose();
    _words.dispose();
    super.dispose();
  }

  void naming(EffectDeck d, {bool search = false}) {
    final now = search ? d.words : d.name, c = widget.c;
    _folded = !c.mem.fxListOpen;
    c.set(() => (_naming = d, _search = search, c.mem.fxListOpen = true));
    _words
      ..text = now
      ..selection = TextSelection(baseOffset: 0, extentOffset: now.length);
    // The text field exists from the next frame on.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _named() {
    final d = _naming, c = widget.c, now = _words.text.trim();
    if (d == null || !mounted) return;
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

  /// Adds a new deck and starts editing its name at once, like a new bin in Premiere or a new folder in Finder.
  ///
  /// [thing] is put in the new deck. The list of decks on an effect ends in this entry, as with YouTube's Save
  /// and Spotify's Add to Playlist. [words] is saved as the deck's search, so effects that appear later join it too
  /// (Lightroom's Create Smart Collection, Ableton's Add Label). When made from the +, the new deck is opened.
  void newDeck({DeckThing? thing, String words = ''}) {
    final c = widget.c, d = EffectDeck(deckName(words.isEmpty ? 'Deck' : words), words: words, things: [?thing]);
    c.set(() {
      effectDecks().add(d);
      effectDecksKeep();
      if (thing == null) c.mem.fxPlace = '@${d.name}';
    });
    if (words.isNotEmpty) c.clearSearch();
    naming(d);
  }

  /// Adds a deck from a deck code copied from elsewhere. Effects this machine lacks are kept and marked,
  /// as Hearthstone does when it reads a deck code.
  Future<void> _paste() async {
    final c = widget.c, d = deckRead((await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '');
    if (d == null) {
      c.ws.notice = 'No deck code to paste';
      return;
    }
    deckSettle(d, widget.known);
    final away = d.things.where((t) => !widget.known.contains(t.id)).length;
    c.set(() {
      d.name = deckName(d.name);
      effectDecks().add(d);
      effectDecksKeep();
      c.mem.fxPlace = '@${d.name}';
    });
    c.ws.notice = away > 0 ? 'Added ${d.name}: $away not on this machine' : 'Added ${d.name}';
  }

  void _open(Offset at, List<ContextMenuItem> items) {
    final box = _menu.currentContext?.findRenderObject() as RenderBox?;
    _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, items);
  }

  /// The + at the head of the decks. It opens a menu, like Spotify's Create and Lightroom's Collections +.
  void _plus(BuildContext at) {
    final q = widget.c.query.trim();
    _open((at.findRenderObject() as RenderBox).localToGlobal(Offset.zero), [
      ContextMenuItem('New Deck', newDeck),
      if (q.isNotEmpty) ContextMenuItem('New Deck from “$q”', () => newDeck(words: q)),
      ContextMenuItem('Paste Deck Code', _paste),
    ]);
  }

  /// The menu item that sets the deck an effect's right-click adds to. It is on the row's own context menu.
  /// Choosing it again returns the target to the Favorites. Lightroom Classic has the same Set as Target Collection
  /// item, on the Quick Collection too, and unchecking it works the same way.
  ContextMenuItem _aim(EffectDeck? d) =>
      ContextMenuItem('Set as Target Deck', () => widget.c.set(() => effectTargetSet(d?.target == true ? null : d)), keys: effectTarget() == d ? '✓' : '');

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
  void _favoritesMenu(Offset at) {
    final c = widget.c,
        held = [
          for (final id in c.mem.starred)
            if (widget.known.contains(id)) id,
        ];
    _open(at, [
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
                  widget.put(d, id);
                }
                _saving = held;
                naming(d);
              },
      ),
      ContextMenuItem('Clear Favorites', held.isEmpty ? null : () => c.unstar(held)),
    ]);
  }

  /// The context menu of a deck row, like Ableton's label menu (Rename, color) and Lightroom's Edit Smart Collection.
  void _deckMenu(EffectDeck d, Offset at) {
    final c = widget.c;
    _open(at, [
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
    ]);
  }

  // The name field, edited inside the row as dock_program.dart does for a tile's name.
  Widget _field(EffectDeck d) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (_saving != null) {
          // Escape during Save Favorites… cancels it.
          widget.c.set(() => (effectDecks().remove(d), widget.c.mem.fxPlace = '★'));
          _saving = null;
        }
        _words.text = _search ? d.words : d.name;
        _focus.unfocus();
      },
    },
    child: Container(
      color: Grey.g91,
      padding: EdgeInsets.symmetric(horizontal: Shape.s(4)),
      alignment: Alignment.centerLeft,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          if (_search)
            ListenableBuilder(
              listenable: _words,
              builder: (_, _) =>
                  _words.text.isEmpty ? IgnorePointer(child: Text('Search words, #tags', maxLines: 1, style: T.name(Grey.g56))) : const SizedBox(),
            ),
          TextGestures(
            key: const ValueKey('ws-fx-naming'),
            field: (k) => EditableText(
              key: k,
              rendererIgnoresPointer: true,
              controller: _words,
              focusNode: _focus,
              style: T.name(Grey.g13),
              cursorColor: Grey.g13,
              backgroundCursorColor: Grey.g38,
              selectionColor: Grey.g63,
              maxLines: 1,
              onSubmitted: (_) => _focus.unfocus(),
            ),
          ),
        ],
      ),
    ),
  );

  EffectDeck? _deckAt(String place) => widget.decks.keys.where((d) => '@${d.name}' == place).firstOrNull;

  /// What a row shows: its name, its glyph and its count.
  (String, DockG, int?) _said(String place) {
    final p = widget.counts, deck = _deckAt(place);
    return switch (place) {
      'Recent' => ('Recent', DockG.time, p[place]),
      '★' => ('Favorites', DockG.star, p[place]),
      'In video' => ('In This Video', DockG.video, p[place]),
      'Packs' => ('Packs', DockG.folder, widget.packs.length),
      _ when deck != null => (
        deck.name,
        deck.words.isEmpty ? DockG.list : DockG.search,
        widget.decks[deck],
      ), // A deck that finds by search words has its own glyph, as Lightroom's smart collection differs from a plain one.
      _ when place.startsWith('/') => (place.substring(1), DockG.folder, widget.packs[place.substring(1)]),
      _ => ('All Effects', DockG.effects, p['All']),
    };
  }

  /// One row, built on the Media shelf's folder row (dockFolderRow). Clicking it shows what it holds.
  /// [cover] is a deck's picture; the row then looks like a playlist in Spotify's library
  /// (cover, name, and the count under it).
  Widget _row(String place, {int depth = 0, bool? open, VoidCallback? onTap, ValueChanged<Offset>? menu, Widget? field, bool lit = false, Widget? cover}) {
    final c = widget.c, here = c.mem.fxPlace == place || lit, to = effectTarget();
    final (name, g, n) = _said(place);
    final aim = place == (to == null ? '★' : '@${to.name}');
    // The target deck is marked with a + after its name, as in Lightroom. The + stays when a long name is cut short.
    Widget named(TextStyle s) => Row(
      children: [
        Flexible(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: s),
        ),
        if (aim) Text(' +', key: const ValueKey('ws-fx-target'), style: s),
      ],
    );
    return dockFolderRow(
      key: ValueKey('ws-fx-place-$place'),
      here: here,
      glyph: g,
      name: named,
      depth: depth,
      open: open,
      count: n,
      cover: cover,
      field: field,
      sub: '${g == DockG.search ? 'By words · ' : ''}${n ?? 0} ${n == 1 ? 'effect' : 'effects'}',
      onMenu: menu,
      onTap: onTap ?? () => c.set(() => (c.mem.fxPlace = place, c.mem.fxListOpen = false)),
    );
  }

  Widget _deck(EffectDeck d) => _into(
    d,
    (over) => _row('@${d.name}', field: _naming == d ? _field(d) : null, lit: over, menu: (at) => _deckMenu(d, at), cover: widget.covers['@${d.name}']),
  );

  /// Makes the row accept a dragged tile. Dropped on [d] it goes into that deck. Dropped on the Favorites ([d] null)
  /// it is starred, like a track dropped on a Spotify playlist or on Liked Songs.
  Widget _into(EffectDeck? d, Widget Function(bool over) row) => DragTarget<VoidCallback>(
    onWillAcceptWithDetails: (o) => carriedEffect[o.data] != null,
    onAcceptWithDetails: (o) {
      final id = carriedEffect[o.data]!;
      d != null
          ? widget.put(d, id)
          : widget.c.starred(id)
          ? null
          : widget.c.star(id);
    },
    builder: (context, over, _) => row(over.isNotEmpty),
  );

  /// On the map, the effects the open deck holds, shown under its row like Hearthstone's deck list beside its collection.
  /// A dragged effect dropped on it is added. While the deck is empty it shows how to add one.
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
                  padding: EdgeInsets.fromLTRB(Shape.s(4) + Shape.z(14), Shape.s(4), WindowTokens.inset, Shape.s(6)),
                  child: Text(
                    effectTarget() == d ? 'Drag an effect here from the map, or right-click one' : 'Drag an effect here from the map',
                    style: T.label(Grey.g63),
                  ),
                ),
              ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.c, open = c.mem.open.contains('fx:packs'), deck = _deckAt(c.mem.fxPlace);
    return ContextMenu(
      key: _menu,
      child: ColoredBox(
        color: WindowTokens.body,
        child: widget.narrow && !c.mem.fxListOpen && widget.mapped && (deck != null || c.mem.fxPlace == '★')
            ? Column(
                // Folded to the open deck on the map, with what it holds below, as the browser goes into a category and back.
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _into(
                    deck,
                    (over) => _row(
                      c.mem.fxPlace,
                      open: false,
                      lit: true,
                      onTap: () => c.set(() => c.mem.fxListOpen = true),
                      menu: (at) => deck == null ? _favoritesMenu(at) : _deckMenu(deck, at),
                      cover: widget.covers[c.mem.fxPlace],
                    ),
                  ),
                  Expanded(
                    child: ListView(padding: EdgeInsets.zero, children: [_held(deck)]),
                  ),
                ],
              )
            : widget.narrow && !c.mem.fxListOpen
            ? DragTarget<VoidCallback>(
                // A tile dragged over it opens the list so the tile can be dropped on a deck, like Finder's spring-loaded folders.
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
                      ? (at) => _deckMenu(deck, at)
                      : c.mem.fxPlace == '★'
                      ? (at) => _favoritesMenu(at)
                      : null,
                ),
              )
            : ListView(
                padding: EdgeInsets.symmetric(vertical: Shape.s(2)),
                children: [
                  _row('All'),
                  _row('Recent'),
                  _into(null, (over) => _row('★', lit: over, menu: (at) => _favoritesMenu(at))),
                  if (widget.mapped && c.mem.fxPlace == '★') _held(null),
                  _row('In video'),
                  DockSection(
                    'Decks',
                    trailing: Builder(
                      builder: (b) => IconPress(dockMark(DockG.plus), key: const ValueKey('ws-fx-deck-new'), onTap: () => _plus(b)),
                    ),
                  ),
                  for (final d in widget.decks.keys) ...[_deck(d), if (widget.mapped && c.mem.fxPlace == '@${d.name}') _held(d)],
                  // The effects bundled by their authors, collapsed, like Ableton's Packs.
                  _row('Packs', open: open, onTap: () => c.toggle(c.mem.open, 'fx:packs')),
                  if (open)
                    for (final p in widget.packs.keys) _row('/$p', depth: 1),
                ],
              ),
      ),
    );
  }
}
