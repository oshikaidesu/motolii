// Owns the panel's values (InspectorValues) and provides them again whenever they change. A different kind makes a new document, so give the widget a key.
// The look follows docs/app/DESIGN.md: hairlines, type carries hierarchy, grey levels, and an accent only for Role.selected.

import 'package:flutter/foundation.dart' show ValueListenable, listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_parts.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_sync.dart';
import 'package:motolii/inspector/inspector_values.dart';

/// Owns the panel's values ([InspectorValues]) and provides them again whenever they change.
/// A different kind makes a new document, so give the widget a key.
class InspectorHost extends StatefulWidget {
  const InspectorHost({
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

  /// The caller's name for the kind (see [InspectorValues.kindWord]).
  final String? kindWord;

  /// The values and key marks at a new time, applied without rebuilding the host.
  /// During playback only the time moves, so the fields that show the values follow and the rest of the inspector stays as built.
  final ValueListenable<(Map<String, double>, Map<String, KeyframeState>)> live;

  /// The caller's effects as cards that move up or down its stack (see [InspectorValues.movable]).
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

  /// Builds the code view of a card (see [InspectorValues.cardCode]).
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

  /// The caller's own cards of values (see [InspectorValues.cards]).
  final List<CardDeclaration>? cards;

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
  final Map<String, KeyframeState> keyMarks;

  /// Values changed in the inspector. [live] is true while a drag is still in progress, and the call is repeated once when the drag ends.
  final void Function(Map<String, double> changed, {required bool live})
  onValues;

  /// A drag was cancelled with Esc: what it showed is to be dropped.
  final VoidCallback onDrop;

  /// A property's key mark was changed in the inspector.
  final void Function(String prop, KeyframeState mark) onKey;

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
  State<InspectorHost> createState() => _InspectorHostState();
}

class _InspectorHostState extends State<InspectorHost> {
  late InspectorValues doc = _make();
  InspectorValues _make() {
    final d = InspectorValues(widget.kind, cards: widget.cards ?? const []);
    _wire(d);
    _sync.start(d, _snapshotOf(widget));
    return d..addListener(_r);
  }

  /// Gives the document what the caller says about the selected layer, as it is now.
  void _wire(InspectorValues d) => d
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

  final _sync = InspectorSync();

  InspectorSnapshot _snapshotOf(InspectorHost w) => InspectorSnapshot(
    numbers: w.values,
    words: w.strs,
    flags: w.flags,
    keyMarks: w.keyMarks,
    animating: w.animating,
  );

  InspectorEdits get _edits => InspectorEdits(
    onValues: widget.onValues,
    onDrop: widget.onDrop,
    onKey: widget.onKey,
    onWords: widget.onWords,
    onFlags: widget.onFlags,
    onAnimateAll: widget.onAnimateAll,
    together: widget.together,
    onRoute: widget.onRoute,
    onAim: widget.onAim,
  );

  void _r() {
    _sync.report(doc, _edits);
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
  void didUpdateWidget(InspectorHost o) {
    super.didUpdateWidget(o);
    if (o.live != widget.live) {
      o.live.removeListener(_atMoment);
      widget.live.addListener(_atMoment);
    }
    if (o.kind != widget.kind ||
        !listEquals(
          o.cards
              ?.map(
                (f) =>
                    f.name +
                    f.wgsl.replaceAll(RegExp(r'@default\([^)]*\)'), ''),
              )
              .toList(),
          widget.cards
              ?.map(
                (f) =>
                    f.name +
                    f.wgsl.replaceAll(RegExp(r'@default\([^)]*\)'), ''),
              )
              .toList(),
        )) {
      doc.dispose();
      doc = _make();
      _tick++;
    } else if (_sync.show(
      doc,
      _snapshotOf(widget),
      _edits,
      previous: _snapshotOf(o),
    )) {
      _tick++;
    }
    if (o.title != widget.title ||
        o.kindWord != widget.kindWord ||
        !listEquals(o.cardsOff, widget.cardsOff)) {
      // The eye of an effect was shut or opened, so its card must change.
      _tick++;
    }
    _wire(doc);
  }

  void _atMoment() {
    final (values, marks) = widget.live.value;
    // A value that no field watches changed, such as a choice, so rebuild to show it.
    if (_sync.showAt(doc, values, marks) && mounted) setState(() => _tick++);
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
  Widget build(BuildContext context) =>
      InspectorScope(doc: doc, tick: _tick, child: widget.child);
}
