// One gesture as one undo step that the stage and every panel follow while it lasts. The first move opens the step,
// each move is written into it and shown, letting go closes it, and cancelling (Escape, a lost pointer) takes it all
// back. The step is the engine's undo step, a SQLite transaction (begin, then commit or rollback), so the values in
// progress have one place and every panel reads them from there; `show` (engine/entry/calls_later.cpp) matches the
// stage again and reads the previews of the layers it names anew. While one move is on its way the next waits, and
// moves in between are skipped, since the newest says all. This is how the Ease tool already wrote its drags
// (ease_writer.dart); it is the one way now.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_writes.dart';

import 'package:motolii/workspace/state/workspace_controller.dart';

/// Writes into the document with [Motolii.later] and returns the layers it changed, to be shown at once.
typedef LiveWrites = Iterable<int> Function(Motolii m);

/// The gesture in progress (one at a time): [WorkspaceController.live].
class LiveEdit {
  LiveEdit(this.ws);
  final WorkspaceController ws;

  bool _open = false, _going = false;
  LiveWrites? _waiting;

  /// Whether a gesture's undo step is open.
  bool get isOpen => _open;

  /// Writes [writes] into the gesture's undo step, opening it at the first move, and shows the result.
  void move(LiveWrites writes) {
    final m = ws.inside;
    if (m == null) return;
    if (_going) {
      _waiting = writes;
      return;
    }
    if (!_open) {
      m.later('together', number: 1);
      _open = true;
    }
    _going = true;
    var shown = 0;
    for (final t in {...writes(m)}.ifEmpty(0)) {
      shown = m.later('show', layer: t);
    }
    ws.after(shown, (_, _) {
      _going = false;
      final next = _waiting;
      _waiting = null;
      if (next != null && _open) move(next);
    });
  }

  /// Ends the gesture with [last] written, if given, as one undo step; a change with no gesture before it is a step
  /// of its own. [then] hears why the step was refused, or null when it was kept.
  void done([LiveWrites? last, void Function(String? why)? then]) {
    final m = ws.inside;
    if (m == null) return;
    _waiting = null;
    if (!_open && last == null) return;
    if (!_open) m.later('together', number: 1);
    _open = false;
    last?.call(m);
    ws.after(m.later('together'), (done, why) => then?.call(done ? null : why));
  }

  /// Takes the whole gesture back, as SQLite's rollback does; the stage and the panels show the document as it was.
  /// Returns whether there was one to take back.
  bool cancel() {
    final m = ws.inside;
    _waiting = null;
    if (!_open || m == null) return false;
    _open = false;
    ws.after(m.later('together', number: -1));
    return true;
  }
}

extension on Set<int> {
  Iterable<int> ifEmpty(int t) => isEmpty ? [t] : this;
}
