// Tests for timeline audio fade-in/out keyframe helpers, speed formatting, and
// the streamlined Audio inspector card (replacing the old Media FilmStrip card).
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
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/timeline/audio_fade.dart';
import 'package:motolii/workspace/timeline/timeline_speed.dart'
    show formatSpeed;

const _audio = '''
struct Params {
  /// @label(Volume) @ui(percent) @range(0, 200) @unit(%) @default(100)
  volume: f32,
  /// @label(Beats) @ui(bar) @range(0, 30) @unit(dB) @default(0)
  beats: f32,
}
''';

void main() {
  test('audio fade keyframes round-trip cleanly and clamp overlap', () {
    const fps = 30;
    final keys = buildAudioFadeKeys(
      inF: 30,
      outF: 150,
      fadeInF: 15,
      fadeOutF: 30,
      peak: 0.8,
      fps: fps,
    );
    expect(keys, [(1.0, 0.0), (1.5, 0.8), (4.0, 0.8), (5.0, 0.0)]);

    final layer = Layer(
      1,
      'Clip',
      LayerKind.audio,
      30,
      150,
      [30, 45, 120, 150],
      lanes: [
        Lane(
          name: 'volume',
          label: 'Volume',
          card: 'Audio',
          at: [for (final k in keys) k.$1],
          values: [for (final k in keys) k.$2],
          curves: const [],
        ),
      ],
    );
    final parsed = readAudioFade(layer, fps: fps);
    expect(parsed.fadeInF, 15);
    expect(parsed.fadeOutF, 30);
    expect(parsed.peak, closeTo(0.8, 1e-6));

    // Overlapping fades meet at one shared peak keyframe without duplicates.
    final meet = buildAudioFadeKeys(
      inF: 0,
      outF: 60,
      fadeInF: 40,
      fadeOutF: 50,
      peak: 1.0,
      fps: fps,
    );
    expect(meet, [(0.0, 0.0), (40 / 30, 1.0), (2.0, 0.0)]);

    // Clearing both fades produces no keyframes (returns to constant volume).
    expect(
      buildAudioFadeKeys(
        inF: 0,
        outF: 60,
        fadeInF: 0,
        fadeOutF: 0,
        peak: 1.0,
        fps: fps,
      ),
      isEmpty,
    );
  });

  test('formatSpeed prints compact multipliers', () {
    expect(formatSpeed(1.0), '1×');
    expect(formatSpeed(0.5), '0.5×');
    expect(formatSpeed(0.25), '0.25×');
    expect(formatSpeed(-1.5), '-1.5×');
  });

  testWidgets('Audio card renders Volume and Beats without a FilmStrip', (
    tester,
  ) async {
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
                  'Audio',
                  _audio,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
              ],
            ),
            snapshot: const InspectorSnapshot(
              numbers: {'v_volume': 85, 'v_beats': 6},
            ),
            actions: const CardActions(),
            edits: InspectorEdits(
              onValues: (_, {required live}) {},
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
    expect(find.text('Audio'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Beats'), findsOneWidget);
    expect(find.byKey(const ValueKey('film-strip')), findsNothing);
  });
}
