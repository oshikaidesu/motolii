// Unit & widget tests for WebView-less JS Custom Panels (panel_node + panel_renderer).
import 'dart:convert';

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
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/custom_ui/panel_node.dart';
import 'package:motolii/widgets/custom_ui/panel_renderer.dart';

void main() {
  test('parses panel list, render tree, and action ops cleanly', () {
    final list = parsePanelList(
      'Stagger\t/tmp/Stagger.js\tSequence layers\tSelection\tlayout\n'
      'Quick Rig\t/tmp/Quick Rig.js\tAnchor & macros\tLayer\tplace\n',
    );
    expect(list.length, 2);
    expect(list.first.name, 'Stagger');
    expect(list.first.tone, 'layout');
    expect(list.last.acts, 'Layer');

    final render = parsePanelRenderResponse(
      jsonEncode({
        'ok': true,
        'ui': {
          'type': 'column',
          'children': [
            {'type': 'badge', 'text': '3 layers', 'tone': 'accent'},
            {
              'type': 'number',
              'id': 'step',
              'label': 'Step',
              'value': 4,
              'min': 1,
              'max': 60,
              'unit': 'f',
            },
            {
              'type': 'button',
              'id': 'stagger',
              'label': 'Stagger',
              'accent': true,
            },
          ],
        },
      }),
    );
    expect(render.error, isNull);
    expect(render.root!.type, 'column');
    expect(render.root!.children.length, 3);
    expect(render.root!.children[1].unit, 'f');

    final act = parsePanelActionResponse(
      jsonEncode({
        'ok': true,
        'result': {
          'notice': 'Staggered 2 layers',
          'state': {'step': 6},
          'ops': [
            {'op': 'set', 'layer': 1, 'name': 'start', 'value': 0.0},
            {'op': 'set', 'layer': 2, 'name': 'start', 'value': 0.1},
          ],
        },
      }),
    );
    expect(act.error, isNull);
    expect(act.notice, 'Staggered 2 layers');
    expect(act.state?['step'], 6);
    expect(act.ops.length, 2);
    expect(act.ops.last.value, 0.1);
  });

  testWidgets(
    'PanelTreeView renders controls natively and dispatches actions',
    (tester) async {
      final fired = <(String, Object?, bool)>[];
      final tree = PanelNode.fromJson({
        'type': 'column',
        'children': [
          {
            'type': 'row',
            'children': [
              {'type': 'badge', 'text': '2 layers', 'tone': 'accent'},
              {
                'type': 'button',
                'id': 'stagger',
                'label': 'Stagger',
                'accent': true,
              },
            ],
          },
          {
            'type': 'select',
            'id': 'order',
            'label': 'Order',
            'value': 'top',
            'options': ['top', 'bottom', 'random'],
          },
          {
            'type': 'toggle',
            'id': 'fromPlayhead',
            'label': 'Start at playhead',
            'value': true,
          },
          {
            'type': 'xy',
            'id': 'anchor',
            'label': 'Anchor',
            'x': 0,
            'y': 0,
            'min': -1,
            'max': 1,
            'snap9': true,
          },
          {
            'type': 'grid',
            'cols': 3,
            'children': [
              {
                'type': 'swatch',
                'id': 'fill:#59C3E8',
                'color': '#59C3E8',
                'active': true,
              },
              {'type': 'swatch', 'id': 'fill:#FF5A79', 'color': '#FF5A79'},
              {'type': 'swatch', 'id': 'fill:#FFB84D', 'color': '#FFB84D'},
            ],
          },
        ],
      })!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            color: Grey.g10,
            padding: const EdgeInsets.all(10),
            child: PanelTreeView(
              node: tree,
              onAction: (id, value, {live = false}) =>
                  fired.add((id, value, live)),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('panel:btn:stagger')));
      await tester.tap(find.byKey(const ValueKey('panel:opt:order:random')));
      await tester.tap(find.byKey(const ValueKey('panel:toggle:fromPlayhead')));
      await tester.tap(find.byKey(const ValueKey('panel:swatch:fill:#FF5A79')));

      // Tap top-left corner of the 9-point XY pad -> snaps to (-1, -1).
      final padRect = tester.getRect(
        find.byKey(const ValueKey('panel:xy:anchor')),
      );
      await tester.tapAt(padRect.topLeft + const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(fired[0], ('stagger', true, false));
      expect(fired[1], ('order', 'random', false));
      expect(fired[2], ('fromPlayhead', false, false));
      expect(fired[3], ('fill:#FF5A79', '#FF5A79', false));
      expect(fired[4].$1, 'anchor');
      expect(fired[4].$2, {'x': -1.0, 'y': -1.0});
    },
  );

  testWidgets(
    'Inspector ValuesCard mounts sidecar CustomCardBody, hides declared params, and writes back to prefixed doc ids',
    (tester) async {
      final writes = <Map<String, double>>[];
      const diagBlur = '''
struct Params {
  /// @label(Width) @ui(bar) @range(0, 1) @default(0.25)
  js_diagonal_blur_width: f32,
  /// @label(Angle) @ui(bar) @range(-1, 1) @default(0)
  js_diagonal_blur_angle: f32,
  /// @label(Quality) @enum(Low, Mid, High, Best) @default(2)
  js_diagonal_blur_quality: u32,
}
''';
      final live =
          ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
            const {},
            const {},
          ));
      addTearDown(live.dispose);
      tester.view.physicalSize = const Size(360, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        WidgetsApp(
          color: Grey.g07,
          debugShowCheckedModeBanner: false,
          pageRouteBuilder: <T>(settings, builder) =>
              PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
          home: InspectorHost(
            layer: InspectedLayer(
              kind: Kind.shape,
              title: 'Shape',
              cards: [
                CardDeclaration(
                  'Diagonal Blur',
                  diagBlur,
                  toneOf: () => Grey.g76,
                ),
              ],
            ),
            snapshot: const InspectorSnapshot(
              numbers: {
                'v_js_diagonal_blur_width': 0.25,
                'v_js_diagonal_blur_angle': 0.0,
                'v_js_diagonal_blur_quality': 2,
              },
            ),
            actions: CardActions(
              cardCustomUi: (title, names) => title == 'Diagonal Blur'
                  ? (
                      uiFile: 'Diagonal Blur.ui.js',
                      render: (_) => jsonEncode({
                        'ok': true,
                        'ui': {
                          'hide': ['width', 'angle'],
                          'ui': {
                            'type': 'column',
                            'children': [
                              {
                                'type': 'xy',
                                'id': 'vector',
                                'label': 'Blur Vector',
                                'x': 0.25,
                                'y': 0.0,
                                'min': -1,
                                'max': 1,
                              },
                              {
                                'type': 'button',
                                'id': 'preset:v',
                                'label': 'Vert',
                              },
                            ],
                          },
                        },
                      }),
                      action: (actJson, _) {
                        final act = jsonDecode(actJson) as Map;
                        if (act['id'] == 'preset:v') {
                          return jsonEncode({
                            'ok': true,
                            'result': {
                              'set': {'width': 0.4, 'angle': 0.5},
                            },
                          });
                        }
                        return '{"ok":true,"result":{}}';
                      },
                      liveSignal: null,
                    )
                  : null,
            ),
            edits: InspectorEdits(
              onValues: (changed, {required live}) =>
                  writes.add(Map.of(changed)),
              onDrop: () {},
              onKey: (_, _) {},
              onWords: (_, {required live}) => true,
              onAnimateAll: (_) {},
              together: (tells) => tells(),
              onRoute: (_) {},
              onAim: (_) {},
            ),
            live: live,
            child: const InspectorPanel(width: 360, height: 500),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Custom UI renders Blur Vector pad + Vert preset, tucks raw Width/Angle
      // inside the collapsible `Parameters` fold, and keeps Quality visible.
      expect(find.text('Blur Vector'), findsOneWidget);
      expect(find.text('Quality'), findsOneWidget);
      expect(find.text('Width'), findsNothing);
      expect(find.text('Angle'), findsNothing);
      expect(
        find.byKey(const ValueKey('card-params:Diagonal Blur')),
        findsOneWidget,
      );

      // Opening `Parameters` reveals Width & Angle for keyframes / Macro plugs.
      await tester.tap(find.byKey(const ValueKey('card-params:Diagonal Blur')));
      await tester.pumpAndSettle();
      expect(find.text('Width'), findsOneWidget);
      expect(find.text('Angle'), findsOneWidget);

      // Clicking Vert preset writes back to real prefixed doc params.
      await tester.tap(find.byKey(const ValueKey('panel:btn:preset:v')));
      await tester.pumpAndSettle();
      expect(writes.last['v_js_diagonal_blur_width'], 0.4);
      expect(writes.last['v_js_diagonal_blur_angle'], 0.5);
    },
  );

  testWidgets(
    'ui.canvas renders vector primitives and reports normalized pointer events',
    (tester) async {
      final events = <(String, Object?, bool)>[];
      final node = PanelNode.fromJson({
        'type': 'canvas',
        'id': 'curve',
        'label': 'Falloff',
        'height': 80,
        'draw': [
          {
            'op': 'rect',
            'x': 0.1,
            'y': 0.1,
            'w': 0.8,
            'h': 0.8,
            'stroke': 'border',
          },
          {
            'op': 'bezier',
            'x': 0.1,
            'y': 0.9,
            'cx1': 0.35,
            'cy1': 0.9,
            'cx2': 0.65,
            'cy2': 0.1,
            'x2': 0.9,
            'y2': 0.1,
            'stroke': 'accent',
            'width': 2,
          },
          {'op': 'circle', 'x': 0.35, 'y': 0.9, 'r': 0.05, 'fill': 'accent'},
        ],
      })!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: 240,
            color: Grey.g10,
            padding: const EdgeInsets.all(8),
            child: PanelTreeView(
              node: node,
              onAction: (id, value, {live = false}) =>
                  events.add((id, value, live)),
            ),
          ),
        ),
      );
      await tester.pump();

      final rect = tester.getRect(
        find.byKey(const ValueKey('panel:canvas:curve')),
      );
      await tester.tapAt(rect.center);
      await tester.pumpAndSettle();
      expect(events, isNotEmpty);
      expect(events.first.$1, 'curve');
      final payload = events.first.$2 as Map;
      expect(payload['x'] as double, closeTo(0.5, 0.05));
      expect(payload['y'] as double, closeTo(0.5, 0.05));
      expect(payload['phase'], 'down');
    },
  );

  testWidgets(
    'ui.svg resolves var(--token) skin colors and dispatches pointer events',
    (tester) async {
      final resolved = resolveSvgThemeVars(
        '<svg viewBox="0 0 100 100"><circle cx="50" cy="50" r="20" fill="var(--accent)"/></svg>',
      );
      expect(resolved, isNot(contains('var(--accent)')));
      expect(resolved, contains(panelThemeHexMap()['accent']!));

      final events = <(String, Object?, bool)>[];
      final node = PanelNode.fromJson({
        'type': 'svg',
        'id': 'vector_pad',
        'label': 'SVG Surface',
        'height': 84,
        'svg':
            '<svg viewBox="0 0 200 84" preserveAspectRatio="none">'
            '<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1">'
            '<stop offset="0%" stop-color="var(--accent)" stop-opacity="0.5"/>'
            '<stop offset="100%" stop-color="var(--accent)" stop-opacity="0"/>'
            '</linearGradient></defs>'
            '<path d="M10 70 Q 100 10 190 70 L 190 80 L 10 80 Z" fill="url(#g)"/>'
            '<path d="M10 70 Q 100 10 190 70" fill="none" stroke="var(--accent)" stroke-width="2" stroke-dasharray="4 3"/>'
            '</svg>',
      })!;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            width: 240,
            color: Grey.g10,
            padding: const EdgeInsets.all(8),
            child: PanelTreeView(
              node: node,
              onAction: (id, value, {live = false}) =>
                  events.add((id, value, live)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rect = tester.getRect(
        find.byKey(const ValueKey('panel:svg:vector_pad')),
      );
      await tester.tapAt(rect.center);
      await tester.pumpAndSettle();
      expect(events, isNotEmpty);
      expect(events.first.$1, 'vector_pad');
      final payload = events.first.$2 as Map;
      expect(payload['x'] as double, closeTo(0.5, 0.05));
      expect(payload['y'] as double, closeTo(0.5, 0.05));
      expect(payload['phase'], 'down');
    },
  );

  testWidgets(
    'CustomCardBody preserves ephemeral drag state, passes live signals, and shows error banner',
    (tester) async {
      final seenCtx = <Map<String, Object?>>[];
      var failRender = false;
      final writes = <Map<String, double>>[];
      final live =
          ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
            const {},
            const {},
          ));
      final decl = CardDeclaration('Sound', '''
struct Params {
  /// @label(Start) @ui(bar) @range(20, 12000) @default(60)
  js_rise_start: f32,
  /// @label(End) @ui(bar) @range(20, 12000) @default(1800)
  js_rise_end: f32,
}
''', toneOf: () => InspectorSkin.toneBlend);
      addTearDown(live.dispose);
      tester.view.physicalSize = const Size(360, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        WidgetsApp(
          color: Grey.g07,
          debugShowCheckedModeBanner: false,
          pageRouteBuilder: <T>(settings, builder) =>
              PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
          home: InspectorHost(
            layer: InspectedLayer(
              kind: Kind.text,
              title: 'Title',
              cards: [decl],
              movable: const ['Sound'],
            ),
            snapshot: const InspectorSnapshot(
              numbers: {'v_js_rise_start': 60, 'v_js_rise_end': 1800},
            ),
            actions: CardActions(
              cardCustomUi: (title, _) => title == 'Sound'
                  ? (
                      uiFile: '/nonexistent/rise_to_sound.ui.js',
                      render: (ctxJson) {
                        final ctx = (jsonDecode(ctxJson) as Map)
                            .cast<String, Object?>();
                        seenCtx.add(ctx);
                        if (failRender) {
                          return jsonEncode({
                            'ok': false,
                            'error': 'ReferenceError: boom at line 42',
                          });
                        }
                        final st = (ctx['state'] as Map?) ?? const {};
                        final drag = st['drag']?.toString() ?? 'idle';
                        final audio = (ctx['audio'] as List?) ?? const [];
                        return jsonEncode({
                          'ok': true,
                          'ui': {
                            'hide': ['start', 'end'],
                            'ui': {
                              'type': 'column',
                              'children': [
                                {
                                  'type': 'text',
                                  'text':
                                      'drag=$drag audio=${audio.length} t=${ctx['time']}',
                                },
                                {
                                  'type': 'button',
                                  'id': 'grab-lo',
                                  'label': 'Grab Lo',
                                },
                              ],
                            },
                          },
                        });
                      },
                      action: (actJson, _) {
                        final act = jsonDecode(actJson) as Map;
                        if (act['id'] == 'grab-lo') {
                          return jsonEncode({
                            'ok': true,
                            'result': {
                              'set': {'start': 120},
                              'state': {'drag': 'lo'},
                            },
                          });
                        }
                        return '{"ok":true,"result":{}}';
                      },
                      liveSignal: () => (
                        time: 1.25,
                        fps: 60.0,
                        audio: const [0.1, 0.4, 0.8, 0.5],
                      ),
                    )
                  : null,
            ),
            edits: InspectorEdits(
              onValues: (changed, {required live}) =>
                  writes.add(Map.of(changed)),
              onDrop: () {},
              onKey: (_, _) {},
              onWords: (_, {required live}) => true,
              onAnimateAll: (_) {},
              together: (tells) => tells(),
              onRoute: (_) {},
              onAim: (_) {},
            ),
            live: live,
            child: const InspectorPanel(width: 360, height: 500),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Live audio & time signals flow into ctx immediately.
      expect(find.text('drag=idle audio=4 t=1.25'), findsOneWidget);
      expect(seenCtx.last['theme'], isA<Map>());

      // Action merges ephemeral state (`drag=lo`) and re-renders immediately
      // while also writing document param `v_js_rise_start`.
      await tester.tap(find.byKey(const ValueKey('panel:btn:grab-lo')));
      await tester.pumpAndSettle();
      expect(find.text('drag=lo audio=4 t=1.25'), findsOneWidget);
      expect(writes.last['v_js_rise_start'], 120.0);

      // Render error surfaces inside the non-crashing error banner with Retry.
      failRender = true;
      await tester.tap(find.byKey(const ValueKey('panel:btn:grab-lo')));
      // Trigger re-evaluation by updating doc via live notifier.
      live.value = (const {'v_js_rise_start': 120.0}, const {});
      await tester.pumpAndSettle();
      expect(find.text('ReferenceError: boom at line 42'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      failRender = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text('ReferenceError: boom at line 42'), findsNothing);
      expect(find.text('Grab Lo'), findsOneWidget);
    },
  );
}
