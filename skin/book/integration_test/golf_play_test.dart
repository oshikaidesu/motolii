// Golf on the real window: a hole set up, then strokes read one by one from a file as a player (a person, or a judge
// who has never seen the window) writes them, a picture of the window after each, so the strokes a goal takes are
// counted on the window itself, not on its tests (reports/golf_noise.md: the strokes, and with each whether the player
// knew where to press or guessed). As the first-click test (firstclick_test.dart) and the drag test (fx_drag_test.dart)
// run: flutter drive --profile -d macos --driver=test_driver/integration_test.dart --target=integration_test/golf_play_test.dart --dart-define=HOLE=letters
// The player writes lines to engine/out/golf/HOLE/strokes.txt, in the pictures' own points (the window's size):
//   click x y | shift-click x y | cmd-click x y | double x y | right x y | hover x y | drag x1 y1 x2 y2 [x3 y3 ...] | scroll x y dy
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
import 'package:lab_book/sets/inspector/inspector_parts.dart' show Ctx, OrderDrawing;
import 'package:lab_book/workspace/timeline.dart';
import 'package:lab_book/workspace/workspace.dart' show Workspace;
import 'package:lab_book/workspace/ws.dart';

const _hole = String.fromEnvironment('HOLE', defaultValue: 'letters');

