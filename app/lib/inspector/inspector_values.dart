// Part of inspector_state.dart: the values the panel's cards edit (Doc). The caller supplies them; this file holds none of its own.
part of 'inspector_state.dart';

/// The values of the selected layer as the inspector edits them: numbers, strings and switches.
/// Keys are `v_` plus the value name as its card declares it ([Fx]).
/// Doc keeps no values of its own; a card's default comes from its declaration.
class Doc extends ChangeNotifier {
  Doc(this.kind, {this.cards = const []}) {
    for (final f in cards) {
      for (final (i, p) in f.params.indexed) {
        // Start from the declaration's @default until the caller supplies the value.
        paramDefaults(p).forEach((id, x) => v[id] = d[id] = x);
        if (p.look == ParamLook.color) s2.putIfAbsent('v_${p.id}', () => paramColor(f.decls[i]));
        if (p.look == ParamLook.choice) s2.putIfAbsent('v_${p.id}', () => p.options[p.def.round().clamp(0, p.options.length - 1)]);
      }
    }
  }

  final Kind kind;
  final Map<String, double> v = {}, d = {};
  final Map<String, KeyS> keys = {};
  final Map<String, String> s2 = {};

  final Map<String, bool> b = {};

  /// The caller's name for the layer kind where the six kinds have none, such as video, image or solid. Null uses the sample's name.
  String? kindWord;

  /// Cards the caller supplies in addition to the sample's cards.
  /// Each card's params become fields keyed `v_` plus the value name.
  final List<Fx> cards;
  bool animateAll = false;

  @override
  void dispose() {
    for (final w in _watched.values) {
      w.dispose();
    }
    super.dispose();
  }

  /// The selected layer's name, when the caller knows it.
  String? title;

  String get name => title ?? '';

  double? get(String id) => v[id];

  /// A typed or reset value is absolute.
  void set(String id, double x) => setMany({id: x});

  void delta(String id, double dx) {
    v[id] = (v[id] ?? 0) + dx;
    notifyListeners();
  }

  Map<String, double>? _gesture;

  /// Whether a drag is in progress, between [beginGesture] and [endGesture]. The values shown are not final yet.
  bool get inGesture => _gesture != null;

  void beginGesture() {
    _gesture ??= Map.of(v);
  }

  void endGesture() {
    final before = _gesture;
    _gesture = null;
    // The drag ended. Listeners are notified, but the inspector does not rebuild: the field being dragged already shows its value.
    // Only the rows of changed values are notified, and the caller then reads the document back.
    ending = true;
    notifyListeners();
    ending = false;
    for (final e in v.entries) {
      if (before?[e.key] != e.value) _watched[e.key]?.value++;
    }
  }

  /// True while the end of a drag is being notified (see [endGesture]).
  bool ending = false;

  /// Shows the caller's values at a new time without treating them as an edit: no key and no undo step.
  /// Only the fields whose value or key mark changed are notified, since each watches its own; the inspector does not rebuild.
  /// Returns true when a changed value has no watching field, such as a choice or a switch, so the caller must rebuild the panel.
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

  /// One notifier per value id, or `key:` plus the property name for a key mark. [showAt] and [setKey] bump them.
  final _watched = <String, ValueNotifier<int>>{};
  ValueListenable<int> watch(String id) => _watched.putIfAbsent(id, () => ValueNotifier(0));

  void setMany(Map<String, double> xs) {
    for (final e in xs.entries) {
      v[e.key] = e.value;
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

  void setKey(String prop, KeyS s) {
    keys[prop] = s;
    // Notify the field that draws this key mark.
    _watched['key:$prop']?.value++;
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

  /// The fields selected together.
  /// Shift-click selects a rectangle of [_grid], one row per card with its fields in order, like a spreadsheet.
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
    // Selecting one field shows nothing, because [isPicked] needs several. Notify only when the selection was or becomes visible,
    // otherwise pressing a parameter control rebuilt the whole inspector for no change.
    if (shown || picked.length > 1) notifyListeners();
  }

  void unpick() {
    if (picked.isEmpty) return;
    picked.clear();
    notifyListeners();
  }

  late final _grid = [
    for (final f in cards) [for (final p in f.params) ...paramDefaults(p).keys],
  ];
  (int, int)? _cell(String id) {
    for (var r = 0; r < _grid.length; r++) {
      final c = _grid[r].indexOf(id);
      if (c >= 0) return (r, c);
    }
    return null;
  }

  /// Titles of the caller's cards that can move up or down (its effects), and the callback that moves one by that many places.
  List<String> movable = const [];
  void Function(String title, int by)? onCardMove;

  /// Titles of cards the caller could add that are not shown yet.
  List<String> moreCards = const [];
  void Function(String title)? onMoreCard;

  /// Opens the effect shelf with its search focused, like Alight Motion's Add Effect.
  VoidCallback? onAddEffect;

  /// Evaluates an arithmetic expression typed into a number field. Returns null if the text is not one.
  double? Function(String sum)? onSum;
  void Function(List<String> names)? onCardReset;
  void Function(String title)? onCardRemove;

  /// Builds the code view of a card, found by its title and its value names, because two cards can share a title (ThorVG's Tint and an ISF Duotone).
  /// It sits under the card's parameters, like After Effects' expression under its value.
  Widget? Function(String title, List<String> names)? cardCode;
  void Function(String title)? onCardEye;
  void Function(String title, List<String> names)? onCardSave;
  void Function(String title)? onCardInfo;
  void Function(String title)? onCardDuplicate;
  List<String> cardsOff = const [];
  void Function(List<String> names)? onCardCopy;
  VoidCallback? onCardPaste;
}
