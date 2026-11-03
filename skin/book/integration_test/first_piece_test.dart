// The README's first piece made in the window, a picture after each step (docs/media/window_step1..5.png): a recipe from
// the Create shelf (Iris), the Glow effect from the Effects shelf on it, then Render writes the film.
//   flutter drive --profile -d macos --driver=test_driver/integration_test.dart --target=integration_test/first_piece_test.dart
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab_book/motolii.dart' show motoliiDir;
import 'package:lab_book/theme.dart';
import 'package:lab_book/workspace/dock_make.dart' show CreateShelf;
import 'package:lab_book/workspace/dock_parts.dart' show DockFooter, DockSearch;
import 'package:lab_book/workspace/timeline.dart';
import 'package:lab_book/workspace/workspace.dart' show Workspace;
import 'package:lab_book/workspace/ws.dart';
import 'package:lab_book/workspace/zoom.dart';

import '../test/door.dart' show seen, settled;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('the first piece in the window', (t) async {
    t.view.physicalSize = const Size(3200, 1920);
    t.testTextInput.register(); // (typing goes through the test's own keyboard, as cards_test.dart's: the integration binding registers none)
    addTearDown(t.view.resetPhysicalSize);
    final folder = Directory('${Directory.systemTemp.createTempSync('first').path}/Motolii')..createSync(); // (a folder named as README's ~/Movies/Motolii)
    final doc = '${folder.path}/first.motolii';
    WsZoom.set(1, keep: false);
    ColorTheme.at = '${folder.path}/none.xml'; // (the window's own skin)
    await t.pumpWidget(WidgetsApp(color: const Color(0xFF000000), builder: (c, _) => Workspace(document: doc)));
    for (var i = 0; i < 100 && find.byType(WsTimeline).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
    }
    await t.pumpAndSettle();
    final ws = WsScope.read(t.element(find.byType(WsTimeline))), m = ws.inside!;
    final out = Directory('$motoliiDir/../docs/media')..createSync(recursive: true);
    Future<void> shot(int n) async {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1500))); // (the inside draws the stage in real time)
      for (var k = 0; k < 20; k++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final root = t.binding.renderViews.first.layer! as OffsetLayer;
      final bytes = await (await root.toImage(Offset.zero & t.view.physicalSize)).toByteData(format: ImageByteFormat.png);
      File('${out.path}/window_step$n.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    await shot(1); // (an empty document)

    ws.shelf = 'Create';
    await t.pumpAndSettle();
    await t.enterText(find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText)), 'Iris');
    await t.pumpAndSettle();
    final tile = find.descendant(of: find.byType(CreateShelf), matching: find.text('Iris')).first;
    await seen(t, tile);
    await t.tap(tile);
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: find.byType(DockFooter), matching: find.text('Create')));
    await settled(t, ws);
    final iris = int.parse(ws.selected!);
    expect(m.word(iris, 'name'), 'Iris', reason: m.trouble);
    await shot(2); // (the recipe made, picked)

    ws
      ..reread()
      ..select('$iris')
      ..shelf = 'Effects';
    await t.pumpAndSettle();
    await t.enterText(find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText)), 'Glow');
    await t.pumpAndSettle();
    final glows = find.byElementPredicate((e) => e.widget is Text && (e.widget as Text).data == 'Glow' && e.findAncestorWidgetOfExactType<DockFooter>() == null);   // (the tile, as workspace_joined_test_2.dart's pick)
    for (var i = 0; i < 200 && glows.evaluate().isEmpty; i++) {   // (the window lists the effects once the inside has told them)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    final glow = glows.first;
    await seen(t, glow);
    await t.tap(glow);   // (picked on the shelf; its foot says what it is)
    await t.pump(const Duration(milliseconds: 400));
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: find.byType(DockFooter), matching: find.text('Add')));
    await settled(t, ws);
    bool glowing() => [for (final (title, _) in m.cards(iris)) title].contains('Glow');   // (the shelf's Glow is a file, a card of its own: workspace_joined_test_2.dart)
    for (var i = 0; i < 100 && !glowing(); i++) {   // (put on without waiting)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(glowing(), isTrue, reason: m.trouble);
    await shot(3); // (the effect on it)

    await t.tap(find.text('Render').first);   // (the top bar's: it asks for a name)
    await t.pumpAndSettle();
    await shot(4); // (the Render box)
    await t.enterText(find.descendant(of: find.ancestor(of: find.text('File'), matching: find.byType(Row)).first, matching: find.byType(EditableText)), 'first');   // (the box's own File: the shelf's search is an EditableText too)
    await t.pumpAndSettle();
    await t.tap(find.text('Render').last);
    await t.pumpAndSettle();
    for (var i = 0; i < 3600 && !(ws.notice ?? '').startsWith('Written'); i++) {   // (3 minutes: 8 s of Iris with Glow is written in more than 20 here)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(ws.notice, startsWith('Written'), reason: m.trouble);
    expect(File('${folder.path}/first.mp4').existsSync(), isTrue);
    await shot(5); // (written: the top bar says so)
  });
}
