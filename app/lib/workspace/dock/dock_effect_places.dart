// Where the Effects shelf looks: a list of its own beside or over the tiles, in the shape of the Media shelf's tree
// (dock_files_browser.dart), as Ableton's browser sidebar lists its Collections, Final Cut's Effects browser its
// categories, Spotify its Library, Premiere its bins: a press on a row shows what it holds among the tiles, and the
// search and the kinds narrow within it. A bundle is never a chip beside the kinds. Over the tiles, where the shelf is
// narrow, it folds to the row that says where it looks: a press on a row gives the shelf to what it holds, and the row
// brings the list back, as Alight Motion's browser goes from its categories to one's effects and back (EffectBrowser.kt:
// 105, 197, 247).
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../parts/text_gestures.dart' show TextGestures;
import '../../style/tokens.dart';
import 'dock_glyphs.dart';
import 'dock_parts.dart';
import '../shelf/effect_decks.dart';
import '../ws.dart';
import '../ws_menu.dart';

const dockFxListHeight = 176.0;

/// Which effect a tile being carried is: told by what two presses on it do, which is what the stage takes (DockHover's
/// Draggable). Dropped on a deck it goes in, as a track on a Spotify playlist, an effect in a Premiere bin.
final carriedEffect = Expando<String>();

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
  final bool narrow; // (over the tiles, not beside them)
  final Map<String, int> counts; // (All, Recent, ★, In video: how many of what is found each holds)
  final Map<String, int> packs;
  final Map<EffectDeck, int> decks;
  final void Function(EffectDeck, String id) put;
  final Set<String> known; // (all the shelf can tell: what a deck pasted in is settled against)
  final bool mapped; // (the shelf a map: the map all of it, the deck picked kept open under its row to make)
  final List<Widget> held; // (what the open deck holds, on the map: under its row)
  final Map<String, Widget> covers; // (a deck's picture: its first four, Spotify's playlist cover)
  @override
  State<EffectPlaces> createState() => EffectPlacesState();
}

