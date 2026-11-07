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
import 'dart:math' as math;
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

const _keys = {   // (each with its physical key: the key simulator finds none of its own for some (enter: golf 3, player 2))
  'space': (LogicalKeyboardKey.space, PhysicalKeyboardKey.space), 'enter': (LogicalKeyboardKey.enter, PhysicalKeyboardKey.enter),
  'escape': (LogicalKeyboardKey.escape, PhysicalKeyboardKey.escape), 'tab': (LogicalKeyboardKey.tab, PhysicalKeyboardKey.tab),
  'backspace': (LogicalKeyboardKey.backspace, PhysicalKeyboardKey.backspace), 'delete': (LogicalKeyboardKey.delete, PhysicalKeyboardKey.delete),
  'left': (LogicalKeyboardKey.arrowLeft, PhysicalKeyboardKey.arrowLeft), 'right': (LogicalKeyboardKey.arrowRight, PhysicalKeyboardKey.arrowRight),
  'up': (LogicalKeyboardKey.arrowUp, PhysicalKeyboardKey.arrowUp), 'down': (LogicalKeyboardKey.arrowDown, PhysicalKeyboardKey.arrowDown),
  'z': (LogicalKeyboardKey.keyZ, PhysicalKeyboardKey.keyZ), 'a': (LogicalKeyboardKey.keyA, PhysicalKeyboardKey.keyA), 'c': (LogicalKeyboardKey.keyC, PhysicalKeyboardKey.keyC),
  'v': (LogicalKeyboardKey.keyV, PhysicalKeyboardKey.keyV), 'd': (LogicalKeyboardKey.keyD, PhysicalKeyboardKey.keyD), 'g': (LogicalKeyboardKey.keyG, PhysicalKeyboardKey.keyG),
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

    // (the holes)
    switch (_hole) {
      case 'five':   // (five things of five kinds side by side, nothing done to them: a 3D model, a point cloud, a film, a photo, an SVG)
        final home = Directory(motoliiDir).parent.path;
        for (final (kind, file, x, size) in [
          ('solid', '$home/research_notes/hosts/bin-v8/examples/assets/DamagedHelmet.glb', -1.4, .45),
          ('solid', '$motoliiDir/out/models/pointclouds/apartment/apartment.ply', -.7, .08),
          ('film', '/Users/member_ottoto/Documents/Motolii-probes/refs/pv/EfCkoqafS8k/v.mp4', 0.0, .45),
          ('picture', '$motoliiDir/effects/chroma.png', .7, .45),
          ('picture', '$motoliiDir/acid_flat.svg', 1.4, .45),
        ]) {
          final t = m.add(kind, file);
          m.set(t, 'x', x);
          m.set(t, 'size', size);
          m.set(t, 'duration', 6);
        }
      case 'fish':   // (nine circles in a row, nothing done to them: a school to group and move one by one, GROUP_FOCUS_new.md's スイミー)
        for (var i = 0; i < 9; i++) {
          final t = m.add('shape', 'circle');
          m.set(t, 'x', -1.6 + .4 * i);
          m.set(t, 'size', .12);
          m.set(t, 'duration', 6);
        }
      case 'lyric':   // (a line of lyrics, one letter a thing, as a split will make it: TextoN's way, GROUP_FOCUS_new.md「文字」)
        const line = '君の名前を呼んだ';
        for (var i = 0; i < line.length; i++) {
          final t = m.add('text', '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc');
          m.say(t, 'text', line[i]);
          m.set(t, 'x', -1.05 + .3 * i);
          m.set(t, 'size', .3);
          m.set(t, 'duration', 6);
        }
      case 'tags':   // (a 3D helmet and six 2.5D tags around it, standing in the world facing the camera)
        final home = Directory(motoliiDir).parent.path;
        final helmet = m.add('solid', '$home/research_notes/hosts/bin-v8/examples/assets/DamagedHelmet.glb');
        m.set(helmet, 'size', .6);
        m.set(helmet, 'duration', 6);
        for (final (i, word) in const ['バイザー', '通気口', '顎紐', 'ヒンジ', '耳当て', '後頭部'].indexed) {
          final t = m.add('text', '/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc');
          m.say(t, 'text', word);
          m.say(t, 'space', '2.5d');
          final a = i * math.pi / 3;
          m.set(t, 'x', .75 * math.cos(a));
          m.set(t, 'y', .45 * math.sin(a));
          m.set(t, 'z', .3 * math.sin(a + .7));
          m.set(t, 'size', .12);
          m.set(t, 'duration', 6);
        }
      case 'scatter':   // (a small white circle with Alight Motion's Scatter Repeat on it, Count 20, Radius 300, as the check lays it (engine/check/scatter_repeat.sh): its copies to come out one by one by a row of its room)
        final c = m.add('shape', 'circle');
        m.set(c, 'size', .06);
        m.set(c, 'duration', 6);
        m.say(c, 'fill', 'ffffff');
        m.later('fx_file', thing: c, word: '$motoliiDir/effects/scatter_repeat.am');
        m.later('set', thing: c, name: 'js_scatter_repeat_count', number: 20);
        m.later('set', thing: c, name: 'js_scatter_repeat_radius', number: 300);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      case 'copies':   // (the same, with no effect: a small white circle grouped as ⌘G groups it (workspace.dart), the group with Copies 20 and Scatter, a square as wide as Scatter Repeat's Radius 300 (.89 of the stage: 300 px); its copies each the circle (doc_dealt), to come out one by one by a row of its room)
        final c = m.add('shape', 'circle');
        m.set(c, 'size', .06);
        m.set(c, 'duration', 6);
        m.say(c, 'fill', 'ffffff');
        final g = m.add('shape', 'null');
        m.say(g, 'name', 'Group');
        m.set(g, 'duration', 6);
        m.set(g, 'element_length', 6);
        m.set(c, 'parent', g.toDouble());
        m.set(g, 'copies', 20);
        m.set(g, 'scatter_x', .89);
        m.set(g, 'scatter_y', .89);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      default:
        throw StateError('no hole $_hole');
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
        case 'type':   // (as a keyboard types: into the field that has the cursor; with none, the first key pressed on what has the keys (a number picked starts its number so, Ableton Live's), then the rest into the field it opened)
          final words = w.skip(1).join(' ');
          var typing = find.byWidgetPredicate((x) => x is EditableText && x.focusNode.hasFocus);
          if (typing.evaluate().isEmpty && RegExp(r'^[0-9.\-]+$').hasMatch(words)) {   // (a number: each key pressed in turn on what has the keys, as a hand types it; the field it opens takes them)
            const digits = [PhysicalKeyboardKey.digit0, PhysicalKeyboardKey.digit1, PhysicalKeyboardKey.digit2, PhysicalKeyboardKey.digit3, PhysicalKeyboardKey.digit4, PhysicalKeyboardKey.digit5, PhysicalKeyboardKey.digit6, PhysicalKeyboardKey.digit7, PhysicalKeyboardKey.digit8, PhysicalKeyboardKey.digit9];
            for (final c in words.split('')) {
              final d = int.tryParse(c);
              final (k, p) = d != null ? (LogicalKeyboardKey(0x30 + d), digits[d]) : c == '-' ? (LogicalKeyboardKey.minus, PhysicalKeyboardKey.minus) : (LogicalKeyboardKey.period, PhysicalKeyboardKey.period);
              await t.sendKeyDownEvent(k, platform: 'macos', physicalKey: p, character: c);
              await t.sendKeyUpEvent(k, platform: 'macos', physicalKey: p);   // (no frame between: a typist's keys come before the field it opened takes the cursor, and it keeps them, golf_noise.md (113))
            }
            break;
          }
          // (into it as the Mac's text input gives a field what is typed (TextInputClient.updateEditingValue): this live binding
          //  has no test text input (integration_test's registerTestTextInput is false), so enterText reached no field at all)
          if (typing.evaluate().isNotEmpty) t.state<EditableTextState>(typing.first).updateEditingValue(TextEditingValue(text: words, selection: TextSelection.collapsed(offset: words.length)));
        case 'wait':
          await t.runAsync(() => Future<void>.delayed(Duration(milliseconds: (1000 * xs.first).round())));
      }
      n++;
      await picture();
    }

    // (the hole's answer: what the inside holds, and where each thing shows at each tenth of a second of the first three)
    final lines = ['strokes $n'];
    for (final x in m.things) {
      final kind = m.word(x, 'kind');
      final keyed = [
        for (final v in const ['x', 'y', 'z', 'scale_x', 'scale_y', 'rotate', 'rotate_x', 'rotate_y', 'opacity', 'size', 'strength'])
          if (m.keyMoments(x, v).isNotEmpty) '$v@${[for (final (i, k) in m.keyMoments(x, v).indexed) '${k.toStringAsFixed(2)}=${m.keyValues(x, v)[i].toStringAsFixed(2)}(${m.wayOf(x, v, k)})'].join(',')}',
      ];
      lines.add('thing $x $kind name "${m.word(x, 'name')}" file "${m.word(x, 'file').split('/').last}" parent ${m.value(x, 'parent', 0)} x ${m.value(x, 'x', 0)?.toStringAsFixed(2)} y ${m.value(x, 'y', 0)?.toStringAsFixed(2)} z ${m.value(x, 'z', 0)?.toStringAsFixed(2)} keys ${keyed.join(' ')}');
      if (m.word(x, 'shape') == 'null') lines.add('  group: stagger ${m.value(x, 'stagger', 0)} stagger_from "${m.word(x, 'stagger_from')}" seed ${m.value(x, 'seed', 0)} things ${[for (final c in m.things) if ((m.value(c, 'parent', 0) ?? 0).round() == x) c]}');
      if (kind == 'behaviour') {
        lines.add('  file ${m.word(x, 'file')} members ${m.word(x, 'members')} lag ${m.value(x, 'lag', 0)} lag_from "${m.word(x, 'lag_from')}" spread ${m.value(x, 'spread', 0)} scatter ${m.value(x, 'scatter', 0)} strength ${m.value(x, 'strength', 0)} seed ${m.value(x, 'seed', 0)}');
      }
    }
    final seen = [for (final x in m.things) if (m.word(x, 'kind') != 'behaviour') x];
    for (var f = 0; f <= 3 * Ws.fps; f += Ws.fps ~/ 10) {
      ws.frame = f;
      ws.reread();
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 120)));
      await t.pump();
      lines.add('at ${(f / Ws.fps).toStringAsFixed(1)}: ${[for (final x in seen) '$x(${[for (final v in const ['x', 'y', 'z', 'opacity', 'scale_x', 'rotate']) '${v[0]}${(m.shows(x, v, f / Ws.fps)?.$1 ?? m.value(x, v, f / Ws.fps) ?? 0).toStringAsFixed(2)}'].join(' ')} on picture ${m.frame(x)?.take(2).map((e) => e.round()).join(',') ?? '-'})'].join(' ')}');
    }
    File('${out.path}/result.txt').writeAsStringSync(lines.join('\n'));
  });
}