const _keys = {   // (each with its physical key: the key simulator finds none of its own for some (enter: golf 3, player 2))
  'space': (LogicalKeyboardKey.space, PhysicalKeyboardKey.space), 'enter': (LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter),
  'escape': (LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape), 'tab': (LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab),
  'backspace': (LogicalKeyboardKey.backspace, PhysicalKeyboardKey.backspace), 'delete': (LogicalKeyboardKey.delete, PhysicalKeyboardKey.delete),
  'left': (LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft), 'right': (LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight),
  'up': (LogicalKeyboardKey.arrowUp, PhysicalKeyboardKey.arrowUp), 'down': (LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown),
  'z': (LogicalKeyboardKey.keyZ, PhysicalKeyboardKey.keyZ), 'a': (LogicalKeyboardKey.keyA, PhysicalKeyboardKey.keyA), 'c': (LogicalKeyboardKey.keyC, PhysicalKeyboardKey.keyC),
  'v': (LogicalKeyboardKey.keyV, PhysicalKeyboardKey.keyV), 'd': (LogicalKeyboardKey.keyD, PhysicalKeyboardKey.keyD),
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
      case 'three':   // (three shapes in a row, nothing done to them yet: the way in, from things picked to their order)
        final made = <int>[];
        for (final (shape, x, fill) in const [('circle', -.6, '4cc9f0'), ('star', 0.0, 'ffd166'), ('rect', .6, 'ff5d8f')]) {
          final t = m.add('shape', shape);
          m.set(t, 'size', .12);
          m.set(t, 'x', x);
          m.say(t, 'fill', fill);
          made.add(t);
        }
        thing = made.last;
      case 'ripple':   // (twelve in three rows of four, one a yellow star off every named place: a ripple out from it, faded in (a third party's hole, 11/6))
        final made = <int>[];
        for (final y in const [.3, 0.0, -.3]) {
          for (final x in const [-.45, -.15, .15, .45]) {
            final star = x == -.15 && y == -.3, t = m.add('shape', star ? 'star' : 'circle');
            m.set(t, 'size', .12);
            m.set(t, 'x', x);
            m.set(t, 'y', y);
            m.say(t, 'fill', star ? 'ffd166' : '4cc9f0');
            made.add(t);
          }
        }
        thing = made[9];
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
        case 'shift-click' || 'cmd-click':   // (one more picked, as a hand holds a key down and clicks)
          final (held, physical) = say == 'shift-click' ? (LogicalKeyboardKey.shiftLeft, PhysicalKeyboardKey.shiftLeft) : (LogicalKeyboardKey.metaLeft, PhysicalKeyboardKey.metaLeft);
          await glide(at(0));
          await t.sendKeyDownEvent(held, platform: 'macos', physicalKey: physical);
          await mouse.down(at(0));
          await mouse.up();
          await t.pump(const Duration(milliseconds: 60));
          await t.sendKeyUpEvent(held, platform: 'macos', physicalKey: physical);
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
          final mods = [if (parts.contains('cmd')) (LogicalKeyboardKey.metaLeft, PhysicalKeyboardKey.metaLeft), if (parts.contains('shift')) (LogicalKeyboardKey.shiftLeft, PhysicalKeyboardKey.shiftLeft)];
          for (final (k, p) in mods) {
            await t.sendKeyDownEvent(k, platform: 'macos', physicalKey: p);
          }
          if (key case (final k, final p)) await t.sendKeyEvent(k, platform: 'macos', physicalKey: p);
          for (final (k, p) in mods.reversed) {
            await t.sendKeyUpEvent(k, platform: 'macos', physicalKey: p);
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
    if (_hole == 'three' || _hole == 'ripple') {   // (every thing, what holds it and what moves it; a group's members and when each moves)
      final lines = ['strokes $n'];
      for (final x in m.things) {
        final keyed = [for (final v in const ['opacity', 'x', 'y', 'size', 'scale_x', 'scale_y', 'rotate']) if (m.keyMoments(x, v).isNotEmpty) '$v@${m.keyMoments(x, v).map((k) => k.toStringAsFixed(2)).join(',')}=${m.keyValues(x, v).map((k) => k.toStringAsFixed(2)).join(',')}'];
        lines.add('thing $x ${m.word(x, 'kind')} ${m.word(x, 'shape')} name "${m.word(x, 'name')}" file "${m.word(x, 'file')}" script "${m.word(x, 'script')}" parent ${m.value(x, 'parent', 0)} x ${m.value(x, 'x', 0)?.toStringAsFixed(2)} y ${m.value(x, 'y', 0)?.toStringAsFixed(2)} start ${m.value(x, 'start', 0)} stagger ${m.value(x, 'stagger', 0)} from ${m.word(x, 'stagger_from')} place ${m.value(x, 'stagger_x', 0)?.toStringAsFixed(3)} ${m.value(x, 'stagger_y', 0)?.toStringAsFixed(3)} keys ${keyed.join(' ')}');
        final held = (await t.runAsync(() => m.members(x)))!;
        if (m.word(x, 'shape') == 'null') {
          for (var i = 0; i + 3 < held.length; i += 4) {
            lines.add('  member ${i ~/ 4} x ${held[i].toStringAsFixed(2)} y ${held[i + 1].toStringAsFixed(2)} delay ${held[i + 3].toStringAsFixed(3)}');
          }
        }
      }
      if (find.byType(OrderDrawing).evaluate().firstOrNull case final fig?) {   // (what the Relation card shows, beside what the document says)
        final shown = Ctx.read(fig).doc;
        lines.add('relation card: by ${shown.s2['v_stagger_from']} (${shown.get('v_stagger_from')}) stagger ${shown.get('v_stagger')} place ${shown.get('v_stagger_x')} ${shown.get('v_stagger_y')}');
      }
      File('${out.path}/result.txt').writeAsStringSync(lines.join('\n'));
      return;
    }
    final members = (await t.runAsync(() => m.members(thing)))!;
    File('${out.path}/result.txt').writeAsStringSync([
      'strokes $n',
      'from ${m.word(thing, 'stagger_from')} stagger ${m.value(thing, 'stagger', 0)} seed ${m.value(thing, 'seed', 0)} point ${m.value(thing, 'stagger_x', 0)} ${m.value(thing, 'stagger_y', 0)} ${m.value(thing, 'stagger_z', 0)}',
      for (var i = 0; i + 3 < members.length; i += 4) 'member ${i ~/ 4} x ${members[i].toStringAsFixed(3)} y ${members[i + 1].toStringAsFixed(3)} z ${members[i + 2].toStringAsFixed(3)} delay ${members[i + 3].toStringAsFixed(3)}',
    ].join('\n'));
  });
}
