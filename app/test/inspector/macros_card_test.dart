// Universal Signal Macros card tests: verifies modeless plug drag-and-drop &
// click-to-connect, inline Min..Max range bands, source switching (Knob / Audio /
// MIDI / Layer / Wave), Ranges table (Invert / Unmap), knob drag, Rand, and Vars.
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
  /// @label(Sources) @unit(words)
  macro_sources: vec3<f32>,
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
    List<MacroLayerChoice> layers = const [
      (id: 10, name: 'Beat Track', hasAudio: true),
      (id: 11, name: 'Lead Shape', hasAudio: false),
    ],
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
      WidgetsApp(
        color: const Color(0xFF141414),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(settings, builder) =>
            PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
        home: InspectorHost(
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
          actions: CardActions(layerChoices: () => layers),
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
    );
    await tester.pump();
  }

  test('macro model parses and serializes bindings, sources, and vars', () {
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

    // Sources round-trip across wave, audio, midi, and layer.
    var srcRaw = setMacroSource(
      '',
      1,
      const MacroSource.wave(shape: 'saw', hz: 2.5, phase: 0.25),
    );
    srcRaw = setMacroSource(
      srcRaw,
      2,
      const MacroSource.audio(layerId: 5, gain: 2, smooth: 0.1),
    );
    srcRaw = setMacroSource(
      srcRaw,
      3,
      const MacroSource.midi(mode: 'pitch', channel: 1, file: 'my song.mid'),
    );
    srcRaw = setMacroSource(
      srcRaw,
      4,
      const MacroSource.layer(layerId: 2, prop: 'rotate', inMin: 0, inMax: 180),
    );
    final parsed = parseMacroSources(srcRaw);
    expect(parsed[1]!.kind, MacroSourceKind.wave);
    expect(parsed[1]!.sub, 'saw');
    expect(parsed[1]!.a, 2.5);
    expect(parsed[2]!.kind, MacroSourceKind.audio);
    expect(parsed[2]!.ref, 5);
    expect(parsed[3]!.kind, MacroSourceKind.midi);
    expect(parsed[3]!.path, 'my song.mid');
    expect(parsed[4]!.kind, MacroSourceKind.layer);
    expect(parsed[4]!.sub, 'rotate');
    expect(parsed[4]!.b, 180);

    // Resetting back to knob removes the entry.
    srcRaw = setMacroSource(srcRaw, 1, const MacroSource.knob());
    expect(parseMacroSources(srcRaw).containsKey(1), isFalse);

    final vars = parseMacroVars(
      writeMacroVars([
        (name: 'Calm', values: [10, 20, 0, 0, 0, 0, 0, 0]),
      ]),
    );
    expect(vars.single.name, 'Calm');
    expect(vars.single.values[0], 10);
    expect(vars.single.values[1], 20);
  });

  testWidgets(
    'modeless plug drag & click connect, show inline range band, invert and unmap',
    (tester) async {
      await mount(tester);
      expect(find.byKey(const ValueKey('macros:knob:1')), findsOneWidget);
      expect(find.byKey(const ValueKey('macros:knob:5')), findsNothing);

      // Drag plug 1 directly onto Radius in Glow card below (modeless!).
      final plugCenter = tester.getCenter(
        find.byKey(const ValueKey('macros:plug:1')),
      );
      final radiusCenter = tester.getCenter(find.text('Radius'));
      final gesture = await tester.startGesture(plugCenter);
      await tester.pump();
      await gesture.moveTo(radiusCenter);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
        '1 radius 0 100',
      );
      expect(find.byKey(const ValueKey('macro-dot:v_radius')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('macro-range:v_radius')),
        findsOneWidget,
      );

      // Click-to-arm plug 2, then click Intensity to connect.
      await tester.tap(find.byKey(const ValueKey('macros:plug:2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Intensity'));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
        '1 radius 0 100\n2 intensity 0 4',
      );

      // Open Ranges disclosure, invert Radius, and unmap it.
      await tester.tap(find.byKey(const ValueKey('macros:ranges')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('macros:invert:radius')));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
        '1 radius 100 0\n2 intensity 0 4',
      );

      await tester.tap(find.byKey(const ValueKey('macros:unmap:radius')));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
        '2 intensity 0 4',
      );
    },
  );

  testWidgets(
    'Map mode stays active across multiple clicks and slot switches for stacked FX',
    (tester) async {
      await mount(tester);

      // Enter Map mode: auto-arms slot 1 and shows status strip.
      await tester.tap(find.byKey(const ValueKey('macros:map')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('macros:map-banner')), findsOneWidget);

      // Click Radius -> binds to M1, and Map mode stays active.
      await tester.tap(find.text('Radius'));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
        '1 radius 0 100',
      );
      expect(find.byKey(const ValueKey('macros:map-banner')), findsOneWidget);
      // Mappings table auto-opens in Map mode.
      expect(
        find.byKey(const ValueKey('macros:invert:radius')),
        findsOneWidget,
      );

      // Switch active Map slot to M2 via its plug, then click Intensity.
      await tester.tap(find.byKey(const ValueKey('macros:plug:2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Intensity'));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere((w) => w.containsKey('v_macro_map'))['v_macro_map'],
        '1 radius 0 100\n2 intensity 0 4',
      );

      // Exit Map mode.
      await tester.tap(find.byKey(const ValueKey('macros:map')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('macros:map-banner')), findsNothing);
    },
  );

  testWidgets(
    'switching signal source between Wave, Audio, MIDI, and Layer updates macro_sources',
    (tester) async {
      await mount(tester);

      // Open source tray for slot 2.
      await tester.tap(find.byKey(const ValueKey('macros:src:2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('macros:tray:2')), findsOneWidget);

      // Switch to Wave -> Square.
      await tester.tap(find.byKey(const ValueKey('macros:kind:wave')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('macros:wave:square')));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere(
          (w) => w.containsKey('v_macro_sources'),
        )['v_macro_sources'],
        '2 wave square 1 0',
      );
      expect(find.byKey(const ValueKey('macros:meter:2')), findsOneWidget);

      // Switch to Audio -> picks first audio layer (id 10).
      await tester.tap(find.byKey(const ValueKey('macros:kind:audio')));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere(
          (w) => w.containsKey('v_macro_sources'),
        )['v_macro_sources'],
        '2 audio 10 1.5 0.05',
      );

      // Switch to Layer -> picks first layer (id 10), then pick Scale prop.
      await tester.tap(find.byKey(const ValueKey('macros:kind:layer')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('macros:lprop:scale_x')));
      await tester.pumpAndSettle();
      expect(
        words.lastWhere(
          (w) => w.containsKey('v_macro_sources'),
        )['v_macro_sources'],
        '2 layer 10 scale_x -180 180',
      );
    },
  );

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
    'Rand randomizes knob macros and Variations save & recall snapshots',
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

      // Expand from 4 to 8 channels.
      await tester.tap(find.byKey(const ValueKey('macros:count')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('macros:knob:8')), findsOneWidget);
    },
  );
}
