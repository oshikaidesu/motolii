// Owns the panel's values (Doc) and provides them again whenever they change. A different kind makes a new document, so give the widget a key.
// The look follows docs/app/DESIGN.md: hairlines, type carries hierarchy, grey levels, and an accent only for Role.selected.

import 'package:flutter/foundation.dart' show ValueListenable, listEquals, mapEquals;
import 'package:flutter/widgets.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/inspector/inspector_values.dart';

/// Owns the panel's values ([Doc]) and provides them again whenever they change.
/// A different kind makes a new document, so give the widget a key.
class InspHost extends StatefulWidget {
  const InspHost({
    super.key,
    required this.kind,
    required this.kindWord,
    required this.movable,
    required this.onCardMove,
    required this.onSum,
    required this.onAddEffect,
    required this.moreCards,
    required this.onMoreCard,
    required this.onCardReset,
    required this.onCardRemove,
    required this.cardCode,
    required this.onCardEye,
    required this.onCardSave,
    required this.onCardInfo,
    required this.onCardDuplicate,
    required this.cardsOff,
    required this.onCardCopy,
    required this.onCardPaste,
    required this.cards,
    required this.title,
    required this.onRoute,
    required this.onAim,
    required this.values,
    required this.keyMarks,
    required this.onValues,
    required this.onDrop,
    required this.onKey,
    required this.onWords,
    required this.onAnimateAll,
    required this.animating,
    required this.flags,
    required this.onFlags,
    required this.together,
    required this.live,
    required this.strs,
    required this.child,
  });
  final Kind kind;
  final Widget child;

  /// The caller's name for the kind (see [Doc.kindWord]).
  final String? kindWord;

  /// The values and key marks at a new time, applied without rebuilding the host.
  /// During playback only the time moves, so the fields that show the values follow and the rest of the inspector stays as built.
  final ValueListenable<(Map<String, double>, Map<String, KeyS>)> live;

  /// The caller's effects as cards that move up or down its stack (see [Doc.movable]).
  final List<String> movable;
  final void Function(String title, int by)? onCardMove;
  final double? Function(String sum) onSum;
  final VoidCallback? onAddEffect;
  final List<String> moreCards;
  final void Function(String title)? onMoreCard;

  /// Resets a card's values to their defaults (Reset on the card head).
  final void Function(List<String> names)? onCardReset;

  /// Removes an effect (Remove on the card head, like Alight Motion's Delete).
  final void Function(String title)? onCardRemove;

  /// Builds the code view of a card (see [Doc.cardCode]).
  final Widget? Function(String title, List<String> names)? cardCode;

  /// Turns an effect off or on again, keeping its values (like the eye on an effect in Alight Motion).
  final void Function(String title)? onCardEye;

  /// Saves an effect's values, keys included, as a preset on the shelf (like Alight Motion's preset of one effect).
  final void Function(String title, List<String> names)? onCardSave;

  /// Shows what an effect does, in its author's words (like AbsentMotion's Effect Info).
  final void Function(String title)? onCardInfo;

  /// Adds a copy of an effect after it, with its values (like Alight Motion's Duplicate).
  final void Function(String title)? onCardDuplicate;

  /// Titles of the effects that are turned off.
  final List<String> cardsOff;

  /// Copies a card's values so they can be pasted onto another layer (Copy on the card head).
  final void Function(List<String> names)? onCardCopy;

  /// Pastes the copied card values (Paste on the card head).
  final VoidCallback? onCardPaste;

  /// The caller's own cards of values (see [Doc.cards]).
  final List<Fx>? cards;

  /// The selected layer's name, when the caller knows it.
  final String? title;

  /// A panel link asked to open a panel (`Browser › Fonts`, `Ease`); the caller opens it.
  final ValueChanged<String> onRoute;

  /// The slot a panel link pointed at when it asked for its panel, or '' for none. Called just before [onRoute].
  final ValueChanged<String> onAim;

  /// Values the caller owns, such as the layer's transform at this frame. They are written in silently when they change, so edits made here last until then.
  final Map<String, double> values;
  final Map<String, String> strs;

  /// The key mark of each property (position, scale, rotation ...) as the caller's document has it.
  final Map<String, KeyS> keyMarks;

  /// Values changed in the inspector. [live] is true while a drag is still in progress, and the call is repeated once when the drag ends.
  final void Function(Map<String, double> changed, {required bool live}) onValues;

  /// A drag was cancelled with Esc: what it showed is to be dropped.
  final VoidCallback onDrop;

  /// A property's key mark was changed in the inspector.
  final void Function(String prop, KeyS mark) onKey;

  /// Strings changed in the inspector, such as a text's content or a chooser's choice.
  /// Returns false if the caller did not take them, and the fields go back to their previous strings.
  final bool Function(Map<String, String> changed) onWords;

  /// Animate all was turned on or off. The caller's document may then key whatever a drag changes, wherever the drag is.
  final ValueChanged<bool> onAnimateAll;

  /// The caller's own Animate all. It is shown as given and is never reset by a new kind.
  final bool animating;

  /// The on/off properties the caller owns, such as Clip to below, and the callback for a change of them.
  /// The callback returns false if the caller did not take the change (nothing is behind that switch), and the switch goes back.
  final Map<String, bool> flags;
  final bool Function(Map<String, bool> changed)? onFlags;

  /// Wraps one change of the inspector, values then key marks, so the caller can record it as one undo step.
  final void Function(VoidCallback tells) together;
  @override
  State<InspHost> createState() => _InspHostState();
}

