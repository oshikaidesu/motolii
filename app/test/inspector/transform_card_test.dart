// The Transform card holds a small preview of the layer that is pulled to edit it, as it did before 52289b693
// (the author, 2026-11-12: "トランスフォームはちっさなプレビューがあってそのままさわれたはずなんだ").
// Expected: dragging the box to the right moves Position X right and leaves Y; the rows sit under one X / Y / Z
// heading; a value the inside does not draw is still on the card. Needs no engine.
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

// Transform as workspace/inspector_feed/cards.dart writes it from engine/document/card_table.h, plus one value the
// inside does not draw (Wobble).
const _transform = '''
struct Params {
  /// @label(Space) @enum(2d, 2.5d, 3d) @default(0)
  space: u32,
  /// @label(Parent) @enum(None, Title) @default(0)
  parent: u32,
  /// @label(Position X) @ui(bipolar) @range(-3840, 3840) @unit(px) @default(960)
  x: f32,
  /// @label(Position Y) @ui(bipolar) @range(-2160, 2160) @unit(px) @default(540)
  y: f32,
  /// @label(Position Z) @ui(bipolar) @range(-5000, 5000) @unit(px) @default(0)
  z: f32,
  /// @label(Scale X) @ui(bar) @range(0, 400) @unit(%) @default(100)
  scale_x: f32,
  /// @label(Scale Y) @ui(bar) @range(0, 400) @unit(%) @default(100)
  scale_y: f32,
  /// @label(Rotation) @ui(angle) @range(-360, 360) @unit(°) @default(0)
  rotate: f32,
  /// @label(Opacity) @ui(percent) @range(0, 100) @unit(%) @default(100)
  opacity: f32,
  /// @label(Wobble) @ui(bar) @range(0, 10) @unit() @default(2)
  wobble: f32,
  // @advanced(Anchor)
  /// @label(Anchor X) @ui(bar) @range(0, 100) @unit(%) @default(50)
  anchor_x: f32,
  /// @label(Anchor Y) @ui(bar) @range(0, 100) @unit(%) @default(50)
  anchor_y: f32,
}
''';

void main() {
  late List<Map<String, double>> told;

  Future<void> mount(WidgetTester tester) async {
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
                  'Transform',
                  _transform,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
              ],
            ),
            snapshot: const InspectorSnapshot(),
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

  testWidgets(
    'dragging the box on the preview to the right moves Position X right and leaves Y',
    (tester) async {
      await mount(tester);
      final preview = find.byKey(const ValueKey('transform-preview'));
      expect(preview, findsOneWidget);
      // At first the layer stands in the middle of the preview, its anchor ring at the very middle; the box is grabbed
      // away from the ring.
      await tester.dragFrom(
        tester.getCenter(preview) + const Offset(-18, 10),
        const Offset(30, 0),
      );
      await tester.pump();
      final last = told.lastWhere((t) => t.containsKey('v_x'));
      expect(last['v_x']!, greaterThan(960));
      expect(last['v_y'] ?? 540, 540);
    },
  );

  testWidgets(
    'Position, Scale and Rotation sit under one X / Y / Z heading, and Wobble stays on the card',
    (tester) async {
      await mount(tester);
      for (final row in [
        'Position',
        'Scale',
        'Rotation',
        'Opacity',
        'Parent',
        'X',
        'Y',
        'Z',
      ]) {
        expect(find.text(row), findsOneWidget, reason: row);
      }
      for (final id in [
        'v_x',
        'v_y',
        'v_z',
        'v_scale_x',
        'v_scale_y',
        'v_rotate',
      ]) {
        expect(
          find.byKey(ValueKey('transform:$id')),
          findsOneWidget,
          reason: id,
        );
      }
      expect(find.text('Wobble'), findsOneWidget);
    },
  );

  testWidgets('while the box is dragged, the Position X field follows it', (
    tester,
  ) async {
    await mount(tester);
    final preview = find.byKey(const ValueKey('transform-preview'));
    final g = await tester.startGesture(
      tester.getCenter(preview) + const Offset(-18, 10),
    );
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    final x = find.byKey(const ValueKey('transform:v_x'));
    expect(find.descendant(of: x, matching: find.text('960')), findsNothing);
    await g.up();
  });
}
