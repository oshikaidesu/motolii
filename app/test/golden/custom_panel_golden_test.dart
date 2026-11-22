// Golden contact sheet showing the two bundled JS Custom Panels (`Stagger` and
// `Quick Rig`) rendered natively with PanelTreeView in Motolii's skin.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/tool_panel/custom_panel/panel_node.dart';
import 'package:motolii/workspace/tool_panel/custom_panel/panel_renderer.dart';

import '../main_tests_only.dart';

void main() {
  if (skipUnlessEveryTest()) return;

  testWidgets('custom panels contact sheet', (tester) async {
    const w = 640.0;
    const h = 360.0;
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

    Widget card(String title, Color tone, PanelNode root) => Expanded(
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
                card('Stagger', InspectorSkin.toneLayout, stagger),
                const SizedBox(width: 12),
                card('Quick Rig', InspectorSkin.tonePlace, quickRig),
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
