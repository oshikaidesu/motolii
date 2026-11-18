// SnapshotWatch records a take of the snapshots only when its three parts together are over the budget, as rule 10
// of docs/app/BRIDGE.md asks. The expected values follow that rule and the line format written beside the class.
import 'package:motolii/bridge/snapshot_watch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const budget = SnapshotWatch.budget;
  final at = DateTime(2026, 11, 18, 9, 5, 7, 42);

  test('a take at the budget is not recorded', () {
    final watch = SnapshotWatch()..took(budget - 2, 1, 1, at: at);
    expect(watch.count, 0);
    expect(watch.lines, isEmpty);
  });

  test('the parts are added: none alone is over, together they are', () {
    final watch = SnapshotWatch()..took(budget - 2, 2, 1, at: at);
    expect(watch.count, 1);
    expect(watch.lines, hasLength(1));
  });

  test('each part alone can go over the budget', () {
    final watch = SnapshotWatch()
      ..took(budget + 1, 0, 0, at: at)
      ..took(0, budget + 1, 0, at: at)
      ..took(0, 0, budget + 1, at: at);
    expect(watch.count, 3);
  });

  test('the line starts with the clock time and names each part in ms', () {
    final watch = SnapshotWatch()..took(budget + 500, 250, 1250, at: at);
    final all = ((budget + 2000) / 1000).toStringAsFixed(1),
        document = ((budget + 500) / 1000).toStringAsFixed(1);
    expect(
      watch.lines.single,
      startsWith(
        '09:05:07.042 the window\'s take of the snapshots $all ms '
        '(document $document, time 0.3, listener 1.3)',
      ),
    );
  });

  test('only the last 200 lines are kept, the count goes on', () {
    final watch = SnapshotWatch();
    for (var i = 0; i < 205; i++) {
      watch.took(budget + 1, 0, 0, at: at.add(Duration(seconds: i)));
    }
    expect(watch.count, 205);
    expect(watch.lines, hasLength(200));
    expect(watch.lines.first, startsWith('09:05:12.042 '));
    expect(watch.lines.last, startsWith('09:08:31.042 '));
  });
}
