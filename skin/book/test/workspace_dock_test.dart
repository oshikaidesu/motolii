// The shelves on a real document (the inside joined, test/door.dart): each lays out at the dock's sizes; Media is one
// browser, its tree beside the contents when wide and above them when narrow, its search over where it is.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart' show PointerDeviceKind, kDoubleTapTimeout, kPrimaryButton, kSecondaryButton;
import 'package:flutter/services.dart' show LogicalKeyboardKey, SystemChannels;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab_book/motolii.dart';
import 'package:lab_book/workspace/dock.dart';
import 'package:lab_book/workspace/create_preview.dart';
import 'package:lab_book/workspace/desk_kit.dart' show DeskChip;
import 'package:lab_book/workspace/dock_parts.dart' show DockIconButton, DockMem, DockSearch, dockStarsAt;
import 'package:lab_book/workspace/dock_effects.dart' show EffectTile, TileMoving;
import 'package:lab_book/workspace/dock_map.dart' show DockMap, DockMapPlaces, dockMap, dockSpread, dockSpreadRadius, dockTogether;
import 'package:lab_book/workspace/dock_tags.dart' show DockTags;
import 'package:lab_book/workspace/effect_decks.dart';
import 'package:lab_book/workspace/effect_tiles.dart';

import 'door.dart';

const _shelves = ['Media', 'Effects', 'Fonts', 'Colors', 'Create', 'Program'];

/// A window's state joined to a new document in a folder of its own, with a picture beside it.
Ws _joined() {
  final dir = Directory.systemTemp.createTempSync('dock');
  File('$motoliiDir/fx_sample.jpg').copySync('${dir.path}/still.jpg');   // (a picture in git: a clean clone has it)
  final m = Motolii.open('${dir.path}/dock.motolii')!;
  addTearDown(m.close);
  return Ws()
    ..join(m)
    ..documentFolder = dir.path;
}

