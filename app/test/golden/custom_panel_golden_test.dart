// Golden contact sheet showing BOTH tracks built on the shared PanelTreeView core:
// Track A (Custom Docking Tabs): `Stagger` and `Quick Rig`
// Track B (Inspector Effect Custom Card): `Diagonal Blur` with its `.ui.js` sidecar
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/inspector/card_actions.dart';
import 'package:motolii/inspector/card_declaration.dart' show CardDeclaration;
import 'package:motolii/inspector/inspected_layer.dart';
import 'package:motolii/inspector/inspector_edits.dart';
import 'package:motolii/inspector/inspector_host.dart';
import 'package:motolii/inspector/inspector_snapshot.dart';
import 'package:motolii/inspector/inspector_state.dart';
import 'package:motolii/inspector/values_card.dart';
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/custom_ui/panel_node.dart';
import 'package:motolii/widgets/custom_ui/panel_renderer.dart';
import 'package:motolii/widgets/panel_header.dart';

import '../main_tests_only.dart';

const _diagBlur = '''
struct Params {
  /// @label(Width) @ui(bar) @range(0, 1) @default(0.35)
  js_diagonal_blur_width: f32,
  /// @label(Angle) @ui(bar) @range(-1, 1) @default(0.25)
  js_diagonal_blur_angle: f32,
  /// @label(Quality) @enum(Low, Mid, High, Best) @default(2)
  js_diagonal_blur_quality: u32,
}
''';

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('custom panels contact sheet', (tester) async {
    const w = 960.0;
    const h = 392.0;
    tester.view.physicalSize = const Size(w, h);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final stagger = PanelNode.fromJson({
      'type': 'column',
      'children': [
        {
          'type': 'row',
          'children': [
            {'type': 'badge', 'text': '4 layers', 'tone': 'accent'},
            {'type': 'spacer', 'size': 4},
            {'type': 'text', 'text': 'FPS 60', 'muted': true},
          ],
        },
        {
          'type': 'row',
          'children': [
            {
              'type': 'number',
              'id': 'step',
              'label': 'Step',
              'value': 6,
              'min': 1,
              'max': 120,
              'step': 1,
              'unit': 'f',
            },
            {
              'type': 'select',
              'id': 'order',
              'label': 'Order',
              'value': 'top',
              'options': ['top', 'bottom', 'random'],
            },
          ],
        },
        {
          'type': 'canvas',
          'id': 'curve',
          'label': 'Time Curve',
          'height': 74,
          'draw': [
            {
              'op': 'line',
              'x': 0.08,
              'y': 0.85,
              'x2': 0.92,
              'y2': 0.85,
              'stroke': 'border',
              'width': 0.8,
            },
            {
              'op': 'line',
              'x': 0.08,
              'y': 0.15,
              'x2': 0.92,
              'y2': 0.15,
              'stroke': 'border',
              'width': 0.8,
            },
            {
              'op': 'line',
              'x': 0.08,
              'y': 0.85,
              'x2': 0.38,
              'y2': 0.85,
              'stroke': 'muted',
              'width': 1,
            },
            {
              'op': 'line',
              'x': 0.92,
              'y': 0.15,
              'x2': 0.62,
              'y2': 0.15,
              'stroke': 'muted',
              'width': 1,
            },
            {
              'op': 'bezier',
              'x': 0.08,
              'y': 0.85,
              'cx1': 0.38,
              'cy1': 0.85,
              'cx2': 0.62,
              'cy2': 0.15,
              'x2': 0.92,
              'y2': 0.15,
              'stroke': 'accent',
              'width': 2.0,
            },
            {
              'op': 'circle',
              'x': 0.38,
              'y': 0.85,
              'r': 0.055,
              'fill': 'accent',
            },
            {
              'op': 'circle',
              'x': 0.62,
              'y': 0.15,
              'r': 0.055,
              'fill': 'accent',
            },
          ],
        },
        {
          'type': 'toggle',
          'id': 'fromPlayhead',
          'label': 'Start at playhead',
          'value': true,
        },
        {
          'type': 'row',
          'children': [
            {
              'type': 'button',
              'id': 'stagger',
              'label': 'Stagger',
              'accent': true,
            },
            {'type': 'button', 'id': 'align', 'label': 'Align Start'},
          ],
        },
      ],
    })!;

    final quickRig = PanelNode.fromJson({
      'type': 'column',
      'children': [
        {
          'type': 'row',
          'children': [
            {'type': 'badge', 'text': 'Hero Title', 'tone': 'place'},
            {'type': 'spacer', 'size': 4},
            {'type': 'button', 'id': 'reset', 'label': 'Reset'},
          ],
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
          'type': 'section',
          'title': 'Palette',
          'open': true,
          'children': [
            {
              'type': 'grid',
              'cols': 6,
              'children': [
                {
                  'type': 'swatch',
                  'id': 'c1',
                  'color': '#59C3E8',
                  'active': true,
                },
                {'type': 'swatch', 'id': 'c2', 'color': '#FF5A79'},
                {'type': 'swatch', 'id': 'c3', 'color': '#FFB84D'},
                {'type': 'swatch', 'id': 'c4', 'color': '#C8E64C'},
                {'type': 'swatch', 'id': 'c5', 'color': '#A78BFA'},
                {'type': 'swatch', 'id': 'c6', 'color': '#F4F4F5'},
              ],
            },
          ],
        },
        {
          'type': 'row',
          'children': [
            {
              'type': 'button',
              'id': 'audio_bounce',
              'label': 'Audio Bounce',
              'accent': true,
            },
            {'type': 'button', 'id': 'wave_spin', 'label': 'Wave Spin'},
          ],
        },
      ],
    })!;

    Widget tabCard(String title, Color tone, PanelNode root) => Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Grey.g10,
          borderRadius: Shape.round(8),
          border: Border.all(color: Grey.g20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelHeader(
              title,
              leading: Container(
                width: 16,
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  title.characters.first,
                  style: TextStyles.micro(WindowTokens.onAccent),
                ),
              ),
              trailing: [Text('Tab', style: TextStyles.micro(Grey.g56))],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(WindowTokens.gap),
                child: PanelTreeView(
                  node: root,
                  onAction: (_, _, {live = false}) {},
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final live =
        ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
          const {},
          const {},
        ));
    addTearDown(live.dispose);
    final blurDecl = CardDeclaration(
      'Diagonal Blur',
      _diagBlur,
      toneOf: () => InspectorSkin.toneBlend,
    );

    final effectCard = Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Grey.g10,
          borderRadius: Shape.round(8),
          border: Border.all(color: Grey.g20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelHeader(
              'Inspector · .ui.js Card',
              trailing: [Text('Effect', style: TextStyles.micro(Grey.g56))],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(WindowTokens.gap),
                child: InspectorHost(
                  layer: InspectedLayer(
                    kind: Kind.shape,
                    title: 'Sample',
                    cards: [blurDecl],
                    movable: const ['Diagonal Blur'],
                  ),
                  snapshot: const InspectorSnapshot(
                    numbers: {
                      'v_js_diagonal_blur_width': 0.55,
                      'v_js_diagonal_blur_angle': -0.25,
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
                                      'type': 'canvas',
                                      'id': 'compass',
                                      'label': 'Blur Vector',
                                      'height': 88,
                                      'draw': [
                                        {
                                          'op': 'circle',
                                          'x': 0.5,
                                          'y': 0.5,
                                          'r': 0.42,
                                          'stroke': 'border',
                                          'width': 1,
                                        },
                                        {
                                          'op': 'circle',
                                          'x': 0.5,
                                          'y': 0.5,
                                          'r': 0.21,
                                          'stroke': 'border',
                                          'width': 0.8,
                                          'alpha': 0.6,
                                        },
                                        {
                                          'op': 'line',
                                          'x': 0.08,
                                          'y': 0.5,
                                          'x2': 0.92,
                                          'y2': 0.5,
                                          'stroke': 'border',
                                          'width': 0.8,
                                          'alpha': 0.6,
                                        },
                                        {
                                          'op': 'line',
                                          'x': 0.5,
                                          'y': 0.08,
                                          'x2': 0.5,
                                          'y2': 0.92,
                                          'stroke': 'border',
                                          'width': 0.8,
                                          'alpha': 0.6,
                                        },
                                        {
                                          'op': 'line',
                                          'x': 0.30,
                                          'y': 0.70,
                                          'x2': 0.70,
                                          'y2': 0.30,
                                          'stroke': 'blend',
                                          'width': 5,
                                          'alpha': 0.28,
                                        },
                                        {
                                          'op': 'line',
                                          'x': 0.30,
                                          'y': 0.70,
                                          'x2': 0.70,
                                          'y2': 0.30,
                                          'stroke': 'accent',
                                          'width': 1.8,
                                        },
                                        {
                                          'op': 'circle',
                                          'x': 0.5,
                                          'y': 0.5,
                                          'r': 0.025,
                                          'fill': 'muted',
                                        },
                                        {
                                          'op': 'circle',
                                          'x': 0.70,
                                          'y': 0.30,
                                          'r': 0.065,
                                          'fill': 'accent',
                                          'alpha': 0.25,
                                        },
                                        {
                                          'op': 'circle',
                                          'x': 0.70,
                                          'y': 0.30,
                                          'r': 0.04,
                                          'fill': 'accent',
                                        },
                                        {
                                          'op': 'text',
                                          'x': 0.04,
                                          'y': 0.14,
                                          'text': '-45°',
                                          'fill': 'muted',
                                        },
                                        {
                                          'op': 'text',
                                          'x': 0.96,
                                          'y': 0.14,
                                          'text': '68%',
                                          'fill': 'text',
                                          'align': 'right',
                                        },
                                      ],
                                    },
                                    {
                                      'type': 'row',
                                      'children': [
                                        {
                                          'type': 'button',
                                          'id': 'h',
                                          'label': 'Horiz',
                                        },
                                        {
                                          'type': 'button',
                                          'id': 'v',
                                          'label': 'Vert',
                                        },
                                        {
                                          'type': 'button',
                                          'id': 'd',
                                          'label': '45°',
                                          'accent': true,
                                        },
                                        {
                                          'type': 'button',
                                          'id': 'o',
                                          'label': 'Off',
                                        },
                                      ],
                                    },
                                  ],
                                },
                              },
                            }),
                            action: (_, _) => '{"ok":true,"result":{}}',
                          )
                        : null,
                  ),
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
                  child: ValuesCard(blurDecl),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      WidgetsApp(
        color: Grey.g07,
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(settings, builder) =>
            PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
        home: ColoredBox(
          key: const ValueKey('custom-panels-root'),
          color: Grey.g07,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tabCard('Stagger', InspectorSkin.toneLayout, stagger),
                const SizedBox(width: 12),
                tabCard('Quick Rig', InspectorSkin.tonePlace, quickRig),
                const SizedBox(width: 12),
                effectCard,
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('custom-panels-root')),
      matchesGoldenFile('goldens/custom_panels_contact.png'),
    );
  });
}