class EffectPlacesState extends State<EffectPlaces> {
  final _menu = GlobalKey<WsMenuState>();
  EffectDeck? _naming; // (the deck whose name, or search, is being written in its row, as a Finder folder's)
  bool _search = false, _folded = false; // (folded: as it was before the row was needed)
  List<String>? _saving; // (the Favorites going into the deck being named: emptied once it is named, as Lightroom's Save)
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus()); // (its field is there from the next frame)
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

  /// A new deck, its name at once to write, as a new bin in Premiere or a new folder in Finder: [thing] in it (the list
  /// of decks on an effect ends in one, as YouTube's Save and Spotify's Add to Playlist), or the [words] saved, so that
  /// what comes later comes in too (Lightroom's Create Smart Collection, Ableton's Add Label); from the +, it opens.
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

  /// A deck's line, copied from wherever it was found: taken in, what this machine lacks kept and marked, as Hearthstone
  /// reads a deck code as a new deck is begun.
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

  void _open(Offset at, List<WsMenuItem> items) {
    final box = _menu.currentContext?.findRenderObject() as RenderBox?;
    _menu.currentState?.show(box?.globalToLocal(at) ?? Offset.zero, items);
  }

  /// The + at the head of the decks, a menu as Spotify's Create and Lightroom's Collections +.
  void _plus(BuildContext at) {
    final q = widget.c.query.trim();
    _open((at.findRenderObject() as RenderBox).localToGlobal(Offset.zero), [
      WsMenuItem('New Deck', newDeck),
      if (q.isNotEmpty) WsMenuItem('New Deck from “$q”', () => newDeck(words: q)),
      WsMenuItem('Paste Deck Code', _paste),
    ]);
  }

  /// Where an effect's right click puts it, set on the row's own right click and set again to go back to the Favorites,
  /// as Lightroom Classic's Set as Target Collection (on the Quick Collection too) and its unchecking.
  WsMenuItem _aim(EffectDeck? d) =>
      WsMenuItem('Set as Target Deck', () => widget.c.set(() => effectTargetSet(d?.target == true ? null : d)), keys: effectTarget() == d ? '✓' : '');

  /// The Favorites' own right click, as Lightroom Classic's on the Quick Collection: Set as Target Collection, Save Quick
  /// Collection… and Clear Quick Collection (Adobe's Work with photo collections; Thomas Fitzgerald's Quick Lightroom Tip:
  /// Clear Quick Collection, 2016). Saved, the starred become a deck, its name at once to write and the deck open, as New
  /// Deck's from the +; named, the Favorites are emptied for the next lot, as Lightroom's Clear Quick Collection After
  /// Saving is on until unchecked (a deck here is named in its row, with no dialog to uncheck it in); Escape is the
  /// dialog's Cancel, no deck and the Favorites as they were. The whole of the Favorites, whatever is searched, as
  /// Lightroom's from a filtered view. Only this shelf's effects: the Fonts shelf's stars are kept in the same file.
  void _favoritesMenu(Offset at) {
    final c = widget.c,
        held = [
          for (final id in c.mem.starred)
            if (widget.known.contains(id)) id,
        ];
    _open(at, [
      _aim(null),
      const WsMenuItem.rule(),
      WsMenuItem(
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
      WsMenuItem('Clear Favorites', held.isEmpty ? null : () => c.unstar(held)),
    ]);
  }

  /// What is done to a deck is on its row, by a right click, as Ableton's label (Rename, the colour) and Lightroom's
  /// Edit Smart Collection.
  void _deckMenu(EffectDeck d, Offset at) {
    final c = widget.c;
    _open(at, [
      _aim(d),
      const WsMenuItem.rule(),
      WsMenuItem('Rename…', () => naming(d)),
      WsMenuItem('Edit Search…', () => naming(d, search: true)),
      WsMenuItem('Copy Deck Code', () {
        Clipboard.setData(ClipboardData(text: deckCode(d)));
        c.ws.notice = 'Copied ${d.name}: Paste Deck Code on the + brings it back';
      }),
      const WsMenuItem.rule(),
      WsMenuItem(
        'Delete',
        () => c.set(() {
          effectDecks().remove(d);
          effectDecksKeep();
        }),
      ),
    ]);
  }

  // (in its row, as dock_program.dart's name on a tile)
  Widget _field(EffectDeck d) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        if (_saving != null) {
          // (Save Favorites… let go: the dialog's Cancel)
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

  /// What a row says: its name, its mark, how many.
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
      ), // (one that finds by words its own mark, as Lightroom's smart collection beside a plain one)
      _ when place.startsWith('/') => (place.substring(1), DockG.folder, widget.packs[place.substring(1)]),
      _ => ('All Effects', DockG.effects, p['All']),
    };
  }

  /// One row: the Media shelf's folder row (_FolderRow), a press shows what it holds.
  /// [cover]: a deck's picture, its row as Spotify's library lists a playlist (its cover, its name, how many under it).
  Widget _row(String place, {int depth = 0, bool? open, VoidCallback? onTap, ValueChanged<Offset>? menu, Widget? field, bool lit = false, Widget? cover}) {
    final c = widget.c, here = c.mem.fxPlace == place || lit, to = effectTarget();
    final (name, g, n) = _said(place);
    final aim = place == (to == null ? '★' : '@${to.name}');
    // (the target's mark, Lightroom's + after its name, kept when a long name is cut short)
    Widget named(TextStyle s) => Row(
      children: [
        Flexible(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: s),
        ),
        if (aim) Text(' +', key: const ValueKey('ws-fx-target'), style: s),
      ],
    );
    return GestureDetector(
      onSecondaryTapDown: menu == null ? null : (d) => menu(d.globalPosition),
      child: DockHover(
        key: ValueKey('ws-fx-place-$place'),
        onTap: onTap ?? () => c.set(() => (c.mem.fxPlace = place, c.mem.fxListOpen = false)),
        builder: (context, h) => AnimatedContainer(
          duration: Mo.dur,
          curve: Mo.ease,
          height: Shape.z(cover == null ? 22 : 34),
          padding: EdgeInsets.only(left: Shape.s(4) + depth * Shape.s(12.0), right: WsT.inset),
          color: dockFill(here, h),
          child: Row(
            children: [
              SizedBox(
                width: Shape.z(14),
                height: Shape.z(22),
                child: open == null
                    ? null
                    : AnimatedRotation(
                        turns: open ? .25 : 0,
                        duration: Mo.dur,
                        curve: Mo.ease,
                        child: DockGlyph(DockG.chevron, size: Shape.z(7), color: dockInk(here, Grey.g63)),
                      ),
              ),
              if (cover != null)
                SizedBox.square(dimension: Shape.z(28), child: cover)
              else
                DockGlyph(g, size: Shape.z(12), color: here ? WsT.onAccent : Grey.g63),
              SizedBox(width: Shape.s(6)),
              Expanded(
                child:
                    field ??
                    (cover == null
                        ? named(T.name(dockInk(here)).copyWith(fontWeight: here ? FontWeight.w600 : FontWeight.w400))
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              named(T.name(dockInk(here)).copyWith(fontWeight: here ? FontWeight.w600 : FontWeight.w400)),
                              Text(
                                '${g == DockG.search ? 'By words · ' : ''}${n ?? 0} ${n == 1 ? 'effect' : 'effects'}',
                                maxLines: 1,
                                style: T.micro(dockInk(here, Grey.g56)),
                              ),
                            ],
                          )),
              ),
              if (n != null && cover == null) Text('$n', style: T.value(dockInk(here, Grey.g56)).copyWith(fontSize: T.px(10))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deck(EffectDeck d) => _into(
    d,
    (over) => _row('@${d.name}', field: _naming == d ? _field(d) : null, lit: over, menu: (at) => _deckMenu(d, at), cover: widget.covers['@${d.name}']),
  );

  /// A tile carried onto [d] goes in it; onto the Favorites ([d] null) it is starred, as a track dropped on a Spotify
  /// playlist or on its Liked Songs.
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

  /// What the open deck holds, under its row, on the map: Hearthstone's deck list beside its collection, an effect
  /// carried onto it put in; said how while it holds none.
  Widget _held(EffectDeck? d) => _into(
    d,
    (over) => ColoredBox(
      color: over ? WsT.card : WsT.body,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: widget.held.isNotEmpty
            ? widget.held
            : [
                Padding(
                  padding: EdgeInsets.fromLTRB(Shape.s(4) + Shape.z(14), Shape.s(4), WsT.inset, Shape.s(6)),
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
    return WsMenu(
      key: _menu,
      child: ColoredBox(
        color: WsT.body,
        child: widget.narrow && !c.mem.fxListOpen && widget.mapped && (deck != null || c.mem.fxPlace == '★')
            ? Column(
                // (folded to the deck on the map, what it holds under it, as the browser goes into a category and back)
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
                // (a tile carried over it opens the list, for a deck to drop it on: Finder's spring-loaded folders)
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
                      builder: (b) => DockIconButton(DockG.plus, key: const ValueKey('ws-fx-deck-new'), onTap: () => _plus(b)),
                    ),
                  ),
                  for (final d in widget.decks.keys) ...[_deck(d), if (widget.mapped && c.mem.fxPlace == '@${d.name}') _held(d)],
                  _row('Packs', open: open, onTap: () => c.toggle(c.mem.open, 'fx:packs')), // (what the makers bundled, as Ableton's Packs, folded)
                  if (open)
                    for (final p in widget.packs.keys) _row('/$p', depth: 1),
                ],
              ),
      ),
    );
  }
}
