// Golf on the real window: a hole set up, then strokes read one by one from a file as a player (a person, or a judge
// who has never seen the window) writes them, a picture of the window after each, so the strokes a goal takes are
// counted on the window itself, not on its tests (reports/golf_noise.md: the strokes, and with each whether the player
// knew where to press or guessed). As the first-click test (firstclick_test.dart) and the drag test (fx_drag_test.dart)
// run: flutter drive --profile -d macos --driver=test_driver/integration_test.dart --target=integration_test/golf_play_test.dart --dart-define=HOLE=letters
// The player writes lines to engine/out/golf/HOLE/strokes.txt, in the pictures' own points (the window's size):
//   click x y | double x y | right x y | hover x y | drag x1 y1 x2 y2 [x3 y3 ...] | scroll x y dy
//   key space|enter|escape|tab|backspace|delete|left|right|up|down|cmd+z|cmd+shift+z | type words (into the field being typed in) | wait seconds | done
// and finds NN.png written after the NNth (00.png: the hole as it begins). result.txt is the hole's answer, for the one
// who counts.
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/gestures.dart' show PointerDeviceKind, PointerScrollEvent, kSecondaryButton;
import 'package:flutter/rendering.dart' show OffsetLayer;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lab_book/motolii.dart';
import 'package:lab_book/workspace/timeline.dart';
import 'package:lab_book/workspace/workspace.dart' show Workspace;
import 'package:lab_book/workspace/ws.dart';

const _hole = String.fromEnvironment('HOLE', defaultValue: 'letters');

