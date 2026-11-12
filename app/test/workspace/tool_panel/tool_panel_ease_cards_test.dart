// Stacked, reversed and pasted easings as text: what the document stores, what it must define first, and the curve
// the app draws for them. The expected values are what the code gave when this was written, so a move that changes one
// fails here. Every call here passes no engine (null), so an easing only the engine can draw keeps its straight line.
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../main_tests_only.dart';

Ease _named(String name, [List<double>? drawn]) =>
    Ease(EaseKind.bezier, Offset.zero, const Offset(1, 1), name, drawn);

void main() {
  if (skipUnlessEveryTest()) return;
  test('easeCards splits a stack into the text of each card, with the spaces put back', () {
    expect(easeCards('Linear'), ['Linear']);
    expect(easeCards('Bezier~0.42~0.0~1.0~1.0×Hold'), [
      'Bezier 0.42 0.0 1.0 1.0',
      'Hold',
    ]);
    // A reversed card and a card given by points stay one word.
    expect(easeCards('Reverse:Elastic~1~0.3×linear(0,0.5~25%,1)×Cyclic~2'), [
      'Reverse:Elastic~1~0.3',
      'linear(0,0.5~25%,1)',
      'Cyclic 2',
    ]);
  });

  test(
    'the three special forms are known by how the text begins or what it holds',
    () {
      expect((easeIsLaid('Hold×Linear'), easeIsLaid('Hold')), (true, false));
      expect(
        (easeIsPoints('linear(0,1)'), easeIsPoints('Linear')),
        (true, false),
      );
      expect(
        (easeIsTurned('Reverse:Hold'), easeIsTurned('Hold')),
        (true, false),
      );
    },
  );

  test('easeTurn writes an easing reversed as one word, and gives the original back from that word', () {
    expect(
      easeTurn('Bezier 0.42 0.0 1.0 1.0'),
      'Reverse:Bezier~0.42~0.0~1.0~1.0',
    );
    expect(
      easeTurn('Reverse:Bezier~0.42~0.0~1.0~1.0'),
      'Bezier 0.42 0.0 1.0 1.0',
    );
  });

  test('easeThrough is false for the cards that scale or add to the result above: Cyclic and Random, reversed or not', () {
    expect(easeThrough(easingPreset('Linear')), isTrue);
    expect(easeThrough(_named('Elastic 1 0.3')), isTrue);
    expect(easeThrough(_named('Cyclic 2')), isFalse);
    expect(easeThrough(_named('Random 3')), isFalse);
    expect(easeThrough(_named('Reverse:Cyclic~2')), isFalse);
  });

  group('easeDefines', () {
    test('a plain easing needs nothing defined', () {
      expect(easeDefines('Linear'), isEmpty);
      expect(easeDefines('Bezier 0.42 0.0 1.0 1.0'), isEmpty);
    });

    test('a reversed easing is defined as the original played backwards', () {
      expect(easeDefines('Reverse:Hold'), [
        ('Reverse:Hold', "a + (b - a) * (1 - way('Hold', 1 - u))"),
      ]);
    });

    test('an easing given by points is passed to anime.js, a stop with a position in quotes', () {
      expect(easeDefines('linear(0,0.5~25%,1)'), [
        (
          'linear(0,0.5~25%,1)',
          "a + (b - a) * anime('linear(0,\"0.5 25%\",1)', u)",
        ),
      ]);
    });

    test('a stack is defined card by card: through the result above, times it for Cyclic, added to it for Random', () {
      expect(easeDefines('Hold×Bezier~0.42~0.0~1.0~1.0'), [
        (
          'Hold×Bezier~0.42~0.0~1.0~1.0',
          "a + (b - a) * (way('Bezier 0.42 0.0 1.0 1.0', way('Hold', u)))",
        ),
      ]);
      expect(easeDefines('Linear×Cyclic~2×Random~3'), [
        (
          'Linear×Cyclic~2×Random~3',
          "a + (b - a) * (((way('Linear', u)) * way('Cyclic 2', u)) + way('Random 3', u) - u)",
        ),
      ]);
    });

    test('a stack defines its reversed cards first, and doubles a quote inside a name', () {
      expect(easeDefines("Reverse:Hold×Mine's"), [
        ('Reverse:Hold', "a + (b - a) * (1 - way('Hold', 1 - u))"),
        (
          "Reverse:Hold×Mine's",
          "a + (b - a) * (way('Mine''s', way('Reverse:Hold', u)))",
        ),
      ]);
    });
  });

  group('easeCard', () {
    test('a tile or a bezier is read from its text', () {
      expect(easeCard('Hold', null), easingPreset('Hold'));
      expect(easeCard('Bezier 0.42 0.0 1.0 1.0', null), easingPreset('In'));
    });

    test('with no engine, an easing that has no tile keeps its name and has no samples', () {
      final e = easeCard('Elastic 1 0.3', null);
      expect((e.name, e.drawn), ('Elastic 1 0.3', null));
    });

    test('a reversed card is sampled from the original played backwards', () {
      final slowStart = easingPreset('In'),
          turned = easeCard('Reverse:Bezier~0.42~0.0~1.0~1.0', null);
      expect(
        (turned.name, turned.drawn?.length),
        ('Reverse:Bezier~0.42~0.0~1.0~1.0', 193),
      );
      expect((turned.at(0), turned.at(1)), (0, 1));
      expect(turned.at(.25), closeTo(1 - slowStart.at(.75), 1e-9));
    });

    test('a stack is sampled as its cards laid one on another', () {
      final laid = easeCard('Hold×Linear', null);
      expect((laid.name, laid.drawn?.length), ('Hold×Linear', 193));
      expect((laid.at(0), laid.at(.5), laid.at(1)), (0, 0, 1));
    });
  });

  group('easeLaid', () {
    test('one card alone is that card', () {
      final one = easingPreset('In');
      expect(easeLaid([one]), same(one));
    });

    test('the stack is named by the text of its cards, each as one word', () {
      expect(
        easeLaid([easingPreset('In'), easingPreset('Hold')]).name,
        'Bezier~0.42~0.0~1.0~1.0×Hold',
      );
    });

    test('a card maps the result above it through itself', () {
      final first = easingPreset('In'),
          second = easingPreset('Out'),
          laid = easeLaid([first, second]);
      expect((laid.at(0), laid.at(1)), (0, 1));
      expect(laid.at(.5), closeTo(second.at(first.at(.5)), 1e-9));
    });

    test('a result outside 0 to 1 passes the next card unchanged, so an overshoot stays', () {
      final laid = easeLaid([
        _named('Elastic 1 0.3', [0, 1.5, 1]),
        easingPreset('Hold'),
      ]);
      expect(
        (laid.at(.25), laid.at(.5)),
        (0, 1.5),
      ); // At a quarter the result above is 0.75, which Hold turns to 0.
    });

    test('a Cyclic card scales the result above, and a Random card adds what it strays from the straight line', () {
      final linear = easingPreset('Linear');
      final scaled = easeLaid([
        linear,
        _named('Cyclic 2', [1, 0, 1]),
      ]);
      expect(scaled.at(.5), closeTo(0, 1e-9));
      expect(scaled.at(.25), closeTo(linear.at(.25) * .5, 1e-9));
      final added = easeLaid([
        linear,
        _named('Random 3', [0, 1, 1]),
      ]);
      expect(added.at(.5), closeTo(linear.at(.5) + 1 - .5, 1e-9));
    });
  });

  test('easeWord is the short name shown under the graph', () {
    expect(easeWord(easingPreset('Ease')), 'Ease');
    expect(
      easeWord(const Ease(EaseKind.bezier, Offset(.1, .2), Offset(.3, .4))),
      'Bezier',
    );
    expect(easeWord(_named('Elastic 1 0.3')), 'Elastic');
    expect(easeWord(_named('Reverse:Elastic~1~0.3')), 'Elastic');
    expect(easeWord(_named('linear(0,0.5~25%,1)')), 'linear()');
  });

  test('easeText writes a bezier as CSS cubic-bezier() and any other easing as the document stores it', () {
    expect(easeText(easingPreset('In')), 'cubic-bezier(0.42, 0.0, 1.0, 1.0)');
    expect(easeText(easingPreset('Linear')), 'Linear');
    expect(easeText(easingPreset('Hold')), 'Hold');
    expect(easeText(_named('Elastic 1 0.3')), 'Elastic 1 0.3');
  });

  group('easeFromText', () {
    test('finds a CSS cubic-bezier() anywhere in the text', () {
      expect(
        easeFromText('transition: all .3s cubic-bezier(0.42, 0, 1, 1);', null),
        easingPreset('In'),
      );
      expect(
        easeFromText(easeText(easingPreset('Back')), null),
        easingPreset('Back'),
      );
    });

    test('refuses a cubic-bezier() that is not four numbers, or whose x leaves 0 to 1', () {
      for (final text in [
        'cubic-bezier(0.1, 0.2, 0.3)',
        'cubic-bezier(a, 0, 1, 1)',
        'cubic-bezier(1.2, 0, 1, 1)',
        'cubic-bezier(0, 0, -0.1, 1)',
      ]) {
        expect(easeFromText(text, null), isNull, reason: text);
      }
    });

    test('reads a CSS linear() as an easing given by points, one word', () {
      expect(
        easeFromText(
          'animation-timing-function: linear(0, 0.5 25%, 1);',
          null,
        )?.name,
        'linear(0,0.5~25%,1)',
      );
      expect(easeFromText('linear(0)', null), isNull);
    });

    test(
      'reads the forms the document stores, and nothing from any other text',
      () {
        expect(easeFromText('  Hold ', null), easingPreset('Hold'));
        expect(easeFromText('Elastic 1 0.3', null)?.name, 'Elastic 1 0.3');
        expect(easeFromText('Reverse:Hold', null)?.name, 'Reverse:Hold');
        expect(easeFromText('Hold×Linear', null)?.name, 'Hold×Linear');
        expect(easeFromText('hello world', null), isNull);
        expect(easeFromText('', null), isNull);
        expect(easeFromText(null, null), isNull);
      },
    );
  });
}
