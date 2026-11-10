// The values the panel's cards edit (InspectorValues). The caller supplies them; this file holds none of its own.
import 'package:flutter/foundation.dart'
    show ChangeNotifier, ValueListenable, ValueNotifier;

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/controls/inspector_parameter_controls.dart';
import 'package:motolii/inspector/controls/parameter_inference.dart';
import 'package:motolii/inspector/field_selection.dart';
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_card.dart';
import 'package:motolii/inspector/inspector_state.dart';

/// The values of the selected layer as the inspector edits them: numbers, strings and switches.
/// Keys are `v_` plus the value name as its card declares it ([CardDeclaration]).
/// InspectorValues keeps no values of its own; a card's default comes from its declaration.
class InspectorValues extends ChangeNotifier {
  InspectorValues(this.kind, {this.cards = const []}) {
    for (final f in cards) {
      for (final (i, p) in f.params.indexed) {
        // Start from the declaration's @default until the caller supplies the value.
        paramDefaults(p).forEach((id, x) => v[id] = d[id] = x);
        if (p.look == ParameterLook.color) {
          s2.putIfAbsent('v_${p.id}', () => paramColor(f.decls[i]));
        }
        if (p.look == ParameterLook.choice) {
          s2.putIfAbsent(
            'v_${p.id}',
            () => p.options[p.def.round().clamp(0, p.options.length - 1)],
          );
        }
      }
    }
  }

  final Kind kind;
  final Map<String, double> v = {}, d = {};
  final Map<String, KeyframeState> keys = {};
  final Map<String, String> s2 = {};

  final Map<String, bool> b = {};

  /// The cards these values were made for. Each card's params are fields keyed `v_` plus the value name.
  /// They stay as they were when the values were made, while [layer] follows the caller.
  final List<CardDeclaration> cards;

  /// The layer as the caller describes it now: its name, the caller's word for its kind, and which cards move, are off or could be added.
  late InspectedLayer layer = InspectedLayer(kind: kind, cards: cards);

  /// What the buttons and menus on the cards do, as the caller gives them now. Read them when they are used, not before.
  CardActions actions = const CardActions();
  bool animateAll = false;

  @override
  void dispose() {
    for (final w in _watched.values) {
      w.dispose();
    }
    super.dispose();
  }

  /// The selected layer's name, or '' when the caller does not know it.
  String get name => layer.title ?? '';

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
  bool showAt(Map<String, double> values, Map<String, KeyframeState> marks) {
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
  ValueListenable<int> watch(String id) =>
      _watched.putIfAbsent(id, () => ValueNotifier(0));

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
      if (animateAll || (keys[p] ?? KeyframeState.off) != KeyframeState.off) {
        keys[p] = KeyframeState.at;
      }
    }
    notifyListeners();
  }

  void setKey(String prop, KeyframeState s) {
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

  /// The fields selected together, so that an edit of one changes them all. A change of it notifies this object's listeners.
  late final FieldSelection fields = FieldSelection(
    rows: () => [
      for (final f in cards)
        [for (final p in f.params) ...paramDefaults(p).keys],
    ],
    onChanged: notifyListeners,
  );
}
