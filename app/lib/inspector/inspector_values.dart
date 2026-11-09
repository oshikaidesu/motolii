// Part of inspector_state.dart: the values the panel's cards edit (Doc), as the host gives them; none of its own.
part of 'inspector_state.dart';

/// The picked thing's values as the panel edits them: the host's numbers, words and switches, keyed `v_` and the
/// value's name as its cards declare them ([Fx]). It holds no value of its own: a card's default is its declaration's.
class Doc extends ChangeNotifier {
  Doc(this.kind, {this.cards = const []}) {
    for (final f in cards) {
      for (final (i, p) in f.params.indexed) {
        paramDefaults(f.id, p).forEach((id, x) => v[id] = d[id] = x); // (the declaration's @default, until the host says the value)
        if (p.look == ParamLook.color) s2.putIfAbsent('${f.id}_${p.id}', () => paramColor(f.decls[i]));
        if (p.look == ParamLook.choice) s2.putIfAbsent('${f.id}_${p.id}', () => p.options[p.def.round().clamp(0, p.options.length - 1)]);
      }
    }
  }

  final Kind kind;
  final Map<String, double> v = {}, d = {};
  final Map<String, KeyS> keys = {};
  final Map<String, String> s2 = {};

  final Map<String, bool> b = {};

  /// What the host calls the layer's kind, where the six kinds have no word for it (a film, a picture, a solid); null: the sample's.
  String? kindWord;

  /// The host's own cards of values (each one's Params, its fields keyed `v_` and the value's name): what the host has
  /// beyond the sample's cards.
  final List<Fx> cards;
  bool animateAll = false;

  /// Whether an edit marks its own key (the sample's rule, D2); off where a host owns the keys (joined: the document
  /// keys what a hand changes, and a mark told besides was a second key, made before the change, with the old value).
  bool marksEdits = true;

  @override
  void dispose() {
    for (final w in _watched.values) {
      w.dispose();
    }
    super.dispose();
  }

  /// The selected layer's own name, when a host (the workspace) knows it.
  String? title;

  String get name => title ?? '';

  double? get(String id) => v[id];

  /// A typed or reset value is absolute.
  void set(String id, double x) => setMany({id: x});

  void delta(String id, double dx) {
    v[id] = (v[id] ?? 0) + dx;
    _touch(id);
    notifyListeners();
  }

  ({Map<String, double> values, Map<String, KeyS> keys})? _gesture;

  /// A hand is on a value (between beginGesture and endGesture): what it shows is not settled yet.
  bool get inGesture => _gesture != null;

  void beginGesture() {
    _gesture ??= (values: Map.of(v), keys: Map.of(keys));
  }

  void endGesture() {
    final before = _gesture;
    _gesture = null;
    // (a hand let go: the host is told, but the inspector is not built again for it: the field under the hand already
    //  shows its number, the rows of what moved are told alone, and the host's reading of the document follows)
    ending = true;
    notifyListeners();
    ending = false;
    for (final e in v.entries) {
      if (before?.values[e.key] != e.value) _watched[e.key]?.value++;
    }
  }

  /// A hand letting go is being told (see [endGesture]).
  bool ending = false;

  /// What the host has at a new moment, shown as it is (not a hand's change: no key, no undo step): only the fields
  /// whose number or key mark moved are told (each watches its own), the inspector is not built again.
  /// Whether a value changed that no field watches (a choice, a switch): then the panel is built again to show it.
  bool showAt(Map<String, double> values, Map<String, KeyS> marks) {
    var unwatched = false;
    for (final e in values.entries) {
      if (v[e.key] == e.value) continue;
      v[e.key] = e.value;
      final w = _watched[e.key];
      if (w == null) {
        unwatched = true;
      } else {
        w.value++;
      }
    }
    for (final e in marks.entries) {
      if (keys[e.key] == e.value) continue;
      keys[e.key] = e.value;
      _watched['key:${e.key}']?.value++;
    }
    return unwatched;
  }

