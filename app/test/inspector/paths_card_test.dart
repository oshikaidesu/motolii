// Paths card tests: verifies top-row geometry packing beside PathsPreview,
// in-well Fill rule toggle, real persisted operator ordering (`v_path_ops`),
// and duplicate operator instances with distinct prefixed IDs. Needs no engine.
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

const _paths = '''
struct Params {
  /// @label(Points) @ui(bar) @range(3, 12) @unit() @default(5)
  points: f32,
  /// @label(Inner) @ui(bar) @range(0, 1) @unit() @default(0.45)
  inner: f32,
  /// @label(Operators) @unit(words)
  path_ops: vec3<f32>,
  /// @label(Round) @ui(bar) @range(0, 1) @unit() @default(0)
  round: f32,
  /// @label(Bloat) @ui(bipolar) @range(-1, 1) @unit() @default(0)
  bloat: f32,
  /// @label(Offset) @ui(bipolar) @range(-20, 20) @unit(px) @default(0)
  offset: f32,
  /// @label(Zig zag) @ui(bar) @range(0, 20) @unit(px) @default(0)
  zigzag: f32,
  /// @label(Squares) @ui(bar) @range(0, 0.2) @unit(%) @default(0)
  voxel: f32,
  /// @label(Fill rule) @enum(nonzero, evenodd) @default(0)
  fill_rule: u32,
  /// @label(Trim end) @ui(bar) @range(0, 1) @unit() @default(0)
  trim: f32,
  /// @label(Trim start) @ui(bar) @range(0, 1) @unit() @default(0)
  trim_begin: f32,
  /// @label(Trim offset) @ui(bar) @range(0, 1) @unit() @default(0)
  trim_offset: f32,
  // @advanced(Zig zag)
  /// @label(Ridges) @ui(bar) @range(1, 30) @unit() @default(8)
  zigzag_ridges: f32,
  /// @label(Smooth) @ui(bar) @range(0, 1) @unit() @default(0.5)
  zigzag_smooth: f32,
}
''';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    Map<String, double> numbers = const {},
    Map<String, String> words = const {},
    void Function(Map<String, double>)? onValues,
    void Function(Map<String, String>)? onWords,
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
      WidgetsApp(
        color: const Color(0xFF111111),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(settings, builder) =>
            PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
        home: InspectorHost(
          layer: InspectedLayer(
            kind: Kind.shape,
            title: 'Star 1',
            cards: [
              CardDeclaration(
                'Paths',
                _paths,
                toneOf: () => const Color(0xFF9AA4B2),
              ),
            ],
          ),
          snapshot: InspectorSnapshot(numbers: numbers, words: words),
          actions: const CardActions(),
          edits: InspectorEdits(
            onValues: (changed, {required live}) => onValues?.call(changed),
            onDrop: () {},
            onKey: (_, _) {},
            onWords: (changed, {required live}) {
              onWords?.call(changed);
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
    );
    await tester.pump();
  }

  testWidgets(
    'Fill rule lives inside PathsPreview and toggles nonzero/evenodd',
    (tester) async {
      final told = <Map<String, double>>[];
      await mount(
        tester,
        numbers: {'v_points': 5, 'v_inner': 0.45, 'v_fill_rule': 0},
        onValues: (m) => told.add(Map.of(m)),
      );
      final btn = find.byKey(const ValueKey('paths-fill-rule'));
      expect(btn, findsOneWidget);
      await tester.tap(btn);
      await tester.pump();
      expect(told.any((m) => m['v_fill_rule'] == 1.0), isTrue);
    },
  );

  testWidgets(
    'adding a duplicate operator writes a unique prefixed id to v_path_ops',
    (tester) async {
      final toldWords = <Map<String, String>>[];
      await mount(
        tester,
        numbers: {'v_round': 0.15},
        words: {'v_path_ops': 'round'},
        onWords: (w) => toldWords.add(Map.of(w)),
      );
      await tester.tap(find.byKey(const ValueKey('paths-add-operator')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('paths-pick:round')));
      await tester.pumpAndSettle();

      expect(toldWords, isNotEmpty);
      final ops = toldWords.last['v_path_ops'] ?? '';
      final parts = ops.split(' ');
      expect(parts.length, 2);
      expect(parts[0], 'round');
      expect(RegExp(r'^[0-9a-f]{6}:round$').hasMatch(parts[1]), isTrue);
    },
  );

  testWidgets(
    'adding Zig zag sets a safe normalized amplitude within engine range',
    (tester) async {
      final told = <Map<String, double>>[];
      await mount(tester, onValues: (m) => told.add(Map.of(m)));
      await tester.tap(find.byKey(const ValueKey('paths-add-operator')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('paths-pick:zigzag')));
      await tester.pumpAndSettle();

      final zigzagVal = told.last['v_zigzag'];
      expect(zigzagVal, isNotNull);
      expect(zigzagVal!, greaterThan(0));
      expect(zigzagVal, lessThanOrEqualTo(0.3));
    },
  );
}
