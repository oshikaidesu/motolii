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

      // Custom UI renders Blur Vector pad + Vert preset, hides raw Width/Angle, keeps Quality.
      expect(find.text('Blur Vector'), findsOneWidget);
      expect(find.text('Quality'), findsOneWidget);
      expect(find.text('Width'), findsNothing);
      expect(find.text('Angle'), findsNothing);

      // Clicking Vert preset writes back to real prefixed doc params.
      await tester.tap(find.byKey(const ValueKey('panel:btn:preset:v')));
      await tester.pumpAndSettle();
      expect(writes.last['v_js_diagonal_blur_width'], 0.4);
      expect(writes.last['v_js_diagonal_blur_angle'], 0.5);
    },
  );
}
