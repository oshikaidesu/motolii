// Where the Effects shelf looks: a list of its own beside or over the tiles, in the shape of the Media shelf's tree
// (dock_files_browser.dart), as Ableton's browser sidebar lists its Collections, Final Cut's Effects browser its
// categories, Spotify its Library, Premiere its bins: a press on a row shows what it holds among the tiles, and the
// search and the kinds narrow within it. A bundle is never a chip beside the kinds.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../sets/foundations/text_hand.dart' show TextHand;
import '../tokens.dart';
import 'dock_glyphs.dart';
import 'dock_parts.dart';
import 'effect_decks.dart';
import 'ws.dart';
import 'ws_menu.dart';

const dockFxListHeight = 176.0;

/// Which effect a tile being carried is: told by what two presses on it do, which is what the stage takes (DockHover's
/// Draggable). Dropped on a deck it goes in, as a track on a Spotify playlist, an effect in a Premiere bin.
final carriedEffect = Expando<String>();

class EffectPlaces extends StatefulWidget {
  const EffectPlaces(this.c, {super.key, required this.counts, required this.packs, required this.decks, required this.put, required this.known});
  final DockCtx c;
  final Map<String, int> counts;   // (All, Recent, ★, In video: how many of what is found each holds)
  final Map<String, int> packs;
  final Map<EffectDeck, int> decks;
  final void Function(EffectDeck, String id) put;
  final Set<String> known;   // (all the shelf can tell: what a deck pasted in is settled against)
  @override
  State<EffectPlaces> createState() => EffectPlacesState();
}

class EffectPlacesState extends State<EffectPlaces> {
  final _menu = GlobalKey<WsMenuState>();
  EffectDeck? _naming;   // (the deck whose name, or search, is being written in its row, as a Finder folder's)
  bool _search = false;
  final _words = TextEditingController();
  late final FocusNode _focus = FocusNode()..addListener(() => _focus.hasFocus ? null : _named());

  @override
  void dispose() {
    _focus.dispose();
    _words.dispose();
    super.dispose();
  }

  void naming(EffectDeck d, {bool search = false}) {
    final now = search ? d.words : d.name;
    setState(() => (_naming = d, _search = search));
    _words
      ..text = now
      ..selection = TextSelection(baseOffset: 0, extentOffset: now.length);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());   // (its field is there from the next frame)
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
    });
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

  /// What is done to a deck is on its row, by a right click, as Ableton's label (Rename, the colour) and Lightroom's
  /// Edit Smart Collection.
  void _deckMenu(EffectDeck d, Offset at) {
    final c = widget.c;
    _open(at, [
      WsMenuItem('Rename…', () => naming(d)),
      WsMenuItem('Edit Search…', () => naming(d, search: true)),
      WsMenuItem('Copy Deck Code', () {
        Clipboard.setData(ClipboardData(text: deckCode(d)));
        c.ws.notice = 'Copied ${d.name}: Paste Deck Code on the + brings it back';
      }),
      const WsMenuItem.rule(),
      WsMenuItem('Delete', () => c.set(() {
        effectDecks().remove(d);
        effectDecksKeep();
      })),
    ]);
  }

  // (in its row, as dock_program.dart's name on a tile)
  Widget _field(EffectDeck d) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
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
          if (_search) ListenableBuilder(listenable: _words, builder: (_, _) => _words.text.isEmpty ? IgnorePointer(child: Text('Search words, #tags', maxLines: 1, style: T.name(Grey.g56))) : const SizedBox()),
          TextHand(key: const ValueKey('ws-fx-naming'), field: (k) => EditableText(key: k, rendererIgnoresPointer: true, controller: _words, focusNode: _focus, style: T.name(Grey.g13), cursorColor: Grey.g13, backgroundCursorColor: Grey.g38, selectionColor: Grey.g63, maxLines: 1, onSubmitted: (_) => _focus.unfocus())),
        ],
      ),
    ),
  );

  /// One row: the Media shelf's folder row (_FolderRow), a press shows what it holds.
  Widget _row(String place, String name, DockG g, int? n, {int depth = 0, bool? open, VoidCallback? onTap, ValueChanged<Offset>? menu, Widget? field, bool lit = false}) {
    final c = widget.c, here = c.mem.fxPlace == place || lit;
    return GestureDetector(
      onSecondaryTapDown: menu == null ? null : (d) => menu(d.globalPosition),
      child: DockHover(
        key: ValueKey('ws-fx-place-$place'),
        onTap: onTap ?? () => c.set(() => c.mem.fxPlace = place),
        builder: (context, h) => AnimatedContainer(
          duration: Mo.dur,
          curve: Mo.ease,
          height: Shape.z(22),
          padding: EdgeInsets.only(left: Shape.s(4) + depth * Shape.s(12.0), right: WsT.inset),
          color: dockFill(here, h),
          child: Row(
            children: [
              SizedBox(
                width: Shape.z(14),
                height: Shape.z(22),
                child: open == null ? null : AnimatedRotation(turns: open ? .25 : 0, duration: Mo.dur, curve: Mo.ease, child: DockGlyph(DockG.chevron, size: Shape.z(7), color: dockInk(here, Grey.g63))),
              ),
              DockGlyph(g, size: Shape.z(12), color: here ? WsT.onAccent : Grey.g63),
              SizedBox(width: Shape.s(6)),
              Expanded(child: field ?? Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.name(dockInk(here)).copyWith(fontWeight: here ? FontWeight.w600 : FontWeight.w400))),
              if (n != null) Text('$n', style: T.value(dockInk(here, Grey.g56)).copyWith(fontSize: T.px(10))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _deck(EffectDeck d, int n) => DragTarget<VoidCallback>(
    onWillAcceptWithDetails: (o) => carriedEffect[o.data] != null,
    onAcceptWithDetails: (o) => widget.put(d, carriedEffect[o.data]!),
    builder: (context, over, _) => _row('@${d.name}', d.name, d.words.isEmpty ? DockG.list : DockG.search, n, field: _naming == d ? _field(d) : null, lit: over.isNotEmpty, menu: (at) => _deckMenu(d, at)),   // (one that finds by words its own mark, as Lightroom's smart collection beside a plain one)
  );

  @override
  Widget build(BuildContext context) {
    final c = widget.c, p = widget.counts, open = c.mem.open.contains('fx:packs');
    return WsMenu(
      key: _menu,
      child: ColoredBox(
        color: WsT.body,
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: Shape.s(2)),
          children: [
            _row('All', 'All Effects', DockG.effects, p['All']),
            _row('Recent', 'Recent', DockG.time, p['Recent']),
            _row('★', 'Favorites', DockG.star, p['★']),
            _row('In video', 'In This Video', DockG.video, p['In video']),
            DockSection('Decks', trailing: Builder(builder: (b) => DockIconButton(DockG.plus, key: const ValueKey('ws-fx-deck-new'), onTap: () => _plus(b)))),
            for (final e in widget.decks.entries) _deck(e.key, e.value),
            _row('Packs', 'Packs', DockG.folder, widget.packs.length, open: open, onTap: () => c.toggle(c.mem.open, 'fx:packs')),   // (what the makers bundled, as Ableton's Packs: 186 of them, folded)
            if (open)
              for (final e in widget.packs.entries) _row('/${e.key}', e.key, DockG.folder, e.value, depth: 1),
          ],
        ),
      ),
    );
  }
}
