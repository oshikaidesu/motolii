import 'package:flutter/foundation.dart' show mapEquals;

import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/inspector_values.dart';

/// Keeps the values the Inspector edits and the values their owner holds the same, passing each way only what differs.
///
/// It remembers what the owner gave or has been told. An edit is reported to the owner once,
/// and what the owner says replaces what the Inspector shows, except a value that is being dragged.
class InspectorSync {
  // What the caller has been told of or gave. Only what differs from it is reported.
  final _seen = <String, double>{};
  final _seenKeys = <String, KeyframeState>{};
  final _seenWords = <String, String>{};
  final _seenFlags = <String, bool>{};
  bool _live = false;
  // The strings a drag in progress has told live. When it ends they are told once more as settled, even unchanged.
  final _liveWords = <String, String>{};
  bool _animating = false;

  /// Fills a new [doc] with the owner's [snapshot], which is then what the owner is known to have seen.
  void start(InspectorValues doc, InspectorSnapshot snapshot) {
    doc
      ..numbers.addAll(snapshot.numbers)
      ..strings.addAll(snapshot.words)
      ..flags.addAll(snapshot.flags)
      ..keys.addAll(snapshot.keyMarks)
      ..animateAll = _animating = snapshot.animating;
    _seen
      ..clear()
      ..addAll(doc.numbers);
    _seenKeys
      ..clear()
      ..addAll(doc.keys);
    _seenWords
      ..clear()
      ..addAll(doc.strings);
    _seenFlags
      ..clear()
      ..addAll(doc.flags);
  }

  /// Reports through [edits] whatever [doc] holds that the owner has not seen: values, key marks, strings, switches and Animate all.
  ///
  /// Strings and switches the owner refuses go back to what it last had.
  // During a drag, report only the current values and make no undo step, since nothing is settled.
  void report(InspectorValues doc, InspectorEdits edits) => doc.inGesture
      ? _reportAll(doc, edits)
      : edits.together(() => _reportAll(doc, edits));

  void _reportAll(InspectorValues doc, InspectorEdits edits) {
    if (doc.animateAll != _animating) {
      edits.onAnimateAll(_animating = doc.animateAll);
    }
    final live = doc.inGesture,
        changed = {
          for (final e in doc.numbers.entries)
            if (_seen[e.key] != e.value) e.key: e.value,
        };
    if (changed.isNotEmpty) {
      if (!live) _seen.addAll(changed);
      edits.onValues(changed, live: live);
    } else if (_live && !live) {
      edits.onDrop();
    }
    _live = live;
    for (final e in doc.keys.entries.toList()) {
      // While a drag is in progress nothing is settled; the key is reported when the drag ends.
      if (live || _seenKeys[e.key] == e.value) continue;
      _seenKeys[e.key] = e.value;
      edits.onKey(e.key, e.value);
    }
    final words = {
      if (!live) ..._liveWords,
      for (final e in doc.strings.entries)
        if (e.key != 'route' &&
            e.key != 'route.at' &&
            _seenWords[e.key] != e.value)
          e.key: e.value,
    };
    live ? _liveWords.addAll(words) : _liveWords.clear();
    if (edits.onFlags case final tell?) {
      final flags = {
        for (final e in doc.flags.entries)
          if ((_seenFlags[e.key] ?? e.key.endsWith('.open')) != e.value)
            // A card is open until it is folded, so its first fold is news too. Otherwise it would open again at the next read.
            e.key: e.value,
      };
      if (flags.isNotEmpty) {
        if (tell(flags)) {
          _seenFlags.addAll(flags);
        } else {
          for (final id in flags.keys) {
            doc.flags[id] = _seenFlags[id] ?? false;
          }
        }
      }
    }
    if (words.isEmpty) return;
    if (edits.onWords(words, live: live)) {
      _seenWords.addAll(words);
    } else {
      for (final id in words.keys) {
        _seenWords.containsKey(id)
            ? doc.strings[id] = _seenWords[id]!
            : doc.strings.remove(id);
      }
    }
  }

  /// Shows in [doc] the owner's [snapshot], which replaced [previous]. Switches are taken only from an owner that hears of them ([InspectorEdits.onFlags]).
  ///
  /// Returns true when something changed that no field watches, so the whole panel must be rebuilt to show it.
  bool show(
    InspectorValues doc,
    InspectorSnapshot snapshot,
    InspectorEdits edits, {
    required InspectorSnapshot previous,
  }) {
    var rebuild = false;
    // A caller that is told of changes owns the values. Whatever it did not take goes back to what it says as soon as no drag is in progress.
    // A value being dragged is never overwritten, even during playback.
    // Numbers and key marks are sent to the fields that show them; strings, flags, choices and the rest cause a full rebuild.
    if (!doc.inGesture) {
      // A value that no field watches changed, so rebuild to show it.
      if (doc.showAt(snapshot.numbers, const {})) rebuild = true;
      _seen.addAll(snapshot.numbers);
    }
    if (edits.onFlags != null) {
      if (snapshot.flags.entries.any((e) => doc.flags[e.key] != e.value)) {
        rebuild = true;
      }
      doc.flags.addAll(snapshot.flags);
      _seenFlags.addAll(snapshot.flags);
    }
    if (snapshot.words.entries.any((e) => doc.strings[e.key] != e.value)) {
      rebuild = true;
    }
    doc.strings.addAll(snapshot.words);
    _seenWords.addAll(snapshot.words);
    // Also cover the case where what is shown differs from the document. A key mark that was just pressed shows lit at once,
    // and an undo that removes the key leaves the document's marks as they were before the press, so only the shown one differs.
    if (!mapEquals(previous.keyMarks, snapshot.keyMarks) ||
        snapshot.keyMarks.entries.any((e) => doc.keys[e.key] != e.value)) {
      doc.showAt(const {}, snapshot.keyMarks);
      _seenKeys.addAll(snapshot.keyMarks);
    }
    if (snapshot.animating != _animating) {
      doc.animateAll = _animating = snapshot.animating;
      rebuild = true;
    }
    return rebuild;
  }

  /// Shows in [doc] the owner's values and key marks at a new time, unless a drag is in progress.
  ///
  /// Returns true when a value changed that no field watches, such as a choice, so the whole panel must be rebuilt to show it.
  bool showAt(
    InspectorValues doc,
    Map<String, double> values,
    Map<String, KeyframeState> marks,
  ) {
    // Never during a drag.
    if (doc.inGesture) return false;
    _seen.addAll(values);
    _seenKeys.addAll(marks);
    return doc.showAt(values, marks);
  }
}