const _keys = {
  'space': LogicalKeyboardKey.space, 'enter': LogicalKeyboardKey.enter, 'escape': LogicalKeyboardKey.escape, 'tab': LogicalKeyboardKey.tab,
  'backspace': LogicalKeyboardKey.backspace, 'delete': LogicalKeyboardKey.delete, 'left': LogicalKeyboardKey.arrowLeft,
  'right': LogicalKeyboardKey.arrowRight, 'up': LogicalKeyboardKey.arrowUp, 'down': LogicalKeyboardKey.arrowDown, 'z': LogicalKeyboardKey.keyZ,
  'a': LogicalKeyboardKey.keyA, 'c': LogicalKeyboardKey.keyC, 'v': LogicalKeyboardKey.keyV, 'd': LogicalKeyboardKey.keyD,
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized().framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive; // (the stage's picture is the inside's, drawn as the window goes)

  testWidgets('golf: $_hole, stroke by stroke', timeout: const Timeout(Duration(minutes: 19)), (t) async {
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.menu, (_) async => null);
    final out = Directory('$motoliiDir/out/golf/$_hole');
    if (out.existsSync()) out.deleteSync(recursive: true);
    out.createSync(recursive: true);
    final strokes = File('${out.path}/strokes.txt')..writeAsStringSync('');
    final doc = '${Directory.systemTemp.createTempSync('golf').path}/golf.motolii';
    await t.pumpWidget(WidgetsApp(color: const Color(0xFF000000), builder: (c, _) => Workspace(document: doc)));
    await t.pumpAndSettle();
    final ws = WsScope.read(t.element(find.byType(WsTimeline))), m = ws.inside!;

    // (the holes: each a thing already moving as a maker would have it, with Fade In from the shelf, one after another)
    final fade = '$motoliiDir/animators/fade_in.js';
    final int thing;
    switch (_hole) {
      case 'deep':   // (ten boxes going back into the picture)
        thing = m.add('shape', 'rect');
        m.say(thing, 'space', '3d');
        for (final (n, v) in const [('size', .08), ('copies', 10.0), ('copy_x', .12), ('copy_z', -.35)]) {
          m.set(thing, n, v);
        }
        m.say(thing, 'fill', 'ffb740');
        m.say(thing, 'script', fade);
      default:   // (a title, letter by letter)
        thing = m.add('text', '$motoliiDir/out/arial_black.ttf');
        m.say(thing, 'text', 'MOTOLII');
        m.say(thing, 'script', fade);
    }
    ws.reread();
    await t.pumpAndSettle();

    final dpr = t.view.devicePixelRatio;
    var n = 0;
    Future<void> picture() async {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 700))); // (a press waits for a second before it is one; the inside draws what was said)
      await t.pump();
      // ignore: invalid_use_of_protected_member
      final root = t.binding.renderViews.first.layer! as OffsetLayer;
      final png = await (await root.toImage(Offset.zero & t.view.physicalSize, pixelRatio: 1 / dpr)).toByteData(format: ImageByteFormat.png);
      File('${out.path}/${n.toString().padLeft(2, '0')}.png').writeAsBytesSync(png!.buffer.asUint8List());
    }

    await picture();
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    var here = Offset.zero;
    Future<void> glide(Offset to) async {   // (a hand goes there through the places between, as a mouse does: what it passes over feels it)
      for (var s = 1; s <= 12; s++) {
        await mouse.moveTo(Offset.lerp(here, to, s / 12)!);
        await t.pump(const Duration(milliseconds: 16));
      }
      here = to;
    }

    final end = DateTime.now().add(const Duration(minutes: 18));
    while (DateTime.now().isBefore(end)) {
      final lines = (await t.runAsync(() => strokes.readAsLines()))!.where((l) => l.trim().isNotEmpty).toList();
      if (lines.length <= n) {
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
        await t.pump();
        continue;
      }
      final w = lines[n].trim().split(RegExp(r'\s+')), say = w.first;
      if (say == 'done') break;
      final xs = [for (final s in w.skip(1)) double.tryParse(s) ?? 0];
      Offset at(int i) => Offset(xs[2 * i], xs[2 * i + 1]);
      switch (say) {
        case 'click' || 'double':
          await glide(at(0));
          for (var i = 0; i < (say == 'double' ? 2 : 1); i++) {
            await mouse.down(at(0));
            await mouse.up();
            await t.pump(const Duration(milliseconds: 60));
          }
        case 'right':
          await glide(at(0));
          final r = await t.createGesture(kind: PointerDeviceKind.mouse, buttons: kSecondaryButton);
          await r.down(at(0));
          await r.up();
        case 'hover':
          await glide(at(0));
        case 'drag':   // (through each point given, in small steps, as a hand goes)
          await glide(at(0));
          await mouse.down(at(0));
          for (var i = 1; i < xs.length ~/ 2; i++) {
            for (var s = 1; s <= 8; s++) {
              await mouse.moveTo(Offset.lerp(at(i - 1), at(i), s / 8)!);
              await t.pump(const Duration(milliseconds: 16));
            }
          }
          await mouse.up();
          here = at(xs.length ~/ 2 - 1);
        case 'scroll':
          await glide(at(0));
          await t.sendEventToBinding(PointerScrollEvent(position: at(0), scrollDelta: Offset(0, xs[2]), kind: PointerDeviceKind.mouse));
        case 'key':
          final parts = w[1].split('+'), key = _keys[parts.last];
          final mods = [if (parts.contains('cmd')) LogicalKeyboardKey.metaLeft, if (parts.contains('shift')) LogicalKeyboardKey.shiftLeft];
          for (final k in mods) {
            await t.sendKeyDownEvent(k, platform: 'macos');
          }
          if (key != null) await t.sendKeyEvent(key, platform: 'macos');
          for (final k in mods.reversed) {
            await t.sendKeyUpEvent(k, platform: 'macos');
          }
        case 'type':
          final typing = find.byWidgetPredicate((x) => x is EditableText && x.focusNode.hasFocus);
          if (typing.evaluate().isNotEmpty) await t.enterText(typing.first, w.skip(1).join(' '));
        case 'wait':
          await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: (1000 * xs.first).round())));
      }
      n++;
      await picture();
    }

    // (the hole's answer: what the inside holds now, and when each one moves)
    final members = (await t.runAsync(() => m.members(thing)))!;
    File('${out.path}/result.txt').writeAsStringSync([
      'strokes $n',
      'from ${m.word(thing, 'stagger_from')} stagger ${m.value(thing, 'stagger', 0)} seed ${m.value(thing, 'seed', 0)} point ${m.value(thing, 'stagger_x', 0)} ${m.value(thing, 'stagger_y', 0)} ${m.value(thing, 'stagger_z', 0)}',
      for (var i = 0; i + 3 < members.length; i += 4) 'member ${i ~/ 4} x ${members[i].toStringAsFixed(3)} y ${members[i + 1].toStringAsFixed(3)} z ${members[i + 2].toStringAsFixed(3)} delay ${members[i + 3].toStringAsFixed(3)}',
    ].join('\n'));
  });
}
