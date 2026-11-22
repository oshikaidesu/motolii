// Ableton-style Macros card tests: verifies rotary knob dragging, Map mode
// (clicking a parameter below + clicking Map on a knob), Min/Max/Invert/Unmap,
// Rand, Macro Variations save/recall, and live value mirroring on mapped fields.
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
import 'package:motolii/inspector/macros/macro_model.dart';

const _macros = '''
struct Params {
  /// @label(Macro 1) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_1: f32,
  /// @label(Macro 2) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_2: f32,
  /// @label(Macro 3) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_3: f32,
  /// @label(Macro 4) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_4: f32,
  /// @label(Macro 5) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_5: f32,
  /// @label(Macro 6) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_6: f32,
  /// @label(Macro 7) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_7: f32,
  /// @label(Macro 8) @ui(percent) @range(0, 100) @unit(%) @default(0)
  macro_8: f32,
  /// @label(Mappings) @unit(words)
  macro_map: vec3<f32>,
  /// @label(Names) @unit(words)
  macro_names: vec3<f32>,
  /// @label(Variations) @unit(words)
  macro_vars: vec3<f32>,
}
''';

const _glow = '''
struct Params {
  /// @label(Radius) @ui(bar) @range(0, 100) @unit(px) @default(20)
  radius: f32,
  /// @label(Intensity) @ui(bar) @range(0, 4) @unit(×) @default(1)
  intensity: f32,
}
''';

void main() {
  late List<Map<String, double>> numbers;
  late List<Map<String, String>> words;

  Future<void> mount(
    WidgetTester tester, {
    Map<String, double> initialNumbers = const {},
    Map<String, String> initialWords = const {},
    Map<String, bool> initialFlags = const {},
  }) async {
    numbers = [];
    words = [];
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
              title: 'Shape',
              cards: [
                CardDeclaration(
                  'Macros',
                  _macros,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
                CardDeclaration(
                  'Glow',
                  _glow,
                  toneOf: () => const Color(0xFF9AA4B2),
                ),
              ],
            ),
            snapshot: InspectorSnapshot(
              numbers: initialNumbers,
              words: initialWords,
              flags: initialFlags,
            ),
            actions: const CardActions(),
            edits: InspectorEdits(
              onValues: (changed, {required live}) =>
                  numbers.add(Map.of(changed)),
              onDrop: () {},
              onKey: (_, _) {},
              onWords: (changed, {required live}) {
                words.add(Map.of(changed));
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

  test('macro model parses, upserts, inverts, and serializes cleanly', () {
    var raw = upsertMacroBinding('', (
      slot: 1,
      prop: 'rotate',
      min: -45,
      max: 45,
    ));
    raw = upsertMacroBinding(raw, (
      slot: 1,
      prop: 'scale_x',
      min: 0.5,
      max: 1.5,
    ));
    expect(parseMacroMap(raw).length, 2);
    expect(nextFreeMacroSlot(raw), 2);

    raw = invertMacroBinding(raw, 'rotate');
    final rot = macroBindingOf(raw, 'rotate')!;
    expect(rot.min, 45);
    expect(rot.max, -45);

    raw = removeMacroBinding(raw, 'scale_x');
    expect(parseMacroMap(raw).length, 1);

    final vars = parseMacroVars(
      writeMacroVars([
        (name: 'Calm', values: [10, 20, 0, 0, 0, 0, 0, 0]),
      ]),
    );
    expect(vars.single.name, 'Calm');
    expect(vars.single.values[0], 10);
    expect(vars.single.values[1], 20);
  });

  testWidgets('Ableton Map mode binds a parameter, inverts range, and unmaps', (
    tester,
  ) async {
    await mount(tester);
    expect(find.byKey(const ValueKey('macros:knob:1')), findsOneWidget);
    expect(find.byKey(const ValueKey('macros:knob:5')), findsNothing);

    // Toggle Map mode on.
    await tester.tap(find.byKey(const ValueKey('macros:map')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('macros:map-banner')), findsOneWidget);
    expect(find.byKey(const ValueKey('macros:bind:1')), findsOneWidget);

    // Click Radius in the Glow card below, then click Map on Macro 1.
    await tester.tap(find.text('Radius'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Glow · Radius'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('macros:bind:1')));
    await tester.pumpAndSettle();
    final mapped = words.lastWhere(
      (w) => w.containsKey('v_macro_map'),
    )['v_macro_map']!;
    expect(mapped, '1 radius 0 100');
    expect(find.byKey(const ValueKey('macro-dot:v_radius')), findsOneWidget);

    // Invert range swaps Min and Max.
    await tester.tap(find.byKey(const ValueKey('macros:invert:radius')));
    await tester.pumpAndSettle();
    expect(
      words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
      '1 radius 100 0',
    );

    // Unmap clears the binding.
    await tester.tap(find.byKey(const ValueKey('macros:unmap:radius')));
    await tester.pumpAndSettle();
    expect(
      words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
      '',
    );
  });

  testWidgets(
    'dragging Macro 1 knob updates macro_1 and live-mirrors mapped field',
    (tester) async {
      await mount(
        tester,
        initialNumbers: const {'v_macro_1': 0, 'v_radius': 20},
        initialWords: const {'v_macro_map': '1 radius 0 100'},
      );
      await tester.drag(
        find.byKey(const ValueKey('macros:knob:1')),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      final last = numbers.lastWhere((m) => m.containsKey('v_macro_1'));
      expect(last['v_macro_1']!, greaterThan(30));
    },
  );

  testWidgets(
    'Rand randomizes mapped knobs and Variations save & recall snapshots',
    (tester) async {
      await mount(
        tester,
        initialNumbers: const {'v_macro_1': 70, 'v_macro_2': 25},
        initialWords: const {'v_macro_map': '1 radius 0 100\n2 intensity 0 4'},
      );

      // Open Variations and save current state.
      await tester.tap(find.byKey(const ValueKey('macros:vars')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('macros:var:new')));
      await tester.pumpAndSettle();
      final saved = words.lastWhere(
        (w) => w.containsKey('v_macro_vars'),
      )['v_macro_vars']!;
      expect(saved, contains('Var 1\t70,25,'));

      // Randomize mapped knob, then recall Var 1 back to 70%.
      await tester.tap(find.byKey(const ValueKey('macros:rand')));
      await tester.pumpAndSettle();
      expect(numbers.any((m) => m.containsKey('v_macro_1')), isTrue);

      await tester.tap(find.byKey(const ValueKey('macros:var:0')));
      await tester.pumpAndSettle();
      expect(numbers.last['v_macro_1'], 70.0);
      expect(numbers.last['v_macro_2'], 25.0);

      // Expand from 4 to 8 knobs.
      await tester.tap(find.byKey(const ValueKey('macros:count')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('macros:knob:8')), findsOneWidget);
    },
  );
}
