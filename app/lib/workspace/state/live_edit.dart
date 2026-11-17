// The one gesture gateway. Every continuous drag — carry or live writes — goes through here, so the undo step has one
// owner and Escape / pointer loss / dispose all have one cancel path.
//
// Carry: the engine holds values in memory, updates are coalesced and cheap, one commit at release. Used by the stage
// (move, resize, rotate, crop), bar drag/trim/slip and depth.
//
// Live writes: each step writes to SQLite and `show`s the result. Used by keyframe slide, Ease, colours, inspector
// words and the transform pad.
import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_writes.dart';

import 'package:motolii/workspace/state/workspace_controller.dart';

/// Writes into the document with [Motolii.later] and returns the layers it changed, to be shown at once.
typedef LiveWrites = Iterable<int> Function(Motolii m);

/// The gesture in progress (one at a time): [WorkspaceController.live].
class LiveEdit {
  LiveEdit(this.ws);
  final WorkspaceController ws;

  bool _open = false, _going = false, _carry = false;
  LiveWrites? _waiting;

  /// Whether a gesture's undo step is open.
  bool get isOpen => _open;

  // ---- carry ------------------------------------------------

  /// Begins a carry-style drag on [layer]. The engine holds values in memory; updates go through
  /// [Motolii.dragUpdate] as before. Calling again while already carrying the same layer is a no-op
  /// (the engine's doc_hold is idempotent for the same layer).
  void hold(int layer) {
    if (_carry) return;
    assert(!_open, 'A live-writes gesture is already open');
    ws.inside!.take(layer);
    _open = true;
    _carry = true;
  }

  /// Sends a value into the carry drag. [name] is the property name and [a] is its new value.
  void update(String name, double a, [double b = 0]) {
    assert(_carry, 'update is for carry gestures');
    ws.inside?.dragUpdate(name, a, b);
  }

  /// Ends the carry, keeping or discarding it. [then] hears the engine's answer.
  void letGo({bool keep = true, void Function(bool, String)? then}) {
    if (!_carry) return;
    _open = false;
    _carry = false;
    final m = ws.inside;
    if (m != null) ws.after(m.later('drag_end', number: keep ? 1 : 0), then);
  }

  // ---- live writes ------------------------------------------

  /// Writes [writes] into the gesture's undo step, opening it at the first move, and shows the result.
  void move(LiveWrites writes) {
    assert(!_carry, 'A carry gesture is open — use dragUpdate, not move');
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
    assert(!_carry, 'A carry gesture is open — use letGo, not done');
    final m = ws.inside;
    if (m == null) return;
    _waiting = null;
    if (!_open && last == null) return;
    if (!_open) m.later('together', number: 1);
    _open = false;
    last?.call(m);
    ws.after(m.later('together'), (done, why) => then?.call(done ? null : why));
  }

  // ---- common -----------------------------------------------

  /// Takes the whole gesture back — carry or live writes — and returns whether there was one.
  bool cancel() {
    final m = ws.inside;
    _waiting = null;
    if (!_open || m == null) return false;
    if (_carry) {
      _open = false;
      _carry = false;
      _going = false;
      ws.after(m.later('drag_end', number: 0));
      return true;
    }
    _open = false;
    _going = false;
    ws.after(m.later('together', number: -1));
    return true;
  }
}

extension on Set<int> {
  Iterable<int> ifEmpty(int t) => isEmpty ? [t] : this;
}
