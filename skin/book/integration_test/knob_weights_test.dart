// A picture of the inspector with an effect's knobs tinted by how much moving each alone shows it (engine/knob_weights.json):
// Electric Edges on the balloon (or the effect --dart-define=MOTOLII_FX names, from the library's folder), in the window's
// own picture (the system's temp folder, knob_weights/).
//   flutter drive --profile -d macos --driver=test_driver/integration_test.dart --target=integration_test/knob_weights_test.dart
import 'dart:convert' show jsonDecode;
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab_book/motolii.dart' show motoliiDir;
import 'package:lab_book/sets/inspector/inspector_param_controls_tile.dart' show ParamTile;
import 'package:lab_book/theme.dart';
import 'package:lab_book/workspace/effect_tiles.dart' show EffectTiles;
import 'package:lab_book/workspace/timeline.dart';
import 'package:lab_book/workspace/workspace.dart' show Workspace;
import 'package:lab_book/workspace/ws.dart';
import 'package:lab_book/workspace/zoom.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('an effect\'s knobs are tinted by their weight', (t) async {
    t.view.physicalSize = const Size(3200, 4800);
    addTearDown(t.view.resetPhysicalSize);
    final folder = Directory('${Directory.systemTemp.createTempSync('weights').path}/Motolii')..createSync();
    WsZoom.set(1, keep: false);
    ColorTheme.at = '${folder.path}/none.xml'; // (the window's own skin)
    await t.pumpWidget(WidgetsApp(color: const Color(0xFF000000), builder: (c, _) => Workspace(document: '${folder.path}/Untitled.motolii')));
    for (var i = 0; i < 100 && find.byType(WsTimeline).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await t.pump();
    }
    await t.pumpAndSettle();
    final ws = WsScope.read(t.element(find.byType(WsTimeline))), m = ws.inside!;
    final photo = m.add('picture', '$motoliiDir/fx_sample.jpg');
    m.set(photo, 'size', 2);
    const fx = String.fromEnvironment('MOTOLII_FX', defaultValue: 'effects/am_electricedges.wgsl');
    expect(m.say(photo, 'fx', '$motoliiDir/$fx'), isTrue, reason: m.trouble);
    ws
      ..reread()
      ..select('$photo');
    await t.pumpAndSettle();
    final weighed = EffectTiles.weighed(motoliiDir, '$motoliiDir/$fx');
    final card = m.cards(photo).firstWhere((c) => c.$2.any(weighed.containsKey)).$1;
    // ignore: avoid_print
    print('card: $card');
    expect(find.text(card), findsWidgets, reason: 'its card in sight in a window this tall');
    // (palettes to try, each three colours, first the most seen: a JSON list of {id, colors}, its path given by
    //  --dart-define=MOTOLII_PALETTES; none given, the one the tile has)
    const given = String.fromEnvironment('MOTOLII_PALETTES');
    final palettes = given.isEmpty
        ? {'knob_weights': ParamTile.steps}
        : {
            for (final p in jsonDecode(File(given).readAsStringSync()) as List)
              'knob_weights_${p['id']}': [for (final c in (p['colors'] as List).reversed) Color(int.parse((c as String).substring(1), radix: 16) | 0xFF000000)],
          };
    const shots = String.fromEnvironment('MOTOLII_SHOTS');
    final out = Directory(shots.isEmpty ? '${Directory.systemTemp.path}/knob_weights' : shots)..createSync(recursive: true);   // (where its pictures go: --dart-define=MOTOLII_SHOTS)
    for (final MapEntry(key: name, value: steps) in palettes.entries) {
      ParamTile.steps = steps; // (step 1 to 3: the list's last first)
      await t.binding.reassembleApplication();
      await t.pumpAndSettle();
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 800))); // (the inside draws the stage in real time)
      for (var k = 0; k < 20; k++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final root = t.binding.renderViews.first.layer! as OffsetLayer;
      final bytes = await (await root.toImage(Offset.zero & t.view.physicalSize)).toByteData(format: ImageByteFormat.png);
      File('${out.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
