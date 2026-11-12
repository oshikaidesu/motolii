// The Trim Paths card holds a sample path whose part left after the trim is drawn bright, as it did before 52289b693
// (inspector_trim.dart), and is pulled to set the trim, as After Effects' Trim Paths Start, End and Offset do.
// Expected: taking the end knob back along the path cuts off the end (Trim end grows) and leaves the start; taking
// the start knob forward moves the start alone; taking the bright part slides the offset alone. Needs no engine.
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
import 'package:motolii/inspector/trim/trim_path.dart' show TrimView;

// Trim Paths as workspace/inspector_feed/cards.dart writes it from engine/document/values.h (shares shown in %).
const _trim = '''
struct Params {
  /// @label(Trim end) @ui(percent) @range(0, 100) @unit(%) @default(0)
  trim: f32,
  /// @label(Trim start) @ui(percent) @range(0, 100) @unit(%) @default(0)
  trim_begin: f32,
  /// @label(Trim offset) @ui(bipolar) @range(-100, 100) @unit(%) @default(0)
  trim_offset: f32,
}
''';

void main() {
  late List<Map<String, double>> told;

  Future<void> mount(
    WidgetTester tester, {
    Map<String, double> numbers = const {},
  }) async {
    told = [];
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
              kind: Kind.shape,
              title: 'Rectangle 1',
              cards: [
                CardDeclaration(
                  'Trim Paths',
                  _trim,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
              ],
            ),
            snapshot: InspectorSnapshot(numbers: numbers),
            actions: const CardActions(),
            edits: InspectorEdits(
              onValues: (changed, {required live}) => told.add(Map.of(changed)),
              onDrop: () {},
              onKey: (_, _) {},
              onWords: (_) => true,
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
  }

  Offset on(WidgetTester tester, double u, {double begin = 0, double end = 1}) {
    final box = find.byKey(const ValueKey('trim-path'));
    expect(box, findsOneWidget);
    return tester.getTopLeft(box) +
        TrimView(tester.getSize(box), begin: begin, end: end, slide: 0).at(u);
  }

  Map<String, double> last() => {for (final t in told) ...t};

  testWidgets(
    'taking the end knob back cuts off the end and leaves the start',
    (tester) async {
      await mount(tester);
      await tester.dragFrom(on(tester, 1), on(tester, .6) - on(tester, 1));
      await tester.pump();
      expect(last()['v_trim'], greaterThan(20));
      expect(last()['v_trim_begin'] ?? 0, 0);
    },
  );

  testWidgets('taking the start knob forward moves the start alone', (
    tester,
  ) async {
    await mount(tester);
    await tester.dragFrom(on(tester, 0), on(tester, .4) - on(tester, 0));
    await tester.pump();
    expect(last()['v_trim_begin'], greaterThan(20));
    expect(last()['v_trim'] ?? 0, 0);
  });

  testWidgets('taking the bright part slides the offset alone', (tester) async {
    await mount(tester, numbers: {'v_trim_begin': 20, 'v_trim': 50});
    final from = on(tester, .35, begin: .2, end: .5);
    await tester.dragFrom(from, on(tester, .5, begin: .2, end: .5) - from);
    await tester.pump();
    expect(last()['v_trim_offset'], greaterThan(5));
    expect(last().containsKey('v_trim_begin'), isFalse);
    expect(last().containsKey('v_trim'), isFalse);
  });
}