class _InspHostState extends State<InspHost> {
  late Doc doc = _make();
  Doc _make() {
    final d = Doc(widget.kind, cards: widget.cards ?? const []);
    _wire(d);
    d
      ..v.addAll(widget.values)
      ..s2.addAll(widget.strs)
      ..b.addAll(widget.flags)
      ..keys.addAll(widget.keyMarks)
      ..animateAll = _animating = widget.animating;
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
    return d..addListener(_r);
  }

  /// Gives the document what the caller says about the selected layer, as it is now.
  void _wire(Doc d) => d
    ..title = widget.title
    ..kindWord = widget.kindWord
    ..movable = widget.movable
    ..onCardMove = widget.onCardMove
    ..onSum = widget.onSum
    ..onAddEffect = widget.onAddEffect
    ..moreCards = widget.moreCards
    ..onMoreCard = widget.onMoreCard
    ..onCardReset = widget.onCardReset
    ..onCardRemove = widget.onCardRemove
    ..cardCode = widget.cardCode
    ..onCardEye = widget.onCardEye
    ..onCardSave = widget.onCardSave
    ..onCardInfo = widget.onCardInfo
    ..onCardDuplicate = widget.onCardDuplicate
    ..cardsOff = widget.cardsOff
    ..onCardCopy = widget.onCardCopy
    ..onCardPaste = widget.onCardPaste;

  // What the caller has been told of or gave. Only what differs from it is reported.
  final _seen = <String, double>{};
  final _seenKeys = <String, KeyS>{};
  final _seenWords = <String, String>{};
  final _seenFlags = <String, bool>{};
  bool _live = false;
  // During a drag, report only the current values and make no undo step, since nothing is settled.
  void _tell() => doc.inGesture ? _tells() : widget.together(_tells);
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
      // While a drag is in progress nothing is settled; the key is reported when the drag ends.
      if (live || _seenKeys[e.key] == e.value) continue;
      _seenKeys[e.key] = e.value;
      widget.onKey(e.key, e.value);
    }
    final words = {
      for (final e in doc.s2.entries)
        if (e.key != 'route' && e.key != 'route.at' && _seenWords[e.key] != e.value) e.key: e.value,
    };
    if (widget.onFlags case final tell?) {
      final flags = {
        for (final e in doc.b.entries)
          if ((_seenFlags[e.key] ?? e.key.endsWith('.open')) != e.value)
            // A card is open until it is folded, so its first fold is news too. Otherwise it would open again at the next read.
            e.key: e.value,
      };
      if (flags.isNotEmpty) {
        if (tell(flags)) {
          _seenFlags.addAll(flags);
        } else {
          for (final id in flags.keys) {
            doc.b[id] = _seenFlags[id] ?? false;
          }
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

  void _r() {
    _tell();
    final r = doc.s2['route'];
    if (r != null) {
      doc.s2.remove('route');
      widget.onAim(doc.s2.remove('route.at') ?? '');
      widget.onRoute(r);
    }
    // During a drag the whole inspector is not rebuilt at each step: the field being dragged shows its own value
    // and the preview follows what the caller is told. Everything is rebuilt once when the drag ends.
    if (mounted && !doc.inGesture && !doc.ending) setState(() => _tick++);
  }

  @override
  void didUpdateWidget(InspHost o) {
    super.didUpdateWidget(o);
    if (o.live != widget.live) {
      o.live.removeListener(_atMoment);
      widget.live.addListener(_atMoment);
    }
    if (o.kind != widget.kind ||
        !listEquals(
          o.cards?.map((f) => f.name + f.wgsl.replaceAll(RegExp(r'@default\([^)]*\)'), '')).toList(),
          widget.cards?.map((f) => f.name + f.wgsl.replaceAll(RegExp(r'@default\([^)]*\)'), '')).toList(),
        )) {
      doc.dispose();
      doc = _make();
      _tick++;
    } else {
      // A caller that is told of changes owns the values. Whatever it did not take goes back to what it says as soon as no drag is in progress.
      // A value being dragged is never overwritten, even during playback.
      // Numbers and key marks are sent to the fields that show them; strings, flags, choices and the rest cause a full rebuild.
      if (!doc.inGesture) {
        // A value that no field watches changed, so rebuild to show it.
        if (doc.showAt(widget.values, const {})) _tick++;
        _seen.addAll(widget.values);
      }
      if (widget.onFlags != null) {
        if (widget.flags.entries.any((e) => doc.b[e.key] != e.value)) _tick++;
        doc.b.addAll(widget.flags);
        _seenFlags.addAll(widget.flags);
      }
      if (widget.strs.entries.any((e) => doc.s2[e.key] != e.value)) _tick++;
      doc.s2.addAll(widget.strs);
      _seenWords.addAll(widget.strs);
      // Also cover the case where what is shown differs from the document. A key mark that was just pressed shows lit at once,
      // and an undo that removes the key leaves the document's marks as they were before the press, so only the shown one differs.
      if (!mapEquals(o.keyMarks, widget.keyMarks) || widget.keyMarks.entries.any((e) => doc.keys[e.key] != e.value)) {
        doc.showAt(const {}, widget.keyMarks);
        _seenKeys.addAll(widget.keyMarks);
      }
    }
    if (widget.animating != _animating) {
      doc.animateAll = _animating = widget.animating;
      _tick++;
    }
    if (o.title != widget.title || o.kindWord != widget.kindWord || !listEquals(o.cardsOff, widget.cardsOff)) {
      // The eye of an effect was shut or opened, so its card must change.
      _tick++;
    }
    _wire(doc);
  }

  void _atMoment() {
    final (values, marks) = widget.live.value;
    // Never during a drag.
    if (doc.inGesture) return;
    _seen.addAll(values);
    _seenKeys.addAll(marks);
    // A value that no field watches changed, such as a choice, so rebuild to show it.
    if (doc.showAt(values, marks) && mounted) setState(() => _tick++);
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
