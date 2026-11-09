// Owns the panel's values (Doc) and re-provides it whenever it changes. A different kind makes a new document (give it a key).
// How it LOOKS is the lab's (DESIGN.md): hairlines, type carries hierarchy, grey levels, accent only Role.selected. The old Motolii is not a source.

import 'package:flutter/foundation.dart' show ValueListenable, listEquals, mapEquals;
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';

String _bare(Fx f) => f.name + f.wgsl.replaceAll(RegExp(r'@default\([^)]*\)'), '');

/// Owns the panel's values (Doc) and re-provides it whenever it changes. A different kind makes a new document (give it a key).
class InspHost extends StatefulWidget {
  const InspHost({
    super.key,
    required this.kind,
    this.kindWord,
    this.onSum,
    this.onCardReset,
    this.cards,
    this.title,
    this.values = const {},
    this.strs = const {},
    this.keyMarks = const {},
    required this.onValues,
    required this.onDrop,
    required this.onKey,
    required this.onWords,
    required this.onAnimateAll,
    required this.animating,
    this.flags = const {},
    required this.onFlags,
    this.choices = const {},
    required this.together,
    required this.live,
    required this.child,
  });
  final Kind kind;
  final Widget child;

  /// What the host calls the kind (see [Doc.kindWord]).
  final String? kindWord;

  /// The values and key marks at a new moment, told without the host being built again (played, only the moment moves:
  /// the fields that show them follow, the rest of the inspector stays as it was built).
  final ValueListenable<(Map<String, double>, Map<String, KeyS>)> live;

  final double? Function(String sum)? onSum;
  final void Function(List<String> names)? onCardReset;

  /// The host's own cards of values (see [Doc.cards]).
  final List<Fx>? cards;

  /// The selected layer's name, when the host knows it.
  final String? title;

  /// Values the host owns (the layer's transform at this frame): written in silently when they change, so edits made here last until then.
  final Map<String, double> values;
  final Map<String, String> strs;

  /// The key mark of each property (pos, scale, rot ...) as the host's document has it.
  final Map<String, KeyS> keyMarks;

  /// Values changed in the inspector: [live] while a hand is still on them (not settled), then once more when it lets go.
  final void Function(Map<String, double> changed, {required bool live}) onValues;

  /// A hand let go without keeping what it did (Esc): what it showed is to be dropped.
  final VoidCallback onDrop;

  /// A property's key mark was changed in the inspector.
  final void Function(String prop, KeyS mark) onKey;

  /// Words changed in the inspector (a text's content, a chooser's choice). false: the host did not take them, and they go back to what they were.
  final bool Function(Map<String, String> changed) onWords;

  /// Animate all was turned on or off (the host's document may key whatever a hand changes, wherever the hand is).
  final ValueChanged<bool> onAnimateAll;

  /// The host's own Animate all, shown as it is.
  final bool animating;

  /// The on/off properties the host owns (Clip to below ...), and a change of them told to it. false: the host did not
  /// take it (nothing is behind that switch), and the switch goes back.
  final Map<String, bool> flags;
  final bool Function(Map<String, bool> changed) onFlags;

  /// What a chooser may offer, by its id, where the host's document has its own words for it (a blend's).
  final Map<String, List<String>> choices;

  /// What one change of the inspector tells the host (values, then key marks) is told inside this, so a host can keep it as one act.
  final void Function(VoidCallback tells) together;
  @override
  State<InspHost> createState() => _InspHostState();
}

class _InspHostState extends State<InspHost> {
  late Doc doc = _make();
  Doc _make() {
    final d = Doc(widget.kind, cards: widget.cards ?? const [])
      ..title = widget.title
      ..kindWord = widget.kindWord
      ..onSum = widget.onSum
      ..onCardReset = widget.onCardReset
      ..v.addAll(widget.values)
      ..s2.addAll(widget.strs)
      ..choices.addAll(widget.choices)
      ..b.addAll(widget.flags)
      ..keys.addAll(widget.keyMarks);
    _seen
      ..clear()
      ..addAll(d.v);
    _seenKeys
      ..clear()
      ..addAll(d.keys);
    _seenWords
      ..clear()
      ..addAll(d.s2);
    _seenFlags
      ..clear()
      ..addAll(d.b);
    d.animateAll = _animating = widget.animating; // (the host's: the inspector shows it)
    return d..addListener(_r);
  }

