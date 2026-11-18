// Records each take of the engine's snapshots that held the app's thread past its budget (docs/app/BRIDGE.md rule 10).
import 'package:flutter/foundation.dart' show kDebugMode;

class SnapshotWatch {
  /// Microseconds one take may hold the app's thread: the engine's own limit for a read (motolii_broken), tripled in
  /// a debug build as the top bar's frame budget is.
  static const budget = 2000 * (kDebugMode ? 3 : 1);

  int count = 0;

  /// The last 200, each starting with its clock time (hh:mm:ss.mmm) so they sort among the engine's own lines.
  final lines = <String>[];

  /// Records one take if it was over [budget]. Each part is in microseconds: reading the document snapshot, reading
  /// the time snapshot, and the listener's own work.
  void took(int document, int moment, int listener, {DateTime? at}) {
    final all = document + moment + listener;
    if (all <= budget) return;
    final t = at ?? DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    String ms(int us) => (us / 1000).toStringAsFixed(1);
    lines.add(
      '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${t.millisecond.toString().padLeft(3, '0')} '
      "the window's take of the snapshots ${ms(all)} ms "
      '(document ${ms(document)}, time ${ms(moment)}, listener ${ms(listener)})'
      '${kDebugMode ? ', a debug build: slower than the app' : ''}',
    );
    if (lines.length > 200) lines.removeAt(0);
    count++;
  }
}
