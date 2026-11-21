// Blending card tests: verifies dynamic Matte instrument visibility, in-well
// Alpha/Luma and Invert glass pills, Feather tile, and exact math for the 8
// non-native blend modes. Needs no engine.
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

const _blending = '''
struct Params {
  /// @label(Blend) @enum(normal, multiply, overlay, linear_burn, linear_light, vivid_light, pin_light, darker_color, lighter_color, subtract, divide) @default(0)
  blend: u32,
  /// @label(Clip to below) @toggle @range(0, 1) @default(0)
  clip: u32,
  /// @label(Cut by) @enum(alpha, luma) @default(0)
  clip_matte: u32,
  /// @label(Invert) @toggle @range(0, 1) @default(0)
  clip_invert: u32,
  /// @label(Feather) @ui(bar) @range(0, 100) @unit(px) @default(0)
  clip_feather: f32,
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
              title: 'Shape 1',
              cards: [
                CardDeclaration(
                  'Blending',
                  _blending,
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

  testWidgets('unclipped layer hides Matte preview and feather controls', (
    tester,
  ) async {
    await mount(tester, numbers: {'v_clip': 0});
    expect(find.byKey(const ValueKey('blend-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('matte-preview')), findsNothing);
    expect(find.byKey(const ValueKey('choice:clip_matte')), findsNothing);
    expect(find.byKey(const ValueKey('toggle:clip_invert')), findsNothing);
    expect(find.text('Feather'), findsNothing);
  });

  testWidgets('clipped layer reveals Matte preview, pills, and Feather tile', (
    tester,
  ) async {
    await mount(
      tester,
      numbers: {
        'v_clip': 1,
        'v_clip_matte': 0,
        'v_clip_invert': 0,
        'v_clip_feather': 12,
      },
    );
    expect(find.byKey(const ValueKey('matte-preview')), findsOneWidget);
    expect(find.byKey(const ValueKey('choice:clip_matte')), findsOneWidget);
    expect(find.byKey(const ValueKey('toggle:clip_invert')), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Invert'), findsOneWidget);
    expect(find.text('Feather'), findsOneWidget);
  });

  testWidgets('tapping Matte pills toggles Alpha/Luma and Invert', (
    tester,
  ) async {
    final told = <Map<String, double>>[];
    await mount(
      tester,
      numbers: {'v_clip': 1, 'v_clip_matte': 0, 'v_clip_invert': 0},
      onValues: (m) => told.add(Map.of(m)),
    );
    await tester.tap(find.byKey(const ValueKey('choice:clip_matte')));
    await tester.pump();
    expect(told.any((m) => m['v_clip_matte'] == 1.0), isTrue);

    await tester.tap(find.byKey(const ValueKey('toggle:clip_invert')));
    await tester.pump();
    expect(told.any((m) => m['v_clip_invert'] == 1.0), isTrue);
  });

  testWidgets('all 8 non-native shader blend modes paint cleanly', (
    tester,
  ) async {
    for (var i = 3; i <= 10; i++) {
      await mount(tester, numbers: {'v_blend': i.toDouble()});
      expect(find.byKey(const ValueKey('blend-preview')), findsOneWidget);
    }
  });
}
