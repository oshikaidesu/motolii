// Media card tests: verifies FilmStrip hosts the discrete Hold-at pill inside
// the well and cycles Start / Playhead / End, while leaving continuous values
// in the grid below. Needs no engine.
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

const _media = '''
struct Params {
  /// @label(In) @ui(bar) @range(0, 60) @unit(s) @default(12)
  begin: f32,
  /// @label(Speed) @ui(bipolar) @range(-4, 4) @unit(×) @default(1)
  speed: f32,
  /// @label(Hold at) @enum(start, playhead, end) @default(1)
  speed_hold: u32,
  /// @label(Frame rate) @ui(bar) @range(0, 60) @unit(fps) @default(24)
  frame_rate: f32,
  /// @label(Volume) @ui(percent) @range(0, 100) @unit(%) @default(100)
  volume: f32,
}
''';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    Map<String, double> numbers = const {},
    void Function(Map<String, double>)? onValues,
  }) async {
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
              title: 'Clip 1',
              cards: [
                CardDeclaration(
                  'Media',
                  _media,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
              ],
            ),
            snapshot: InspectorSnapshot(numbers: numbers),
            actions: const CardActions(),
            edits: InspectorEdits(
              onValues: (changed, {required live}) => onValues?.call(changed),
              onDrop: () {},
              onKey: (_, _) {},
              onWords: (_, {required live}) => true,
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

  testWidgets('FilmStrip hosts Hold-at pill inside well and cycles options', (
    tester,
  ) async {
    final told = <Map<String, double>>[];
    await mount(
      tester,
      numbers: {'v_begin': 18, 'v_speed': 1.5, 'v_speed_hold': 1},
      onValues: (m) => told.add(Map.of(m)),
    );
    expect(find.byKey(const ValueKey('film-strip')), findsOneWidget);
    final pill = find.byKey(const ValueKey('choice:speed_hold'));
    expect(pill, findsOneWidget);
    expect(find.text('Playhead'), findsOneWidget);
    // No separate "Hold at" segmented bar below.
    expect(find.text('Hold at'), findsNothing);

    await tester.tap(pill);
    await tester.pump();
    expect(told.any((m) => m['v_speed_hold'] == 2.0), isTrue);
  });
}