Future<void> _shelf(WidgetTester t, Ws ws, Size size, String shelf) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.binding.setSurfaceSize(size);   // (the live binding lays out at its surface's size: flutter_test_config.dart)
  addTearDown(() => t.binding.setSurfaceSize(null));   // (and back after it, as the view: the next test's own)
  await t.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      builder: (_, _) => WsScope(
        ws: ws,
        child: Overlay(   // (a tile is carried to the stage on an overlay, as the window gives it: Draggable's own need)
          key: ValueKey('$shelf $size'),   // (a new one for each: an overlay keeps the entries it began with)
          initialEntries: [OverlayEntry(builder: (_) => Align(alignment: Alignment.topLeft, child: SizedBox(width: size.width, height: size.height, child: WsShelf(shelf, key: ValueKey(shelf)))))],
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  test('an AbsentMotion effect\'s tile is drawn with the knobs its own table shows it with (tools/effect_showcase.json), split before and after where it says', () {
    final table = EffectTiles.table(motoliiDir);
    of(String name) {
      final f = '$motoliiDir/effects/am_$name.wgsl';
      return EffectTiles.showcase(f, File(f).readAsStringSync(), table);
    }
    expect(of('rays')?.knobs, {'js_am_rays_R_center_x': .5, 'js_am_rays_R_center_y': .5, 'js_am_rays_reach': .6, 'js_am_rays_threshold': .5}, reason: 'center: skslc\'s R_ before it, a vector one knob each way');
    expect([of('duotone')?.knobs['js_am_duotone_color1_x'], of('duotone')?.knobs['js_am_duotone_color1_w']], [0x2b / 255, 1.0], reason: 'a colour #2b1055: one knob each way, its alpha 1');
    expect(of('huesaturation')?.split, .4, reason: 'before at its left, up to 0.4');
    expect(EffectTiles.showcase('$motoliiDir/effects/God Rays.fs', '', table), isNull, reason: 'VIDVOX\'s: not in the table');
    final all = [for (final n in (table['effects'] as Map).keys) if (File('$motoliiDir/effects/am_$n.wgsl').existsSync()) of('$n')];
    expect([all.length > 100, all.every((s) => s != null)], [true, true], reason: 'every one of the table\'s with a file of its own read as it is');
    expect(of('chromakey')?.sweeps['js_am_chromakey_tolerance'], [0, 0, .2, .2, 0], reason: 'a moving line\'s list of numbers for one knob: its keys');
    expect(of('stretchaxis')?.moves, isTrue, reason: 'its "move" layout: seen on something going past');
  });
  testWidgets('the Effects shelf has a reload mark: lit, and saying how many are drawn, while the tiles are', (t) async {
    await _shelf(t, _joined(), const Size(1280, 800), 'Effects');
    expect(find.byKey(const ValueKey('ws-fx-reload')), findsOneWidget);
    EffectTiles.progress.value = (24, 1184);
    await t.pump();
    expect(find.text('24 of 1184'), findsOneWidget);
    expect(t.widget<DockIconButton>(find.byKey(const ValueKey('ws-fx-reload'))).on, isTrue);
    EffectTiles.progress.value = null;
    await t.pump();
    expect(find.textContaining(' ready'), findsOneWidget);
  }, skip: !insideBuilt);
  test('a tile shows what its effect does, told by the effect: the knob that stands for it goes, one seen on nothing but an edge is laid on a card going past, with no knob the line between before and after goes across, one that does nothing says so; only that keeps no pictures', () {
    final out = Directory.systemTemp.createTempSync('motolii_tile_test');
    final effects = ['Bright.fs', 'am_longshadow.wgsl', '3d Rotate.fs', 'am_reorient360.wgsl', 'Color Invert.fs'];
    final drawn = EffectTiles.draw(motoliiDir, [for (final (i, e) in effects.indexed) ('$motoliiDir/effects/$e', '${out.path}/$i.png')]);
    expect(drawn.map((d) => d.$2), [false, false, true, false, false], reason: '3d Rotate\'s vertex shader is not run here: it changes nothing, and the tile says so');
    expect([for (final (i, _) in effects.indexed) File(EffectTiles.frame('${out.path}/$i.png', EffectTiles.moments.length - 1)).existsSync()], [true, true, false, true, true], reason: 'a line of AbsentMotion\'s table with no knob moved moves one all the same');
    for (final (i, why) in [(0, 'Bright has no clock: its knob moved, the sample stands'), (3, 'the hand set a value, and moved nothing'), (4, 'Color Invert has no knob: its line moved')]) {
      final first = File(EffectTiles.frame('${out.path}/$i.png', 0)).readAsBytesSync(), last = File(EffectTiles.frame('${out.path}/$i.png', EffectTiles.moments.length - 1)).readAsBytesSync();
      expect(first.length == last.length && first.indexed.every((b) => last[b.$1] == b.$2), isFalse, reason: why);
    }
    out.deleteSync(recursive: true);
  }, skip: !insideBuilt);

  testWidgets('every shelf lays out at the reference size and when smaller', (t) async {
    final ws = _joined();
    for (final size in const [Size(240, 918), Size(240, 600)]) {
      for (final s in _shelves) {
        await _shelf(t, ws, size, s);
        expect(t.takeException(), isNull, reason: '$s at $size');
        expect(find.text(s), findsWidgets);
      }
    }
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('Media is one browser: tree beside the contents when wide, above them when narrow; search covers the location', (t) async {
    final ws = _joined();
    await _shelf(t, ws, const Size(520, 900), 'Media');
    expect(find.byKey(const ValueKey('browser:tree-grip')), findsNothing, reason: 'wide: the tree stands beside the contents');
    await _shelf(t, ws, const Size(300, 900), 'Media');
    expect(find.byKey(const ValueKey('browser:tree-grip')), findsOneWidget, reason: 'narrow: the tree above, with a grip to size it');
    final folder = find.byKey(ValueKey('browser:file:${ws.documentFolder}')); // (the document's own folder, a tile of Project: opened)
    await t.ensureVisible(folder.first);
    await t.tap(folder.first);
    await t.pumpAndSettle();
    await t.enterText(find.byType(EditableText), 'still');
    for (var i = 0; i < 10 && find.text('still.jpg').evaluate().isEmpty; i++) { // (a folder of the disk is read without waiting: its files come a moment later)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pumpAndSettle();
    }
    expect(find.text('still.jpg'), findsWidgets, reason: 'the picture beside the document, found by its name');
    await t.tap(find.byKey(ValueKey('browser:file:${ws.documentFolder}/still.jpg')).first);   // (picked: its foot says what it is)
    for (var i = 0; i < 600 && find.textContaining('857 × 857').evaluate().isEmpty; i++) {   // (GStreamer's discoverer, on another isolate; 5 seconds were too few for a CI Mac: golf (108))
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(find.textContaining('857 × 857 · JPEG'), findsOneWidget, reason: 'its size and kind, as GStreamer\'s discoverer tells them (Alight Motion\'s Media Info)');
    expect(await mediaInfoOf(ws.inside!.libPath, '$motoliiDir/check/beats.mp4'), '320 × 180 · 30 fps · 4.0 s · Quicktime', reason: 'a film: its rate and length too');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  }, retry: 2, skip: !insideBuilt);   // (a slow CI Mac only: golf_noise.md (108))

  testWidgets('a tile pressed is picked as the button goes down, so the shelf\'s button makes that one (Finder picks an icon at once and opens it on a second click; golf (77))', (t) async {
    final ws = _joined(), m = ws.inside!, before = m.things.length;
    await _shelf(t, ws, const Size(520, 918), 'Create');
    await t.tap(find.text('Layers').first);   // (its chip: the recipes come first)
    await t.pumpAndSettle();
    await t.tap(find.text('Camera').first);
    await t.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    expect(find.text('Camera layer'), findsOneWidget);
    await t.tap(find.text('Null').first);
    await t.pump();   // (no wait for a second press)
    expect(find.text('Null layer'), findsOneWidget, reason: 'the button below is about the tile pressed last');
    await t.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    expect(m.things.length, before, reason: 'one press makes nothing');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('Alight Motion\'s fourteen samples under the colour on the Colors shelf: white in one press (golf (80))', (t) async {
    final ws = _joined(), m = ws.inside!, rect = m.add('shape', 'rect');
    ws
      ..reread()
      ..select('$rect');
    await _shelf(t, ws, const Size(520, 918), 'Colors');
    expect(find.byKey(const ValueKey('colour-sample-000000')), findsOneWidget, reason: 'black among them');
    await t.tap(find.byKey(const ValueKey('colour-sample-ffffff')));
    for (var i = 0; i < 200 && ws.waiting; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(m.word(rect, 'fill'), 'ffffff');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('an effect\'s colour, three numbers to the inside, takes a sample of the Colors shelf as one colour when its card aims the shelf at it (golf (83))', (t) async {
    final ws = _joined(), m = ws.inside!, rect = m.add('shape', 'rect');
    expect(m.say(rect, 'fx', '$motoliiDir/effects/Fade Color.fs'), isTrue, reason: m.trouble);
    ws
      ..reread()
      ..select('$rect')
      ..aim = 'js_Fade_Color_color';   // (its card's colour link pressed: workspace_seat.dart onAim)
    await _shelf(t, ws, const Size(520, 918), 'Colors');
    await t.tap(find.byKey(const ValueKey('colour-sample-ffffff')));
    for (var i = 0; i < 200 && ws.waiting; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect([for (final c in ['x', 'y', 'z']) m.value(rect, 'js_Fade_Color_color_$c', 0)], [1, 1, 1], reason: 'white: the three numbers');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('Photo on the Colors shelf is the picture picked on Media: the shelves keep their picks apart, and it reads Media\'s', (t) async {
    final ws = _joined(), rect = ws.inside!.add('shape', 'rect');
    ws
      ..reread()
      ..select('$rect');
    VoidCallback? photo() => t.widget<DeskChip>(find.byKey(const ValueKey('colour-photo'))).onTap;
    await _shelf(t, ws, const Size(520, 918), 'Colors');
    expect(photo(), isNull, reason: 'no picture picked on Media');
    (ws.view.putIfAbsent('dock.Media', DockMem.new) as DockMem).sel['Media'] = '${ws.documentFolder}/still.jpg';
    await _shelf(t, ws, const Size(521, 918), 'Colors');
    expect(photo(), isNotNull, reason: 'the picture picked on Media');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('a picture picked and another picture pressed on Media: Replace shows the new one, its keys as they were (After Effects\' Replace Layer Source; P17)', (t) async {
    final ws = _joined(), m = ws.inside!;
    File('${ws.documentFolder}/still.jpg').copySync('${ws.documentFolder}/final.jpg');
    final pic = m.add('picture', '${ws.documentFolder}/still.jpg');
    expect(pic > 0 && m.key(pic, 'x', .5, 0) && m.key(pic, 'x', 1.5, 1), isTrue, reason: m.trouble);
    ws
      ..reread()
      ..select('$pic');
    await _shelf(t, ws, const Size(520, 900), 'Media');
    final folder = find.byKey(ValueKey('browser:file:${ws.documentFolder}'));
    await t.ensureVisible(folder.first);
    await t.tap(folder.first);
    await t.pumpAndSettle();
    final tile = find.byKey(ValueKey('browser:file:${ws.documentFolder}/final.jpg'));
    for (var i = 0; i < 20 && tile.evaluate().isEmpty; i++) {   // (a folder of the disk is read without waiting)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pumpAndSettle();
    }
    await t.tap(tile.first);
    await t.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));   // (a tile pressed twice places it: one press is known once the second has not come)
    await t.pumpAndSettle();
    expect(ws.selected, '$pic', reason: 'the picture still picked');
    await t.tap(find.text('Replace'));
    for (var i = 0; i < 200 && ws.waiting; i++) {   // (asked without waiting)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect([m.word(pic, 'file'), m.keyMoments(pic, 'x').length], ['${ws.documentFolder}/final.jpg', 2], reason: 'the same thing, its file the new one, its keys kept');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('a picture shown by several things: All beside Replace puts the new one in every one, one undo takes it back (Alight Motion\'s Media Info Replace: AbsentMotion\'s replaceMedia)', (t) async {
    final ws = _joined(), m = ws.inside!, old = '${ws.documentFolder}/still.jpg', made = '${ws.documentFolder}/final.jpg';
    File(old).copySync(made);
    final a = m.add('picture', old), b = m.add('picture', old), box = m.add('shape', 'rect');
    expect(a > 0 && b > 0 && box > 0 && m.say(box, 'fill_media', old), isTrue, reason: m.trouble);
    ws
      ..reread()
      ..select('$a');
    await _shelf(t, ws, const Size(520, 900), 'Media');
    final folder = find.byKey(ValueKey('browser:file:${ws.documentFolder}'));
    await t.ensureVisible(folder.first);
    await t.tap(folder.first);
    await t.pumpAndSettle();
    final tile = find.byKey(ValueKey('browser:file:$made'));
    for (var i = 0; i < 20 && tile.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pumpAndSettle();
    }
    await t.tap(tile.first);
    await t.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    await t.pumpAndSettle();
    expect(find.text('All 3'), findsOneWidget, reason: 'two pictures and a shape filled with it');
    await t.tap(find.text('All 3'));
    for (var i = 0; i < 200 && ws.waiting; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect([m.word(a, 'file'), m.word(b, 'file'), m.word(box, 'fill_media')], [made, made, made]);
    m.undo();
    expect([m.word(a, 'file'), m.word(b, 'file'), m.word(box, 'fill_media')], [old, old, old], reason: 'one step');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('a file\'s effect starred: Favorites in the list holds the starred, and kept for the next time', (t) async {
    final kept = File('${Directory.systemTemp.createTempSync('stars').path}/effect_stars.json');
    dockStarsAt(kept);
    final ws = _joined();
    await _shelf(t, ws, const Size(600, 918), 'Effects');
    final tile = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('ws-screen-')).first;
    final id = (t.widget(tile).key as ValueKey<String>).value.substring('ws-screen-'.length);
    final hand = await t.createGesture(kind: PointerDeviceKind.mouse);
    await hand.addPointer(location: t.getCenter(tile));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('ws-star-$id')));
    await t.pump(const Duration(milliseconds: 400));   // (the tile under it waits for a second press first: a double tap puts it on)
    await hand.removePointer();
    await t.pumpAndSettle();
    expect(kept.readAsStringSync(), contains(id), reason: 'kept for the next time');
    await t.tap(find.byKey(const ValueKey('ws-fx-place-★')));
    await t.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('ws-screen-')), findsOneWidget, reason: 'the starred alone');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('an effect put on comes among the last put on: in sight over the tiles and Recent in the list, the newest first, and said in the log', (t) async {
    final kept = File('${Directory.systemTemp.createTempSync('recent').path}/effect_recent.json');
    effectRecentAt(kept);
    final ws = _joined();
    await _shelf(t, ws, const Size(600, 918), 'Effects');
    final tiles = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('ws-screen-'));
    String idOf(Finder f) => (t.widget(f).key as ValueKey<String>).value.substring('ws-screen-'.length);
    final first = idOf(tiles.at(0)), second = idOf(tiles.at(1));
    expect(find.byKey(const ValueKey('ws-fx-recent')), findsNothing, reason: 'none put on yet');
    Future<void> put(String id) async {
      await doubleTap(t, find.byKey(ValueKey('ws-screen-$id')));
      for (var i = 0; i < 200 && (ws.waiting || !effectRecent().contains(id)); i++) {   // (asked without waiting)
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await t.pump();
      }
      await t.pump(const Duration(milliseconds: 400));
    }
    await put(first);
    await put(second);
    expect(effectRecent(), [second, first], reason: 'the newest first');
    expect(jsonDecode(kept.readAsStringSync()), [second, first], reason: 'kept for the next time');
    expect(find.descendant(of: find.byKey(const ValueKey('ws-fx-recent')), matching: find.byType(EffectTile)), findsNWidgets(2), reason: 'in sight over the tiles');
    await t.tap(find.byKey(const ValueKey('ws-fx-place-Recent')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('ws-fx-recent')), findsNothing, reason: 'not twice');
    expect(idOf(tiles.at(0)), second, reason: 'the table, the newest first');
    expect(tiles, findsNWidgets(2));
    final lines = File('${kept.parent.path}/effect_used.jsonl').readAsLinesSync();
    expect([for (final l in lines) (jsonDecode(l) as Map)['id']], [first, second], reason: 'each said in the log, in its order');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('a deck: a row in the list, made from words typed, a hand puts one in by its menu and by a drag and takes one out, renamed, kept for the next time, deleted', (t) async {
    final kept = File('${Directory.systemTemp.createTempSync('decks').path}/effect_decks.json');
    effectDecksAt(kept);
    final ws = _joined();
    await _shelf(t, ws, const Size(600, 918), 'Effects');
    final tiles = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('ws-screen-'));
    List<String> ids() => [for (final e in tiles.evaluate()) (e.widget.key as ValueKey<String>).value.substring('ws-screen-'.length)];
    final m = ws.inside!, strangers = m.effects.where((e) => !e.$1.toLowerCase().contains('blur') && !m.about(e.$2).toLowerCase().contains('blur') && !m.tags(e.$2).contains('blur')).toList();
    final stranger = strangers[0], another = strangers[1];
    final search = find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText)), naming = find.descendant(of: find.byKey(const ValueKey('ws-fx-naming')), matching: find.byType(EditableText));
    Finder place(String p) => find.byKey(ValueKey('ws-fx-place-$p'));
    Future<void> press(Finder f, {int buttons = kPrimaryButton}) async {
      await t.tap(f, buttons: buttons);
      await t.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
      await t.pumpAndSettle();
    }
    Future<void> type(Finder f, String words) async {
      await t.enterText(f, words);
      await t.pumpAndSettle();
    }
    await type(search, 'blur');
    await press(find.byKey(const ValueKey('ws-fx-deck-new')));
    await press(find.text('New Deck from “blur”'));
    expect(place('@blur'), findsOneWidget, reason: 'a row in the list, by the words typed');
    expect(t.widget<EditableText>(naming).focusNode.hasFocus, isTrue, reason: 'its name at once to write');
    expect(t.widget<EditableText>(search).controller.text, '', reason: 'the words are the deck\'s now');
    await type(naming, 'Soft');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect([place('@blur').evaluate().length, place('@Soft').evaluate().length], [0, 1]);
    final found = ids();
    expect(found, isNotEmpty, reason: 'open, what its words find');
    expect(jsonDecode(kept.readAsStringSync())['decks'][0]['words'], 'blur', reason: 'kept, and no hand listed what it found');
    await press(place('All'));
    await type(search, stranger.$1);
    await press(find.byKey(ValueKey('ws-screen-${stranger.$2}')), buttons: kSecondaryButton);
    await press(find.byKey(const ValueKey('ws-menu-Soft')));
    await type(search, another.$1);
    final hand = await t.startGesture(t.getCenter(find.byKey(ValueKey('ws-screen-${another.$2}'))));
    await t.pump(const Duration(milliseconds: 50));
    await hand.moveTo(t.getCenter(place('@Soft')));
    await t.pump(const Duration(milliseconds: 50));
    await hand.up();
    await t.pumpAndSettle();
    await type(search, '');
    await press(place('@Soft'));
    expect(ids(), containsAll([stranger.$2, another.$2]), reason: 'put in by hand, by its menu and by a drag, beside what its words find');
    await press(find.byKey(ValueKey('ws-screen-${found.first}')));
    await press(find.byKey(const ValueKey('ws-fx-more')));
    expect(find.byKey(const ValueKey('ws-menu-Add to Favorites')), findsOneWidget, reason: 'the three dots open what a right click does');
    await press(find.byKey(const ValueKey('ws-menu-Soft')));
    expect(ids(), isNot(contains(found.first)), reason: 'one its words find, taken out by hand, stays out');
    expect(ids(), contains(found[1]));
    effectDecksAt(kept);   // (the next time)
    expect(effectDecks().single.things.map((e) => e.sum), [effectSum(stranger.$2), effectSum(another.$2)], reason: 'known by what it is');
    expect(effectDecks().single.without, {found.first});
    await press(place('Recent'));   // (the list as read again)
    await press(place('@Soft'));
    await press(place('@Soft'), buttons: kSecondaryButton);
    await press(find.byKey(const ValueKey('ws-menu-Delete')));
    expect(place('@Soft'), findsNothing);
    expect(ids(), isNotEmpty, reason: 'back on all');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('a deck handed on as a line: pasted by the + of the decks, what this machine lacks kept and marked, and it comes back when the effect does', (t) async {
    final ws = _joined();
    await _shelf(t, ws, const Size(600, 918), 'Effects');
    final m = ws.inside!, here = m.effects.first;
    final line = deckCode(EffectDeck('Sent', things: [DeckThing(here.$2, here.$1, effectSum(here.$2)), DeckThing('/elsewhere/engine/effects/Nowhere.fs', 'Nowhere', 'abc')]));
    expect(deckRead('hello'), isNull);
    expect(line, startsWith(deckCodeHead));
    expect(line, isNot(contains('/Users/')), reason: 'no one\'s folders go with it');
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => call.method == 'Clipboard.getData' ? {'text': line} : null);
    addTearDown(() => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await t.tap(find.byKey(const ValueKey('ws-fx-deck-new')));
    await t.pumpAndSettle();
    await t.tap(find.text('Paste Deck Code'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('ws-fx-place-@Sent')), findsOneWidget);
    expect(find.byKey(ValueKey('ws-screen-${here.$2}')), findsOneWidget, reason: 'the one here');
    expect(find.text('NOT HERE'), findsOneWidget, reason: 'the one not, its name kept');
    expect(find.text('Nowhere'), findsOneWidget);
    final moved = EffectDeck('Moved', things: [DeckThing('/gone/${here.$2.split('/').last}', here.$1, effectSum(here.$2))]);
    deckSettle(moved, {for (final e in m.effects) e.$2});
    expect(moved.things.single.id, here.$2, reason: 'moved: found again by its fingerprint');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('narrow, the list folds to the row that says where the shelf looks: a press opens it, a press on a row picks and folds it, a tile carried over it opens it for a deck', (t) async {
    effectDecksAt(File('${Directory.systemTemp.createTempSync('decks').path}/effect_decks.json'));
    effectDecks().add(EffectDeck('Soft'));
    final ws = _joined();
    await _shelf(t, ws, const Size(300, 918), 'Effects');
    Finder place(String p) => find.byKey(ValueKey('ws-fx-place-$p'));
    Future<void> press(Finder f) async {
      await t.tap(f);
      await t.pumpAndSettle();
    }
    expect([place('All').evaluate().length, place('Recent').evaluate().length], [1, 0], reason: 'one row, the rest of the shelf the tiles\'');
    await press(place('All'));
    expect([place('Recent').evaluate().length, place('@Soft').evaluate().length], [1, 1], reason: 'the list');
    await press(place('@Soft'));
    expect([place('@Soft').evaluate().length, place('All').evaluate().length], [1, 0], reason: 'folded, saying where it looks');
    await press(place('@Soft'));
    await press(place('All'));
    final tile = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('ws-screen-')).first;
    final hand = await t.startGesture(t.getCenter(tile));
    await t.pump(const Duration(milliseconds: 50));
    await hand.moveTo(t.getCenter(place('All')));
    await t.pumpAndSettle();
    await hand.moveTo(t.getCenter(place('@Soft')));
    await t.pump(const Duration(milliseconds: 50));
    await hand.up();
    await t.pumpAndSettle();
    expect(effectDecks().single.things, hasLength(1), reason: 'dropped on the deck the carrying opened');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('on the map a deck is made from it: the map all the shelf, the list folded to the deck picked, what it holds under its row, a press there picking one, its picture its first four (Hearthstone\'s deck list beside its collection, Spotify\'s playlist cover)', (t) async {
    final ws = _joined();
    final m = ws.inside!, drawn = [for (final e in m.effects) if (m.picture(e.$2).isNotEmpty) e], four = (drawn.length >= 4 ? drawn : m.effects).take(4).toList();
    effectDecks().add(EffectDeck('Soft', things: [for (final e in four) DeckThing(e.$2, e.$1, effectSum(e.$2))]));
    await _shelf(t, ws, const Size(300, 918), 'Effects');
    Finder place(String p) => find.byKey(ValueKey('ws-fx-place-$p'));
    Future<void> press(Finder f) async {
      await t.tap(f);
      await t.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
      await t.pumpAndSettle();
    }
    await press(find.byKey(const ValueKey('ws-Effects-map')));
    await press(place('All'));
    await press(place('@Soft'));
    expect([place('All').evaluate().length, for (final e in four) find.byKey(ValueKey('ws-fx-held-${e.$2}')).evaluate().length], [0, 1, 1, 1, 1], reason: 'folded to it, what it holds under its row');
    expect(t.widget<DockMap>(find.byType(DockMap)).shown.length, greaterThan(four.length), reason: 'the map all the shelf, to make it from');
    expect(find.descendant(of: place('@Soft'), matching: find.byType(TileMoving)), drawn.length >= 4 ? findsNWidgets(4) : anything, reason: 'its picture, its first four');
    await press(find.byKey(ValueKey('ws-fx-held-${four[1].$2}')));
    expect(ws.view.values.whereType<DockMem>().firstWhere((d) => d.mapped.contains('Effects')).sel['Effects'], four[1].$2, reason: 'a press picks it');   // (the dock it is a map on)
    final map = dockMap('Effects');
    await t.runAsync(() async {   // (the map laid out before the inside goes: its numbers are read from it)
      for (var i = 0; i < 600 && (map.laying.value || map.places.value.isEmpty); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    });
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  test('the pack an effect came in, from the folder its maker named', () {
    expect(effectPack('/x/engine/aviutl_scripts/HexBrowns__HexScript/Script/A.anm2#b'), 'HexScript');
    expect(effectPack('/x/engine/effects/Bloom.fs'), isNull);
  });

  testWidgets('a file\'s effect with nothing picked comes on an adjustment layer over all else, picked (After Effects, Photoshop\'s Adjustments panel)', (t) async {
    final ws = _joined();
    await _shelf(t, ws, const Size(600, 918), 'Effects');
    final m = ws.inside!;
    final was = m.things.length;
    final tile = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('ws-screen-')).first;
    final id = (t.widget(tile).key as ValueKey<String>).value.substring('ws-screen-'.length);
    await t.tap(tile);
    await t.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    await t.pumpAndSettle();
    expect(find.text('new layer'), findsOneWidget, reason: 'as the foot says');
    await t.tap(find.text('Add'));
    for (var i = 0; i < 200 && (ws.waiting || ws.selected == null); i++) {   // (asked without waiting)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await t.pump();
    }
    expect(m.things.length, was + 1);
    final board = int.parse(ws.selected!);
    expect([m.word(board, 'fill'), m.word(board, 'name'), m.word(board, 'fx')], ['behind', 'Adjustment', contains(id)]);
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('an effect pressed once shows its moving pictures large above its name (Alight Motion\'s large moving sample)', (t) async {
    final ws = _joined();
    await _shelf(t, ws, const Size(600, 918), 'Effects');
    final tile = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('ws-screen-') && ws.inside!.picture((w.key as ValueKey<String>).value.substring('ws-screen-'.length)).isNotEmpty).first;   // (one with its pictures drawn)
    expect(find.byKey(const ValueKey('ws-fx-preview')), findsNothing, reason: 'none pressed: no sample');
    await t.tap(tile);
    await t.pump();
    expect(find.byKey(const ValueKey('ws-fx-preview')), findsNothing, reason: 'the tiles stay where they are while a second press may come');
    await t.pump(const Duration(milliseconds: 400));   // (one press picks: the second would put it on)
    await t.pump(const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('ws-fx-preview')), findsOneWidget);
    expect(t.getSize(find.byKey(const ValueKey('ws-fx-preview'))).height, greaterThan(t.getSize(tile).height), reason: 'larger than its tile');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('a shape among the recipes (AbsentMotion\'s Heart) shows its own outline on its tile', (t) async {
    final ws = _joined();
    await _shelf(t, ws, const Size(240, 918), 'Create');
    await t.enterText(find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText)), 'Heart');
    for (var i = 0; i < 1200 && RecipeMotions.of('Heart') == null; i++) {   // (the previews are made in an isolate of their own: waited for in real time)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    }
    await t.pumpAndSettle();
    expect(RecipeMotions.of('Heart')?.single.outline, startsWith('M '), reason: 'its path, as the recipe says it');
    expect(find.byType(SvgPicture), findsOneWidget, reason: 'drawn on its tile');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('the Effects shelf\'s search reads what an effect does, in its maker\'s words (Alight Motion\'s search of the descriptions)', (t) async {
    final ws = _joined(), m = ws.inside!;
    final checker = m.effects.firstWhere((e) => e.$2.endsWith('/am_checker.wgsl'));
    expect(m.about(checker.$2), startsWith('Draws a checkerboard'), reason: 'its head\'s --about:, from AbsentMotion\'s description');
    await _shelf(t, ws, const Size(240, 918), 'Effects');
    await t.enterText(find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText)), 'checkerboard');
    await t.pumpAndSettle();
    expect(find.byKey(ValueKey('ws-screen-${checker.$2}')), findsOneWidget, reason: 'Checker found by a word of what it does, not of its name');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('an effect put on with words typed is the first for those words the next time: Alfred\'s Keyword Latching (golf_noise.md (94))', (t) async {
    DockTags.latchedAt(File('${Directory.systemTemp.createTempSync('latch').path}/latched.json'));
    final ws = _joined();
    await _shelf(t, ws, const Size(240, 6000), 'Effects');   // (tall, all the blurs in sight: the shelf makes only the tiles that are)
    final search = find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText));
    List<String> shown() => [
      for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('ws-screen-')).evaluate())
        (e.widget.key! as ValueKey<String>).value.substring('ws-screen-'.length),
    ];
    await t.enterText(search, 'blur');
    await t.pumpAndSettle();
    final before = shown(), last = before[1];   // (the second: one the list does not already put first)
    expect(before.length, greaterThan(2), reason: 'several blurs, A to Z');
    final tile = find.byKey(ValueKey('ws-screen-$last'));
    await t.ensureVisible(tile);
    await t.pumpAndSettle();
    await doubleTap(t, tile);   // (two presses put it on)
    await t.pumpAndSettle();
    expect(DockTags.latched('Effects', 'blur'), last, reason: 'put on with "blur" typed: latched to it');
    await t.enterText(search, '');
    await t.pumpAndSettle();
    await t.enterText(search, 'Blur ');
    await t.pumpAndSettle();
    expect(shown().first, last, reason: 'the one put on for these words, first now (the words as typed, big letters and spaces aside)');
    expect(shown().toSet(), before.toSet(), reason: 'the rest as they were');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('every shelf finds as the effects shelf does: a word typed wrong or in Japanese brings the nearest (golf_noise.md (97))', (t) async {
    final ws = _joined();
    Future<void> search(String shelf, String words) async {
      await _shelf(t, ws, const Size(520, 918), shelf);
      await t.enterText(find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText)), words);
      await t.pumpAndSettle();
    }
    await search('Create', 'hart');
    expect(find.text('Heart'), findsWidgets, reason: 'Create: a word typed wrong');
    await search('Create', '矢印');
    expect(find.textContaining('Arrow'), findsWidgets, reason: 'Create: a Japanese word, arrow');
    await search('Fonts', 'arail black');
    expect(find.textContaining('Arial Black'), findsWidgets, reason: 'Fonts: a word typed wrong');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('the chips move sideways as any sideways list on a Mac: the wheel with Shift held, not the wheel alone (golf_noise.md (93))', (t) async {
    final ws = _joined();
    await _shelf(t, ws, const Size(240, 918), 'Effects');
    final along = find.ancestor(of: find.text('All'), matching: find.byType(Scrollable)).first, at = t.getCenter(find.text('All'));
    expect(t.state<ScrollableState>(along).position.pixels, 0);
    final mouse = TestPointer(1, PointerDeviceKind.mouse);
    await t.sendEventToBinding(mouse.hover(at));
    await t.sendEventToBinding(mouse.scroll(const Offset(0, 100000)));
    await t.pump();
    expect(t.state<ScrollableState>(along).position.pixels, 0, reason: 'the wheel alone: up and down, not this row');
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendEventToBinding(mouse.scroll(const Offset(0, 100000)));
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.pump();
    final p = t.state<ScrollableState>(along).position;
    expect([p.pixels, p.maxScrollExtent > 0], [p.maxScrollExtent, true], reason: 'with Shift held: to the far end (Flutter\'s pointerAxisModifiers)');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('the Effects shelf filters by what each effect is, read from its file, nobody asked to write it: a tag chip, or the tag typed (Shadertoy\'s filters; golf_noise.md (92))', (t) async {
    final ws = _joined(), m = ws.inside!, nameOf = {for (final (n, f) in m.effects) f: n};
    expect(m.tags(m.effects.firstWhere((e) => e.$1 == 'Waveform Displace').$2), {'sound'}, reason: 'an audio input read: ${m.tags('Waveform Displace')}');
    expect(m.tags(m.effects.firstWhere((e) => e.$1 == 'Sorting Smear').$2), {'feedback', 'time'}, reason: 'a PERSISTENT pass, the clock');
    expect(m.tags(m.effects.firstWhere((e) => e.$2.endsWith('/datamosh.wgsl')).$2), containsAll(['multipass', 'feedback', 'time']), reason: 'a WGSL effect read too: its --pass@ lines, one kept, the clock read');
    expect(m.tags(m.effects.firstWhere((e) => e.$2.endsWith('/am_brightnesscontrast.wgsl')).$2), isNot(contains('time')), reason: 'a clock field declared and not read is not the clock');
    if (m.effects.any((e) => e.$1 == 'NCSVisualizer')) expect(m.tags(m.effects.firstWhere((e) => e.$1 == 'NCSVisualizer').$2), containsAll(['generator', 'sound']), reason: 'an AviUtl2 custom object (.obj2) that reads obj.getaudio');   // (a maker's own script, not in the repository: CI has none)
    await _shelf(t, ws, const Size(240, 6000), 'Effects');   // (tall, all that hear in sight: the shelf makes only the tiles that are)
    List<String> shown() => [
      for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('ws-screen-')).evaluate())
        nameOf[(e.widget.key! as ValueKey<String>).value.substring('ws-screen-'.length)]!,
    ];
    final chip = find.textContaining(RegExp(r'^#sound\b'));
    await seen(t, chip);
    await t.tap(chip.first);
    await t.pumpAndSettle();
    expect(shown(), containsAll(['Waveform Displace', 'FFT Spectrogram']), reason: 'the sound chip: the effects that hear');
    expect(shown().every((n) => m.tags(m.effects.firstWhere((e) => e.$1 == n).$2).contains('sound')), isTrue, reason: 'and none else: ${shown()}');
    expect(find.textContaining(RegExp(r'^#transition\b')), findsNothing, reason: 'Transition is a kind already, read the same way: not twice');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('the Effects shelf lists the files\' effects by their names, one run of A to Z (After Effects\' Effects & Presets), not by file', (t) async {
    final ws = _joined(), m = ws.inside!, nameOf = {for (final (n, f) in m.effects) f: n};
    await _shelf(t, ws, const Size(240, 918), 'Effects');
    await t.enterText(find.descendant(of: find.byType(DockSearch), matching: find.byType(EditableText)), 'glow');
    await t.pumpAndSettle();
    final names = [
      for (final e in find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('ws-screen-')).evaluate())
        nameOf[(e.widget.key! as ValueKey<String>).value.substring('ws-screen-'.length)]!,
    ];
    expect(names, containsAll(['Edge Glow', 'Glow']), reason: 'AbsentMotion\'s am_edgeglow.wgsl and VIDVOX\'s Glow.fs');
    expect(names, [...names]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())), reason: 'by name: before, the capitals of VIDVOX\'s files came before all of AbsentMotion\'s am_');
    await t.pumpWidget(const SizedBox());
  }, skip: !insideBuilt);

  testWidgets('a sound is a sound: its volume on its card and no place, no effect, nothing to colour (Alight Motion\'s audio layer, reports/alight_ui.md 177)', (t) async {
    final ws = await openWorkspace(t), m = ws.inside!;
    final wav = File('${ws.documentFolder}/tone.wav');
    final data = ByteData(44 + 8000)..setUint32(0, 0x52494646)..setUint32(4, 36 + 8000, Endian.little)..setUint32(8, 0x57415645)..setUint32(12, 0x666d7420)..setUint32(16, 16, Endian.little)..setUint16(20, 1, Endian.little)..setUint16(22, 1, Endian.little)..setUint32(24, 8000, Endian.little)..setUint32(28, 16000, Endian.little)..setUint16(32, 2, Endian.little)..setUint16(34, 16, Endian.little)..setUint32(36, 0x64617461)..setUint32(40, 8000, Endian.little);
    wav.writeAsBytesSync(data.buffer.asUint8List());
    final a = m.add('', wav.path);
    expect(a, isNot(0), reason: m.trouble);
    ws
      ..reread()
      ..select('$a')
      ..shelf = 'Colors';
    await t.pumpAndSettle();
    expect(ws.layer?.kind.name, 'audio');
    for (final (word, n) in [('Sound', 2), ('Transform', 0), ('Blending', 0), ('Fill of tone.wav', 0)]) {
      expect(find.text(word).evaluate().length, n, reason: word);
    }
    expect(find.textContaining('Add Effect'), findsNothing);
    await closeWorkspace(t);
  }, skip: !insideBuilt);

  testWidgets('a sound file picked on the Media shelf is heard before it is placed: pressed, the Mac plays it; pressed again, it stops (Alight Motion\'s song preview)', (t) async {
    final ws = _joined();
    final wav = File('${ws.documentFolder}/tone.wav');   // (half a second of silence, as a WAV file says it: 16-bit mono at 8000)
    final data = ByteData(44 + 8000)..setUint32(0, 0x52494646)..setUint32(4, 36 + 8000, Endian.little)..setUint32(8, 0x57415645)..setUint32(12, 0x666d7420)..setUint32(16, 16, Endian.little)..setUint16(20, 1, Endian.little)..setUint16(22, 1, Endian.little)..setUint32(24, 8000, Endian.little)..setUint32(28, 16000, Endian.little)..setUint16(32, 2, Endian.little)..setUint16(34, 16, Endian.little)..setUint32(36, 0x64617461)..setUint32(40, 8000, Endian.little);
    wav.writeAsBytesSync(data.buffer.asUint8List());
    await _shelf(t, ws, const Size(520, 900), 'Media');
    final folder = find.byKey(ValueKey('browser:file:${ws.documentFolder}'));
    await t.ensureVisible(folder.first);
    await t.tap(folder.first);
    await t.pumpAndSettle();
    final tile = find.byKey(ValueKey('browser:file:${wav.path}'));
    for (var i = 0; i < 20 && tile.evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pumpAndSettle();
    }
    await t.tap(tile.first);
    final listen = find.byKey(const ValueKey('media-listen'));
    for (var i = 0; i < 100 && listen.evaluate().isEmpty; i++) {   // (known to be sound once the discoverer has read it)
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    await t.tap(listen);
    for (var i = 0; i < 40 && find.descendant(of: listen, matching: find.text('■')).evaluate().isEmpty; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
      await t.pump();
    }
    expect(find.descendant(of: listen, matching: find.text('■')), findsOneWidget, reason: 'playing');
    await t.tap(listen);
    await t.pump();
    expect(find.descendant(of: listen, matching: find.text('▶')), findsOneWidget, reason: 'stopped');
    expect(find.textContaining('Audio'), findsWidgets, reason: 'shelved as Audio, not Video (Alight Motion\'s picker keeps songs apart)');
    final m = ws.inside!, before = m.things.length;
    await t.tap(find.text('Place'));
    await t.tap(find.text('Place'));   // (the inside still reading the song: the same press)
    for (var i = 0; i < 200 && m.things.length == before; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 25)));
      await t.pump();
    }
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    expect(m.things.length, before + 1, reason: 'one song');
    expect(m.word(m.things.last, 'kind'), 'film', reason: m.trouble);
    expect(m.value(m.things.last, 'visible', 0), 0, reason: 'placed heard and not seen, as Alight Motion\'s audio layer: no wave over the picture');
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  }, tags: 'main', skip: !insideBuilt);

  test('a map\'s kinds weigh more than looks: two Blurs that look apart lie nearer than a Blur and a Glitch that look alike (each kind an island, XO\'s drum types)', () {
    final look = [Float32List.fromList([0, 0]), Float32List.fromList([1, 1]), Float32List.fromList([0, 0.05]), Float32List.fromList([0.6, 0.4])];
    final kind = [for (final k in [0, 0, 1, 1]) Float32List(2)..[k] = 1];
    final v = dockTogether([look, kind], const [1, 2], even: const {0});
    double d(int a, int b) => [for (var i = 0; i < v[a]!.length; i++) (v[a]![i] - v[b]![i]) * (v[a]![i] - v[b]![i])].reduce((x, y) => x + y);
    expect(d(0, 1), lessThan(d(0, 2)), reason: 'the other Blur, though it looks apart, before the Glitch that looks alike');
    expect(dockTogether([[null, look[1]], [kind[0], kind[1]]], const [1, 2]).first, isNull, reason: 'no look: off the map');
  });

  test('heaps on a map pushed apart till none is within a tile of another, each heap kept together and apart (FontMap\'s overlap removal, d3\'s forceCollide)', () {
    final at = [for (var i = 0; i < 60; i++) Offset(i < 30 ? .2 : .8, .5 + i % 30 * .001)];   // (two heaps, each all but one point)
    final s = dockSpread(at);
    var near = double.infinity;
    for (final (i, p) in s.indexed) {
      for (final q in s.skip(i + 1)) {
        near = math.min(near, (p - q).distance);
      }
    }
    final (a, b) = (s.take(30).reduce((p, q) => p + q) / 30, s.skip(30).reduce((p, q) => p + q) / 30);
    expect([near, [for (final (i, p) in s.indexed) ((p - a).distance < (p - b).distance) == (i < 30)].every((n) => n)], [greaterThan(2 * dockSpreadRadius * .95), isTrue], reason: 'none on another, each nearer its own heap');
  });

  testWidgets('a map shows each tile where it lies, inside its circle so none covers another, in no colour of its own, the whole fitted to the room at one scale (FontMap\'s map); the one under the pointer is told, its pictures moving and its name; the one picked flown to', (t) async {
    final places = DockMapPlaces('Test')..places.value = {'a': const Offset(100, 100), 'b': const Offset(100 + 2 * dockSpreadRadius, 100), 'c': const Offset(500, 300), 'd': const Offset(900, 500)};
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 400,
          height: 300,
          child: DockMap(places, [for (final id in ['a', 'b', 'c', 'd']) (id, const SizedBox.expand())], peek: (id) => Text('moving $id'), names: const {'a': 'Box Blur'}),
        ),
      ),
    ));
    final at = {for (final id in ['a', 'b', 'c', 'd']) id: t.getRect(find.byKey(ValueKey('ws-map-Test-$id')))};
    expect([at['a']!.overlaps(at['b']!), (at['d']!.center.dx - at['a']!.center.dx) / 800 * (800 + 2 * dockSpreadRadius), find.descendant(of: find.byKey(const ValueKey('ws-map-Test')), matching: find.byType(DecoratedBox))], [isFalse, closeTo(400 * .92, .01), findsNothing], reason: 'two a tile apart side by side, the whole framed at 0.92 of the room (FontMap\'s start), no edges');
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: at['a']!.center);
    await t.pump();
    expect([find.text('Box Blur'), find.text('moving a')], [findsOneWidget, findsOneWidget], reason: 'the one under the pointer: its pictures moving and its name, by it');
    await mouse.removePointer();
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: SizedBox(width: 400, height: 300, child: DockMap(places, [for (final id in ['a', 'b', 'c', 'd']) (id, const SizedBox.expand())], picked: 'c'))),
    ));
    await t.pumpAndSettle();
    final c = t.getRect(find.byKey(const ValueKey('ws-map-Test-c'))), room = t.getRect(find.byKey(const ValueKey('ws-map-Test')));
    expect([c.center.dx, c.center.dy, c.width / at['c']!.width], [closeTo(room.center.dx, .5), closeTo(room.center.dy, .5), closeTo(4, .01)], reason: 'the one picked flown to, in the middle four times as near (FontMap\'s centerOnFont)');
  });
}