  /// One value's own news ('key:' and its name: its key mark's), as [showAt] tells it.
  final _watched = <String, ValueNotifier<int>>{};
  ValueListenable<int> watch(String id) => _watched.putIfAbsent(id, () => ValueNotifier(0));

  void setMany(Map<String, double> xs) {
    for (final e in xs.entries) {
      v[e.key] = e.value;
      _touch(e.key);
    }
    notifyListeners();
  }

  /// Reset writes the default value. On an animated row it also writes a key at the playhead (so the arrow drops: value == default).
  void resetIds(Iterable<String> ids) {
    for (final i in ids) {
      final dv = d[i] ?? 0;
      v[i] = dv;
      final p = propOf(i);
      if (animateAll || (keys[p] ?? KeyS.off) != KeyS.off) keys[p] = KeyS.at;
    }
    notifyListeners();
  }

  /// D2: while Animate all is on (or the property is animated), an edit writes a key at the playhead.
  void _touch(String id) {
    final p = propOf(id);
    if (marksEdits && (animateAll || (keys[p] ?? KeyS.off) != KeyS.off)) keys[p] = KeyS.at;
  }

  void setKey(String prop, KeyS s) {
    keys[prop] = s;
    _watched['key:$prop']?.value++; // (the field whose mark it is draws it now)
    notifyListeners();
  }

  void str(String id, String x) {
    s2[id] = x;
    notifyListeners();
  }

  void flag(String id, bool x) {
    b[id] = x;
    notifyListeners();
  }

  void poke() => notifyListeners();

  /// Fields picked together; Shift-click spans a rectangle of [_grid] (a card a row, its fields in their order) like a spreadsheet.
  final Set<String> picked = {};
  String? _pickFrom;
  bool isPicked(String id) => picked.length > 1 && picked.contains(id);

  void pick(String id, {bool span = false}) {
    final from = _pickFrom, a = from == null ? null : _cell(from), b = _cell(id), shown = picked.length > 1;
    picked.clear();
    if (span && a != null && b != null) {
      for (var r = math.min(a.$1, b.$1); r <= math.max(a.$1, b.$1); r++) {
        final row = _grid[r];
        for (var c = math.min(a.$2, b.$2); c <= math.max(a.$2, b.$2) && c < row.length; c++) {
          picked.add(row[c]);
        }
      }
    } else {
      picked.add(id);
      _pickFrom = id;
    }
    // (one field picked shows as nothing ([isPicked] is several): told only when the picking shows, before or after;
    //  a press on a knob picked it and built the whole inspector again for no change)
    if (shown || picked.length > 1) notifyListeners();
  }

  void unpick() {
    if (picked.isEmpty) return;
    picked.clear();
    notifyListeners();
  }

  late final _grid = [
    for (final f in cards) [for (final p in f.params) ...paramDefaults(f.id, p).keys],
  ];
  (int, int)? _cell(String id) {
    for (var r = 0; r < _grid.length; r++) {
      final c = _grid[r].indexOf(id);
      if (c >= 0) return (r, c);
    }
    return null;
  }

  /// The host's cards that may be moved up or down (its effects, by their titles), and what moves one so many places.
  List<String> movable = const [];
  void Function(String title, int by)? onCardMove;
  List<String> moreCards = const []; // (the cards it may be given and is not shown)
  void Function(String title)? onMoreCard;
  VoidCallback? onAddEffect; // (Alight Motion's Add Effect: the shelf of them, its search taking the keys)
  double? Function(String sum)? onSum; // (a sum typed in a number field worked out: null, it is not one)
  void Function(List<String> names)? onCardReset;
  void Function(String title)? onCardRemove;
  Widget? Function(String title, List<String> names)? cardCode; // (a card's code as the host draws it, by its title and its values' names (two cards may share a title: ThorVG's Tint and an ISF Duotone): a script's, under its knobs, as After Effects' expression under its value)
  void Function(String title)? onCardEye;
  void Function(String title, List<String> names)? onCardSave;
  void Function(String title)? onCardInfo;
  void Function(String title)? onCardDuplicate;
  List<String> cardsOff = const [];
  void Function(List<String> names)? onCardCopy;
  VoidCallback? onCardPaste;
}
