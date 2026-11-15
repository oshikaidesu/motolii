// The Fill card groups the gradient's own settings (Angle, Stretch, Past end) under the gradient, and shows them only
// while a gradient is chosen. The grouping is the engine's fold, not a list named in the UI: in the struct below those
// three sit under `// @advanced(Gradient)`, exactly as workspace/inspector_feed/cards.dart writes them from
// engine/document/values.h's fold="Gradient". Expected: with no gradient the three are hidden; with a gradient they
// show inline (the body draws them), and no empty "Gradient" fold row appears, since the body draws them itself.
// Needs no engine.
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/controls/parameter_tile.dart'
    show ParameterTile;
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_host.dart';
import 'package:motolii/inspector/inspector_panel.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/widgets/disclosure_triangle.dart'
    show DisclosureTriangle;

// Fill as workspace/inspector_feed/cards.dart writes it from engine/document/card_table.h and values.h: the gradient's
// Angle/Stretch/Past end carry fold="Gradient", so they come after an `// @advanced(Gradient)` marker.
const _fill = '''
struct Params {
  /// @label(Fill) @unit(colours)
  fill: vec3<f32>,
  /// @label(Gradient) @enum(linear, radial) @default(0)
  gradient: u32,
  /// @label(Stroke) @unit(colour)
  stroke: vec3<f32>,
  /// @label(Stroke width) @ui(bar) @range(0, 16) @unit(px) @default(0)
  stroke_width: f32,
  // @advanced(Gradient)
  /// @label(Angle) @ui(angle) @range(-180, 180) @unit(°) @default(0)
  gradient_angle: f32,
  /// @label(Stretch) @ui(bar) @range(0.1, 4) @unit(×) @default(1)
  gradient_scale: f32,
  /// @label(Past end) @enum(pad, reflect, repeat) @default(0)
  gradient_spread: u32,
}
''';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    Map<String, double> numbers = const {},
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
              title: 'Rectangle 1',
              cards: [
                CardDeclaration(
                  'Fill',
                  _fill,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
              ],
            ),
            snapshot: InspectorSnapshot(numbers: numbers),
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
  }

  testWidgets('with no gradient, the gradient settings are hidden', (
    tester,
  ) async {
    await mount(tester);
    expect(find.text('Angle'), findsNothing);
    expect(find.text('Stretch'), findsNothing);
    expect(find.text('Past end'), findsNothing);
  });

  testWidgets(
    'with a gradient, its settings show inline, with no empty fold row',
    (tester) async {
      await mount(tester, numbers: {'v_gradient': 1});
      // The body draws Angle/Stretch/Past end itself, directly under the gradient.
      expect(find.text('Angle'), findsOneWidget);
      expect(find.text('Stretch'), findsOneWidget);
      expect(find.text('Past end'), findsOneWidget);
      // They ride inline, not behind a collapsed "Gradient" fold. The only disclosure on the card is its own frame
      // (rows/section.dart); a stray empty "Gradient" fold row would add a second one.
      expect(find.byType(DisclosureTriangle), findsOneWidget);
    },
  );

  testWidgets('turning the gradient on shows three more parameter tiles', (
    tester,
  ) async {
    await mount(tester);
    final off = tester.widgetList(find.byType(ParameterTile)).length;
    await mount(tester, numbers: {'v_gradient': 1});
    final on = tester.widgetList(find.byType(ParameterTile)).length;
    expect(on, off + 3);
  });
}
