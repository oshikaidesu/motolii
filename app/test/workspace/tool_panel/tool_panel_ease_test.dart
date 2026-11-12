// An easing as a value (Ease), its samples (easeAlong), and its text form in the document (said, heard). The expected
// values are what the code gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../main_tests_only.dart';

const _elastic = Ease(
  EaseKind.bezier,
  Offset.zero,
  Offset(1, 1),
  'Elastic 1 0.3',
);

void main() {
  if (skipUnlessEveryTest()) return;
  test('easeAlong reads between evenly spaced samples, and holds the ends outside 0 to 1', () {
    expect(easeAlong([0, 1], .25), .25);
    expect(easeAlong([0, 2, 0], .25), 1);
    expect(easeAlong([0, 2, 0], .75), 1);
    expect(easeAlong([3, 2, 5], -1), 3);
    expect(easeAlong([3, 2, 5], 2), 5);
  });

  group('Ease', () {
    test(
      'a bezier follows its two handles and holds its ends outside 0 to 1',
      () {
        final linear = easingPreset('Linear'), slowStart = easingPreset('In');
        expect(linear.at(.3), closeTo(.3, .002));
        expect(slowStart.at(.5), lessThan(.5));
        expect(
          (slowStart.at(-1), slowStart.at(0), slowStart.at(1), slowStart.at(2)),
          (0, 0, 1, 1),
        );
      },
    );

    test('a hold stays at 0 until the end', () {
      final hold = easingPreset('Hold');
      expect((hold.at(0), hold.at(.99), hold.at(1)), (0, 0, 1));
    });

    test('an easing with samples follows them, whatever its handles', () {
      const drawn = Ease(
        EaseKind.bezier,
        Offset.zero,
        Offset(1, 1),
        'Elastic 1 0.3',
        [0, 1.5, 1],
      );
      expect((drawn.at(.25), drawn.at(.5), drawn.at(1)), (.75, 1.5, 1));
    });

    test('two easings are equal by kind and handles, not by name', () {
      expect(
        const Ease(EaseKind.bezier, Offset.zero, Offset(1, 1)),
        easingPreset('Linear'),
      );
      expect(
        const Ease(EaseKind.hold, Offset.zero, Offset(1, 1)),
        isNot(easingPreset('Linear')),
      );
      expect(
        const Ease(EaseKind.bezier, Offset(.5, 0), Offset(1, 1)),
        isNot(easingPreset('Linear')),
      );
    });

    test('reversed swaps the handles through the centre and keeps the kind and the name', () {
      final back = const Ease(
        EaseKind.bezier,
        Offset(.25, 0),
        Offset(.5, 1),
        'Mine',
      ).reversed();
      expect(
        (back.kind, back.p1, back.p2, back.name),
        (EaseKind.bezier, const Offset(.5, 0), const Offset(.75, 1), 'Mine'),
      );
    });

    test('withHandles gives a nameless bezier', () {
      final e = easingPreset('Hold')
          .withHandles(const Offset(.1, .2), const Offset(.3, .4));
      expect(
        (e.kind, e.p1, e.p2, e.name),
        (EaseKind.bezier, const Offset(.1, .2), const Offset(.3, .4), null),
      );
    });
  });

  test('the tiles are found by name', () {
    expect(
      [for (final p in easingPresets) p.name],
      ['Linear', 'Ease', 'In', 'Out', 'In-out', 'Back', 'Hold'],
    );
    expect(easingPreset('Back').p1, const Offset(.34, 1.56));
    expect(() => easingPreset('No such tile'), throwsStateError);
  });

  test('easeOther is true for a named easing that has no tile', () {
    expect(easeOther(_elastic), isTrue);
    expect(easeOther(easingPreset('Back')), isFalse);
    expect(
      easeOther(const Ease(EaseKind.bezier, Offset(.1, .2), Offset(.3, .4))),
      isFalse,
    );
  });

  test('easeName is the name of the tile with the same handles, or the own name of an easing with no tile', () {
    expect(easeName(easingPreset('In-out')), 'In-out');
    expect(
      easeName(const Ease(EaseKind.bezier, Offset(.42, 0), Offset(1, 1))),
      'In',
    );
    expect(easeName(_elastic), 'Elastic 1 0.3');
    expect(
      easeName(const Ease(EaseKind.bezier, Offset(.1, .2), Offset(.3, .4))),
      isNull,
    );
  });

  test('said writes an easing as the document stores it', () {
    expect(said(easingPreset('Linear')), 'Linear');
    expect(said(easingPreset('Hold')), 'Hold');
    expect(said(easingPreset('Ease')), 'Bezier 0.25 0.1 0.25 1.0');
    expect(
      said(const Ease(EaseKind.bezier, Offset.zero, Offset(1, 1))),
      'Bezier 0.0 0.0 1.0 1.0',
    ); // Only the tile named Linear is written Linear.
    expect(said(_elastic), 'Elastic 1 0.3');
  });

  test('heard reads that text back, and keeps a kind it has no tile for by its text', () {
    expect(heard('Linear').name, 'Linear');
    expect(heard('Hold').kind, EaseKind.hold);
    final bezier = heard('Bezier 0.25 0.1 0.25 1');
    expect(
      (bezier.kind, bezier.p1, bezier.p2, bezier.name),
      (EaseKind.bezier, const Offset(.25, .1), const Offset(.25, 1), null),
    );
    for (final other in ['Elastic 1 0.3', 'Bezier 1 2']) {
      final e = heard(other);
      expect(
        (e.kind, e.p1, e.p2, e.name, e.drawn),
        (EaseKind.bezier, Offset.zero, const Offset(1, 1), other, null),
      );
    }
  });

  test('every tile comes back the same from its text', () {
    for (final p in easingPresets) {
      expect(heard(said(p)), p, reason: p.name);
    }
  });
}
