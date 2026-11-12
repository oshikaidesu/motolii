// The Text card holds the layer's text in a box; letters selected there are what Size, Fill, Tracking, Baseline and
// the font's axes change, as After Effects' Character panel does for characters selected in a text layer and as CSS
// does for a span. Expected: a Size dragged with letters 1–2 of "Hello" selected writes one text_styles range
// "1 2 font-size: N%" (characters counted as After Effects' style.setFontSize(value, startIndex, numOfCharacters)
// counts them) and leaves the layer's Size alone; with nothing selected, Size is the layer's; the box shows a
// range's color. Needs no engine.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_host.dart';
import 'package:motolii/inspector/inspector_panel.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/widgets/text_gestures.dart' show wordsPicked;

// Text as workspace/inspector_feed/cards.dart writes it from engine/document/card_table.h and values.h.
const _text = '''
struct Params {
  /// @label(Text) @unit(words)
  text: vec3<f32>,
  /// @label(Styles) @unit(words)
  text_styles: vec3<f32>,
  /// @label(Font) @unit(file)
  file: vec3<f32>,
  /// @label(Size) @ui(bar) @range(0, 2) @unit(px) @default(0.08)
  size: f32,
  /// @label(Tracking) @ui(bipolar) @range(-100, 500) @unit() @default(0)
  letter_spacing: f32,
  /// @label(Line Height) @ui(bar) @range(0.5, 3) @unit(×) @default(1.2)
  line_spacing: f32,
}
''';

void main() {
  late List<Map<String, double>> numbers;
  late List<Map<String, String>> words;
  late List<bool> stylesLive;

  Future<void> mount(WidgetTester tester, {String styles = ''}) async {
    numbers = [];
    words = [];
    stylesLive = [];
    wordsPicked.value = null;
    tester.view.physicalSize = const Size(372, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final live =
        ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
          const {},
          const {},
        ));
    addTearDown(live.dispose);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(372, 900)),
          child: InspectorHost(
            layer: InspectedLayer(
              kind: Kind.text,
              title: 'Hello',
              cards: [
                CardDeclaration(
                  'Text',
                  _text,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
              ],
            ),
            snapshot: InspectorSnapshot(
              words: {'v_text': 'Hello', 'v_text_styles': styles},
            ),
            actions: const CardActions(),
            edits: InspectorEdits(
              onValues: (changed, {required live}) =>
                  numbers.add(Map.of(changed)),
              onDrop: () {},
              onKey: (_, _) {},
              onWords: (changed, {required live}) {
                words.add(Map.of(changed));
                if (changed.containsKey('v_text_styles')) stylesLive.add(live);
                return true;
              },
              onAnimateAll: (_) {},
              together: (tells) => tells(),
              onRoute: (_) {},
              onAim: (_) {},
            ),
            live: live,
            child: const InspectorPanel(width: 372, height: 900),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> dragSize(WidgetTester tester) async {
    final size = find.text('Size');
    expect(size, findsOneWidget);
    await tester.dragFrom(tester.getCenter(size), const Offset(40, 0));
    await tester.pump();
  }

  testWidgets(
    'with letters selected, Size writes a range for those letters only',
    (tester) async {
      await mount(tester);
      expect(find.byKey(const ValueKey('text:box')), findsOneWidget);
      wordsPicked.value = (text: 'Hello', start: 1, end: 3);
      await tester.pump();
      await dragSize(tester);
      final styles = words.lastWhere(
        (w) => w.containsKey('v_text_styles'),
      )['v_text_styles']!;
      final m = RegExp(r'^1 2 font-size: ([0-9.]+)%$').firstMatch(styles);
      expect(m, isNotNull, reason: styles);
      expect(double.parse(m![1]!), greaterThan(100));
      expect(numbers.any((n) => n.containsKey('v_size')), isFalse);
      // The stage follows the drag: its steps come live, and only the last one closes it (one undo step).
      expect(stylesLive.where((l) => l), isNotEmpty);
      expect(stylesLive.last, isFalse);
    },
  );

  testWidgets('with nothing selected, Size is the layer\'s', (tester) async {
    await mount(tester);
    await dragSize(tester);
    expect(numbers.any((n) => n.containsKey('v_size')), isTrue);
    expect(words.any((w) => w.containsKey('v_text_styles')), isFalse);
  });

  testWidgets('the box sets a range in its color', (tester) async {
    await mount(tester, styles: '1 2 color: #ff0000');
    final box = find.descendant(
      of: find.byKey(const ValueKey('text:box')),
      matching: find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == '_Editable',
      ),
    );
    final text = tester.renderObject<RenderEditable>(box).text!;
    final red = <String>[];
    text.visitChildren((span) {
      if (span is TextSpan &&
          span.text != null &&
          span.style?.color == const Color(0xffff0000)) {
        red.add(span.text!);
      }
      return true;
    });
    expect(red, ['el']);
  });

  testWidgets(
    'with letters selected, Font shows the font file their range names',
    (tester) async {
      await mount(tester, styles: "1 2 font-family: '/fonts/Range.ttf'");
      expect(find.textContaining('/fonts/Range.ttf'), findsNothing);
      wordsPicked.value = (text: 'Hello', start: 1, end: 3);
      await tester.pump();
      expect(find.textContaining('/fonts/Range.ttf'), findsOneWidget);
    },
  );
}
