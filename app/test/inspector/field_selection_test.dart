// characterization: FieldSelection, the inspector's fields selected together: which fields a span takes and when the
// owner is called. The expected values are what the code gave when this was written, so a move that changes one fails
// here. What the selection does to the listeners of the values is in inspector_values_test.dart. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/inspector/field_selection.dart';

import '../main_tests_only.dart';

/// A selection over two cards, the first with five fields and the second with two, that counts its calls.
class _Fields {
  int rowsRead = 0, changed = 0;
  late final selection = FieldSelection(
    rows: () {
      rowsRead++;
      return [
        ['a', 'b', 'c', 'd', 'e'],
        ['p', 'q'],
      ];
    },
    onChanged: () => changed++,
  );
}

void main() {
  if (skipUnlessEveryTest()) return;
  test('starts empty, and reads the rows once, at the first pick', () {
    final f = _Fields();
    expect(f.selection.picked, isEmpty);
    expect(f.selection.isPicked('a'), isFalse);
    expect(f.rowsRead, 0);
    f.selection.pick('a');
    f.selection.pick('b');
    expect(f.rowsRead, 1);
  });

  test('one field picked alone is held but does not show, and the owner is not called', () {
    final f = _Fields();
    f.selection.pick('a');
    expect(f.selection.picked, {'a'});
    expect((f.selection.isPicked('a'), f.changed), (false, 0));
  });

  test('a span takes the rectangle from the field picked alone last to this one, one row per card', () {
    final f = _Fields();
    f.selection.pick('a');
    f.selection.pick('d', span: true);
    expect(f.selection.picked, {'a', 'b', 'c', 'd'});
    expect(
      (f.selection.isPicked('d'), f.selection.isPicked('e'), f.changed),
      (true, false, 1),
    );
    // Still from a: two columns of both rows.
    f.selection.pick('q', span: true);
    expect(f.selection.picked, {'a', 'b', 'p', 'q'});
    expect(f.changed, 2);
  });

  test('a span across cards stops at the end of a shorter row', () {
    final f = _Fields();
    f.selection.pick('e');
    f.selection.pick('p', span: true);
    expect(f.selection.picked, {'a', 'b', 'c', 'd', 'e', 'p', 'q'});
  });

  test('a span with no field picked first, or from or to a field that is in no row, picks that field alone', () {
    final f = _Fields();
    f.selection.pick('d', span: true);
    expect(f.selection.picked, {'d'});
    f.selection.pick('elsewhere', span: true);
    expect(f.selection.picked, {'elsewhere'});
    f.selection.pick('b', span: true);
    expect(f.selection.picked, {'b'});
    expect(f.changed, 0);
  });

  test('picking one field after several calls the owner, because a selection was showing', () {
    final f = _Fields();
    f.selection.pick('a');
    f.selection.pick('d', span: true);
    f.selection.pick('e');
    expect(f.selection.picked, {'e'});
    expect((f.selection.isPicked('e'), f.changed), (false, 2));
  });

  test('unpick clears and calls the owner, unless nothing was picked', () {
    final f = _Fields();
    f.selection.unpick();
    expect(f.changed, 0);
    f.selection.pick('a');
    f.selection.unpick();
    expect(f.selection.picked, isEmpty);
    expect(f.changed, 1);
  });

  test('the field a span starts from outlives unpick', () {
    final f = _Fields();
    f.selection.pick('a');
    f.selection.unpick();
    f.selection.pick('c', span: true);
    expect(f.selection.picked, {'a', 'b', 'c'});
  });
}
