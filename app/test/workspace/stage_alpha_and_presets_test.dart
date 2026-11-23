// Tests transparent Stage checkerboard toggle and Vism card preset save/apply/delete.
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
import 'package:motolii/storage/panel_presets_file.dart'
    show readPanelPresets, writePanelPresets;
import 'package:motolii/workspace/stage/stage.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

const _testParams = '''
struct Params {
  /// @label(Amount) @ui(bar) @range(0, 1) @default(0.5)
  js_vism_amount: f32,
}
''';

void main() {
  testWidgets('Stage header Alpha toggle switches stage.alpha view flag', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final ws = WorkspaceController();
    addTearDown(ws.dispose);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(settings, builder) =>
            PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
        home: WorkspaceScope(ws: ws, child: const StagePane()),
      ),
    );
    await tester.pumpAndSettle();

    expect(ws.viewOf('stage.alpha', false), isFalse);
    final alphaToggle = find.byKey(const ValueKey('ws-stage-alpha'));
    expect(alphaToggle, findsOneWidget);

    await tester.tap(alphaToggle);
    await tester.pumpAndSettle();
    expect(ws.viewOf('stage.alpha', false), isTrue);

    await tester.tap(alphaToggle);
    await tester.pumpAndSettle();
    expect(ws.viewOf('stage.alpha', false), isFalse);
  });

  testWidgets('Vism card saves, applies, and deletes user presets live', (
    tester,
  ) async {
    const cardName = 'VismLivePresetCardTest';
    writePanelPresets(cardName, const {});
    addTearDown(() => writePanelPresets(cardName, const {}));

    final written = <String, double>{};
    final decl = CardDeclaration(
      cardName,
      _testParams,
      toneOf: () => InspectorSkin.toneBlend,
    );
    final live =
        ValueNotifier<(Map<String, double>, Map<String, KeyframeState>)>((
          const {},
          const {},
        ));
    addTearDown(live.dispose);

    // Pre-save one preset so the chip bar appears on the card.
    writePanelPresets(cardName, {
      'Preset 1': {'amount': 0.85},
    });

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        debugShowCheckedModeBanner: false,
        pageRouteBuilder: <T>(settings, builder) =>
            PageRouteBuilder<T>(pageBuilder: (c, _, _) => builder(c)),
        home: InspectorHost(
          layer: InspectedLayer(
            kind: Kind.shape,
            title: 'Layer',
            cards: [decl],
            movable: [cardName],
          ),
          snapshot: const InspectorSnapshot(
            numbers: {'v_js_vism_amount': 0.25},
          ),
          actions: CardActions(
            cardCustomUi: (title, names) => title == cardName
                ? (
                    uiFile: '$cardName.ui.js',
                    render: (_) => jsonEncode({
                      'ok': true,
                      'ui': {'type': 'text', 'text': 'Custom Vism'},
                    }),
                    action: (_, _) => '{"ok":true,"result":{}}',
                    liveSignal: null,
                    contextExtra: null,
                    applyOps: null,
                  )
                : null,
          ),
          edits: InspectorEdits(
            onValues: (m, {required live}) => written.addAll(m),
            onDrop: () {},
            onKey: (_, _) {},
            onWords: (_, {required live}) => true,
            onAnimateAll: (_) {},
            together: (tells) => tells(),
            onRoute: (_) {},
            onAim: (_) {},
          ),
          live: live,
          child: ValuesCard(decl),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap saved preset chip -> applies 0.85 back to v_js_vism_amount.
    final presetChip = find.byKey(
      const ValueKey('vism-preset:$cardName:Preset 1'),
    );
    expect(presetChip, findsOneWidget);
    await tester.tap(presetChip);
    await tester.pumpAndSettle();
    expect(written['v_js_vism_amount'], closeTo(0.85, 1e-6));

    // Delete preset chip -> clears persisted preset and hides the bar.
    await tester.tap(
      find.byKey(const ValueKey('vism-preset-del:$cardName:Preset 1')),
    );
    await tester.pumpAndSettle();
    expect(readPanelPresets(cardName), isEmpty);
    expect(presetChip, findsNothing);
  });
}