  // what the host has been told of (or gave): only what differs from it is told
  final _seen = <String, double>{};
  final _seenKeys = <String, KeyS>{};
  final _seenWords = <String, String>{};
  final _seenFlags = <String, bool>{};
  bool _live = false;
  void _tell() => doc.inGesture ? _tells() : widget.together(_tells); // (under a hand only where it is is told, nothing settled: no step to make one of)
  bool _animating = false;
  void _tells() {
    if (doc.animateAll != _animating) widget.onAnimateAll(_animating = doc.animateAll);
    final live = doc.inGesture,
        changed = {
          for (final e in doc.v.entries)
            if (_seen[e.key] != e.value) e.key: e.value,
        };
    if (changed.isNotEmpty) {
      if (!live) _seen.addAll(changed);
      widget.onValues(changed, live: live);
    } else if (_live && !live) {
      widget.onDrop();
    }
    _live = live;
    for (final e in doc.keys.entries.toList()) {
      if (live || _seenKeys[e.key] == e.value) continue; // (while a hand is on it nothing is settled: told when it lets go)
      _seenKeys[e.key] = e.value;
      widget.onKey(e.key, e.value);
    }
    final words = {
      for (final e in doc.s2.entries)
        if (_seenWords[e.key] != e.value) e.key: e.value,
    };
    final flags = {
      for (final e in doc.b.entries)
        if ((_seenFlags[e.key] ?? e.key.endsWith('.open')) != e.value)
          e.key: e.value, // (a card is open until it is folded: its first fold is news too, or it opens again at the next reading)
    };
    if (flags.isNotEmpty) {
      if (widget.onFlags(flags)) {
        _seenFlags.addAll(flags);
      } else {
        for (final id in flags.keys) {
          doc.b[id] = _seenFlags[id] ?? false;
        }
      }
    }
    if (words.isEmpty) return;
    if (widget.onWords(words)) {
      _seenWords.addAll(words);
    } else {
      for (final id in words.keys) {
        _seenWords.containsKey(id) ? doc.s2[id] = _seenWords[id]! : doc.s2.remove(id);
      }
    }
  }

  void _take<T>(Map<String, T> from, Map<String, T> into, Map<String, T> seen) {
    if (from.entries.any((e) => into[e.key] != e.value)) _tick++;
    into.addAll(from);
    seen.addAll(from);
  }

  void _r() {
    _tell();
    // (while a hand is on a value the whole inspector is not built again each step: the field under the hand shows its
    //  own number and the stage follows what the host is told; everything is built once when the hand lets go)
    if (mounted && !doc.inGesture && !doc.ending) setState(() => _tick++);
  }

  @override
  void didUpdateWidget(InspHost o) {
    super.didUpdateWidget(o);
    if (o.live != widget.live) {
      o.live.removeListener(_atMoment);
      widget.live.addListener(_atMoment);
    }
    if (o.kind != widget.kind || !listEquals(o.cards?.map(_bare).toList(), widget.cards?.map(_bare).toList())) {
      doc.dispose();
      doc = _make();
      _tick++;
    } else {
      // A host that is told of changes owns the values: whatever it did not take goes back to what it says, as soon
      // as no hand is on them (never under a hand: a value being dragged is not written over, even while it plays).
      // (numbers and key marks: told to the fields that show them; words, flags, choices and the rest: everything again)
      if (!doc.inGesture) {
        if (doc.showAt(widget.values, const {})) _tick++; // (a value no field watches changed: shown by building again)
        _seen.addAll(widget.values);
      }
      _take(widget.flags, doc.b, _seenFlags);
      _take(widget.strs, doc.s2, _seenWords);
      // (and where what is shown is not what the document says: a key mark pressed shows lit at once, and an undo that
      //  takes the key away leaves the document's marks as they were before the press, so only the shown one differs)
      if (!mapEquals(o.keyMarks, widget.keyMarks) || widget.keyMarks.entries.any((e) => doc.keys[e.key] != e.value)) {
        doc.showAt(const {}, widget.keyMarks);
        _seenKeys.addAll(widget.keyMarks);
      }
    }
    if (widget.animating != _animating) {
      doc.animateAll = _animating = widget.animating;
      _tick++;
    }
    if (o.title != widget.title || o.kindWord != widget.kindWord || o.choices.toString() != widget.choices.toString()) {
      _tick++;
    }
    doc
      ..title = widget.title
      ..kindWord = widget.kindWord
      ..onSum = widget.onSum
      ..onCardReset = widget.onCardReset;
    doc.choices
      ..clear()
      ..addAll(widget.choices);
  }

  void _atMoment() {
    final (values, marks) = widget.live.value;
    if (doc.inGesture) return; // (never under a hand)
    _seen.addAll(values);
    _seenKeys.addAll(marks);
    if (doc.showAt(values, marks) && mounted) setState(() => _tick++); // (a value no field watches, a choice, changed: shown by building again)
  }

  @override
  void initState() {
    super.initState();
    widget.live.addListener(_atMoment);
  }

  @override
  void dispose() {
    widget.live.removeListener(_atMoment);
    doc.dispose();
    super.dispose();
  }

  int _tick = 0;
  @override
  Widget build(BuildContext context) => Ctx(doc: doc, tick: _tick, child: widget.child);
}
