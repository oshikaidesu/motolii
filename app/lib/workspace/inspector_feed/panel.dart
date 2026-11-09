// panel.dart: the inspector's panel in the window: what it listens to, and when it builds again or only tells the fields their numbers.
part of '../workspace.dart';

/// The Inspector of the lab, fed by the workspace's selection; its panel links open the dock's shelves or the tool panel.
class _InspectorPanel extends StatefulWidget {
  const _InspectorPanel();
  @override
  State<_InspectorPanel> createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<_InspectorPanel> {
  // (the inspector follows only what it shows: the document, what is picked, Animate, and the moment only while what is
  //  picked has keys; played, a thing with no keys shows the same numbers, so it is not built again each picture)
  Ws? _ws;
  Object? _seen;
  (int, bool)? _stageKeyed;
  bool _keyed(Ws ws) {
    final l = ws.layer;
    if (l != null) return l.keys.isNotEmpty;
    final m = ws.inside;
    if (m == null) return true;
    if (_stageKeyed?.$1 != ws.rev) _stageKeyed = (ws.rev, m.moving(0).any((n) => m.keyTimes(0, n).isNotEmpty)); // (the stage's: once a document)
    return _stageKeyed!.$2;
  }

  // (the moment alone moved: the values and key marks told to the inspector as it stands; anything else: built again)
  final _live = ValueNotifier<(Map<String, double>, Map<String, KeyS>)>((const {}, const {}));
  int? _frame;
  String? _titles; // (the picked thing's cards' titles as last read)
  Object _now(Ws ws) => (ws.rev, ws.selected, ws.animating);

  // (the reading of the document changed only numbers of what is picked, none that changes its cards: they are told
  //  to the fields that show them, as a moment's are; anything else, or not known: the inspector built again)
  bool _onlyNumbers(Ws ws) {
    final m = ws.inside, c = ws.lastChange, t = int.tryParse(ws.selected ?? '') ?? (ws.selected == null ? 0 : null);
    if (m == null || c == null || c.layers || t == null) return false;
    final titles = [for (final (title, _) in m.cards(t)) title].join(';');
    if (titles != _titles) {
      // (a card put on or taken off by its values alone: the Script card's knobs, as the Repeater is laid out from the Create shelf or taken off by its Reset)
      _titles = titles;
      return false;
    }
    for (final (thing, name) in c.values) {
      if (name == 'name' || (thing == t && (m.shaping.contains(name) || m.range(t, name) == null || m.shown(name)?.look == 'thing'))) {
        return false; // (another thing: shown by its name, a word) // (a name changed anywhere: things are named on cards; a word: it is not watched)
      }
      // (nor is an effect's colour, three numbers shown as one swatch as a word is (cards.dart): golf_noise.md (84))
      if (thing == t && RegExp(r'_[xyz]$').hasMatch(name) && RegExp(r' [rgb]$').hasMatch(m.shown(name)?.label ?? '')) return false;
    }
    return true;
  }

  static const _hears = [WsAspect.document, WsAspect.picked, WsAspect.animating]; // (what the inspector shows: the picked thing's cards, Animate all)
  void _changed() {
    final ws = _ws!, now = _now(ws), was = _seen;
    if (now != _seen) {
      _seen = now;
      _frame = ws.frame;
      if (was is (int, String?, bool) && was.$2 == ws.selected && was.$3 == ws.animating && _onlyNumbers(ws)) {
        _live.value = (wsTransform(ws, ws.layer?.id), _keyMarks(ws, ws.layer?.id));
        return;
      }
      if (mounted) setState(() {});
    } else if (ws.frame != _frame) {
      _frame = ws.frame;
      if (!_keyed(ws)) return;
      _live.value = (wsTransform(ws, ws.layer?.id), _keyMarks(ws, ws.layer?.id));
      _settle?.cancel();
      _settle = Timer(
        const Duration(milliseconds: 150),
        () => mounted ? setState(() {}) : null,
      ); // (the moment at rest: built once, whatever does not watch its own number shows it too)
    }
  }

  Timer? _settle;

  // (the inside showed something new while the document and the pick stayed (a hand carrying on the stage, a relation
  //  at a moment): the numbers told to the fields that show them; nothing built again)
  void _seenNow() {
    final ws = _ws!;
    if (_now(ws) != _seen || ws.selected == null || ws.playing) return; // (played: the moment's own reading above)
    _live.value = (wsTransform(ws, ws.layer?.id), _keyMarks(ws, ws.layer?.id));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WsScope.read(context);
    if (ws != _ws) {
      for (final a in _hears) {
        _ws?.on[a]!.removeListener(_changed);
        ws.on[a]!.addListener(_changed);
      }
      _ws?.moment.removeListener(_changed);
      _ws?.seen.removeListener(_seenNow);
      _ws = ws;
      ws.moment.addListener(_changed); // (the playhead too: the inspector's numbers are at the moment)
      ws.seen.addListener(_seenNow);
      _seen = _now(ws);
      _frame = ws.frame;
    }
  }

  @override
  void dispose() {
    for (final a in _hears) {
      _ws?.on[a]!.removeListener(_changed);
    }
    _ws?.moment.removeListener(_changed);
    _ws?.seen.removeListener(_seenNow);
    _settle?.cancel();
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ws = WsScope.read(context), l = ws.layer, k = _kindOf(l), m = ws.inside!;
    return InspHost(
              key: ValueKey(k),
              kind: k,
              kindWord: _kindWord(ws, l?.id),
              cards: _valueCards(ws, l?.id),
              title: l?.name,
              onSum: m.workOut,
              onCardReset: int.tryParse(l?.id ?? '') == null
                  ? null
                  : (names) => ws.after(m.later('reset', layer: int.parse(l!.id), word: names.join(' ')), (_, _) => ws.reread()),
              values: wsTransform(ws, l?.id),
              strs: _words(ws, l?.id),
              choices: _choices(ws, l?.id),
              onWords: (changed) => _say(ws, l?.id, changed),
              onAnimateAll: (on) => ws.animating = on,
              animating: ws.animating,
              flags: _flags(ws, l?.id),
              onFlags: (changed) => _flag(ws, l?.id, changed),
              keyMarks: _keyMarks(ws, l?.id),
              onValues: (changed, {required live}) => _write(ws, l?.id, changed, live: live),
              onDrop: () => ws.after(m.later('drag_end')), // (put down unchanged, without waiting)
              onKey: (prop, mark) => _mark(ws, l?.id, prop, mark),
              together: (tells) {
                // (one step, asked without waiting: begun and ended in the inside's queue around what is told)
                m.later('together', number: 1);
                tells();
                ws.after(m.later('together'));
              },
              live: _live,
              child: const InspectorPanel(),
            );
  }
}
