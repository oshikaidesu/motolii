// External requirement: Flutter's own accessibility guidelines (docs.flutter.dev/ui/accessibility/accessibility-testing)
// applied to the app's real window (Workspace on a new document, the engine library loaded through FFI).
// Expected values live in flutter_test, not here. Failures are information about the UI; do not edit the UI to pass.
// Skipped where engine/out/libmotolii.dylib is not built (engine/edit.sh).
//   cd app && flutter test --no-pub test/accessibility_guidelines_test.dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/bridge/engine_paths.dart' show motoliiDir;
import 'package:motolii/skin/theme.dart' show ColorTheme;
import 'package:motolii/workspace/shelf/create_preview.dart' show RecipeMotions;
import 'package:motolii/workspace/dock/dock_fonts.dart' show fontRecentAt;
import 'package:motolii/workspace/dock/dock_make.dart' show colorsAt;
import 'package:motolii/workspace/dock/dock_map.dart' show dockMapsAt;
import 'package:motolii/workspace/shelf/shelf_context.dart' show dockStarsAt;
import 'package:motolii/workspace/dock/dock_tags.dart' show DockTags;
import 'package:motolii/workspace/tool_panel/tool_panel_ease_shelf.dart' show easeKeptAt;
import 'package:motolii/workspace/shelf/effect_decks.dart' show effectDecksAt, effectRecentAt;
import 'package:motolii/workspace/timeline/timeline.dart' show WsTimeline;
import 'package:motolii/workspace/workspace.dart' show Workspace;
import 'package:motolii/workspace/state/window_zoom.dart' show WsZoom;

final _built = File('$motoliiDir/out/libmotolii.dylib').existsSync();

File _tmp(String name) => File('${Directory.systemTemp.createTempSync(name).path}/$name.json');

Future<void> _open(WidgetTester t) async {
  const size = Size(1600, 960);
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('motolii/stage'), (_) async => -1);
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.menu, (_) async => null);
  // (the maker's own kept state is left alone: every store points at a temp file)
  colorsAt(_tmp('colors'));
  effectDecksAt(_tmp('decks'));
  effectRecentAt(_tmp('recent'));
  easeKeptAt(_tmp('kept'));
  dockMapsAt(Directory.systemTemp.createTempSync('maps'));
  DockTags.latchedAt(_tmp('latched'));
  dockStarsAt(_tmp('stars'));
  fontRecentAt(_tmp('fonts'));
  ColorTheme.at = '${Directory.systemTemp.path}/motolii_test_no_theme.xml';
  WsZoom.set(1, keep: false);
  final doc = '${Directory.systemTemp.createTempSync('a11y').path}/a11y.motolii';
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (c, _) => Workspace(document: doc),
    ),
  );
  for (var i = 0; i < 1500 && find.byType(WsTimeline).evaluate().isEmpty; i++) {
    // (the engine answers in real time)
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await t.pump();
  }
  await t.pumpAndSettle();
}

void main() {
  final guidelines = <String, AccessibilityGuideline>{
    'androidTapTargetGuideline': androidTapTargetGuideline,
    'iOSTapTargetGuideline': iOSTapTargetGuideline,
    'labeledTapTargetGuideline': labeledTapTargetGuideline,
    'textContrastGuideline': textContrastGuideline,
  };
  for (final MapEntry(key: name, value: guideline) in guidelines.entries) {
    testWidgets('the real window meets $name', (t) async {
      final SemanticsHandle semantics = t.ensureSemantics();
      await _open(t);
      expect(find.byType(WsTimeline), findsOneWidget, reason: 'the real window opened');
      t.takeException(); // (a layout overflow on opening is its own test below, not counted against each guideline)
      await expectLater(t, meetsGuideline(guideline));
      t.takeException();
      semantics.dispose();
      await t.runAsync(RecipeMotions.stop);
      await t.pumpWidget(const SizedBox());
      t.view.reset();
    }, skip: !_built);
  }
  testWidgets('the real window opens without a framework exception (layout overflow etc.)', (t) async {
    await _open(t);
    expect(t.takeException(), isNull);
    await t.runAsync(RecipeMotions.stop);
    await t.pumpWidget(const SizedBox());
    t.view.reset();
  }, skip: !_built);
}
