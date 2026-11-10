// Ws, the window's state, with no engine joined: what each call changes and which aspect it tells (the counters of
// Ws.on, which decide what rebuilds). The expected values are what the code gave when this was written, so a move or a
// split that changes one fails here. What only the engine answers (stops, marks, guides, the layers read) is not here.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/state/state.dart';

/// How many times each aspect of [ws] was told while [does] ran. An aspect that was not told is left out.
Map<WsAspect, int> _told(Ws ws, void Function() does) {
  final before = {for (final a in WsAspect.values) a: ws.on[a]!.value};
  does();
  return {
    for (final a in WsAspect.values)
      if (ws.on[a]!.value - before[a]! case final times when times != 0) a: times,
  };
}

Ws _ws() {
  final ws = Ws();
  addTearDown(ws.dispose);
  return ws;
}

WsLayer _layer(String id, WsKind kind, {String? parent}) => WsLayer(id, 'Layer $id', kind, 0, 240, const [], parent: parent);

/// Group 1 holds group 2, which holds shape 3. Shape 4 is the parent of text 5 without being a group.
Ws _nested() => _ws()
  ..layers.addAll([
    _layer('1', WsKind.group),
    _layer('2', WsKind.group, parent: '1'),
    _layer('3', WsKind.shape, parent: '2'),
    _layer('4', WsKind.shape),
    _layer('5', WsKind.text, parent: '4'),
  ]);

const WsKey _a = (layer: '3', frame: 10), _b = (layer: '4', frame: 20), _c = (layer: '3', frame: 30);

void main() {
  test('a new state has nothing selected, the playhead at frame 112 and a document of 240 frames at 30 a second', () {
    final ws = _ws();
    expect((Ws.fps, Ws.duration), (30, 240));
    expect((ws.selected, ws.layer, ws.stretch, ws.aim, ws.fronted, ws.inside), (null, null, null, null, null, null));
    expect((ws.frame, ws.playing, ws.animating, ws.rev, ws.reads), (112, false, false, 0, 0));
    expect(ws.many, isEmpty);
    expect(ws.keys, isEmpty);
    expect([for (final a in WsAspect.values) ws.on[a]!.value], everyElement(0));
  });

  group('the selection', () {
    test('select tells picked once, and nothing when that layer is already the only one selected', () {
      final ws = _ws()..layers.add(_layer('3', WsKind.shape));
      var heard = 0;
      ws.addListener(() => heard++);
      expect(_told(ws, () => ws.select('3')), {WsAspect.picked: 1});
      expect((ws.selected, ws.layer?.id, heard), ('3', '3', 1));
      expect(_told(ws, () => ws.select('3')), isEmpty);
      expect(_told(ws, () => ws.select(null)), {WsAspect.picked: 1});
      expect((ws.selected, ws.layer, heard), (null, null, 2));
    });

    test('select clears the layers picked together, the keyframes, the colour aim and the tool opened by hand', () {
      final ws = _ws()
        ..pickMany(['3', '4'], inOrder: true)
        ..pickKey(_a)
        ..aim = 'stroke'
        ..openToolPanel('Ease');
      // Layer 3 is already the selected one, but others are picked with it.
      expect(_told(ws, () => ws.select('3')), {WsAspect.picked: 1});
      expect(ws.many, isEmpty);
      expect(ws.keys, isEmpty);
      expect((ws.aim, ws.toolPanelManual, ws.toolPanel), (null, null, 'Tools'));
    });

    test('pickMany replaces the layers picked together, tells picked every time, and leaves the selected layer alone', () {
      final ws = _ws()..select('9');
      expect(_told(ws, () => ws.pickMany(['3', '4'])), {WsAspect.picked: 1});
      expect(ws.many, {'3', '4'});
      expect((ws.manyInOrder, ws.selected), (false, '9'));
      expect(_told(ws, () => ws.pickMany(['4'], inOrder: true)), {WsAspect.picked: 1});
      expect(ws.many, {'4'});
      expect(ws.manyInOrder, isTrue);
    });

    test('pickKey selects the keyframe and its layer, and with add keeps the keyframes already selected', () {
      final ws = _ws()..toolPanelManual = 'Ease';
      expect(_told(ws, () => ws.pickKey(_a)), {WsAspect.picked: 1});
      expect(ws.keys, {_a});
      expect((ws.selected, ws.toolPanelManual), ('3', null));
      ws.pickKey(_b, add: true);
      expect(ws.keys, {_a, _b});
      expect(ws.selected, '4');
      ws.pickKey(_c);
      expect(ws.keys, {_c});
      expect(ws.selected, '3');
    });

    test('pickKeys selects exactly these keyframes and the layer of the first; with none, the layer stays', () {
      final ws = _ws()..select('9');
      expect(_told(ws, () => ws.pickKeys([_b, _a])), {WsAspect.picked: 1});
      expect(ws.keys, {_a, _b});
      expect(ws.selected, '4');
      expect(_told(ws, () => ws.pickKeys([])), {WsAspect.picked: 1});
      expect(ws.keys, isEmpty);
      expect(ws.selected, '4');
    });

    test('clearKeys tells picked only when a keyframe was selected, and the layer stays', () {
      final ws = _ws();
      expect(_told(ws, ws.clearKeys), isEmpty);
      ws.pickKey(_a);
      expect(_told(ws, ws.clearKeys), {WsAspect.picked: 1});
      expect(ws.keys, isEmpty);
      expect(ws.selected, '3');
    });

    test('with no engine, pickStretch selects the layer, finds no stretch and fronts nothing', () {
      final ws = _ws()..pickKey(_a);
      expect(_told(ws, () => ws.pickStretch('4', 'opacity', 10)), {WsAspect.picked: 1});
      expect(ws.keys, isEmpty);
      expect((ws.selected, ws.stretch, ws.fronted), ('4', null, null));
    });

    test('aim tells picked when it changes', () {
      final ws = _ws();
      expect(_told(ws, () => ws.aim = 'stroke'), {WsAspect.picked: 1});
      expect(_told(ws, () => ws.aim = 'stroke'), isEmpty);
      expect(ws.aim, 'stroke');
    });
  });

  group('the playhead', () {
    test('frame moves the playhead, kept inside the document, and tells no aspect', () {
      final ws = _ws();
      var moved = 0, heard = 0;
      ws.moment.addListener(() => moved++);
      ws.addListener(() => heard++);
      expect(_told(ws, () => ws.frame = 50), isEmpty);
      expect((ws.frame, ws.moment.value, moved, heard), (50, 50, 1, 0));
      ws.frame = 50;
      expect(moved, 1);
      ws.frame = -5;
      expect(ws.frame, 0);
      ws.frame = 9999;
      expect((ws.frame, moved), (Ws.duration, 3));
    });

    test('playing tells playing when it changes', () {
      final ws = _ws();
      expect(_told(ws, () => ws.playing = true), {WsAspect.playing: 1});
      expect(_told(ws, () => ws.playing = true), isEmpty);
      expect(_told(ws, () => ws.playing = false), {WsAspect.playing: 1});
      expect(ws.playing, isFalse);
    });

    test('timecode writes a frame as minutes, seconds and frames', () {
      final ws = _ws();
      expect(ws.timecode(), '00:03:22'); // The playhead: frame 112.
      expect(ws.timecode(0), '00:00:00');
      expect(ws.timecode(1830), '01:01:00');
      expect(ws.timecode(109829), '61:00:29');
    });
  });

  group('the panels', () {
    test('setView keeps a value under a name and tells view when it changes', () {
      final ws = _ws();
      expect(ws.viewOf('stage.tool', 'select'), 'select');
      expect(_told(ws, () => ws.setView('stage.tool', 'pen')), {WsAspect.view: 1});
      expect(_told(ws, () => ws.setView('stage.tool', 'pen')), isEmpty);
      expect(ws.viewOf('stage.tool', 'select'), 'pen');
      expect(_told(ws, () => ws.setView('never.set', null)), isEmpty);
      expect(ws.eye, [0, 0, 1]);
    });

    test('the working camera is the eye while a camera layer exists and the view is not through it', () {
      final ws = _ws();
      expect(ws.freeEye, isFalse);
      ws.layers.add(_layer('1', WsKind.camera));
      expect(ws.freeEye, isTrue);
      ws.setView('stage.camera', true);
      expect(ws.freeEye, isFalse);
    });

    test('front tells fronted every time and counts up, so fronting the same panel again is heard', () {
      final ws = _ws();
      expect(_told(ws, () => ws.front('Fonts')), {WsAspect.fronted: 1});
      expect(ws.fronted, ('Fonts', 1));
      expect(_told(ws, () => ws.front('Fonts')), {WsAspect.fronted: 1});
      expect(ws.fronted, ('Fonts', 2));
    });

    test('route fronts the panel a link names last', () {
      final ws = _ws()..route('Dock › Colors');
      expect(ws.fronted, ('Colors', 1));
      ws.route('Ease');
      expect(ws.fronted, ('Ease', 2));
    });

    test('openToolPanel names the tool and fronts the Tool Panel', () {
      final ws = _ws();
      expect(ws.toolPanel, 'Tools');
      expect(_told(ws, () => ws.openToolPanel('Ease')), {WsAspect.fronted: 1});
      expect((ws.toolPanelManual, ws.toolPanel, ws.fronted), ('Ease', 'Ease', ('Tool Panel', 1)));
    });

    test('notice tells notice when the text changes, and forgets what clicking the old one did', () {
      final ws = _ws();
      expect(_told(ws, () => ws.notice = 'Rendering…'), {WsAspect.notice: 1});
      ws.noticeGo = () {};
      expect(_told(ws, () => ws.notice = 'Rendering…'), isEmpty);
      expect(ws.noticeGo, isNotNull);
      expect(_told(ws, () => ws.notice = null), {WsAspect.notice: 1});
      expect((ws.notice, ws.noticeGo), (null, null));
    });

    test('stageTexture tells stage when the texture changes', () {
      final ws = _ws();
      expect(_told(ws, () => ws.stageTexture = 7), {WsAspect.stage: 1});
      expect(_told(ws, () => ws.stageTexture = 7), isEmpty);
      expect(ws.stageTexture, 7);
    });
  });

  group('the rows', () {
    test('twirl opens the lanes of the layers when none of them is open, else shuts them all, and tells animating', () {
      final ws = _ws();
      expect(_told(ws, () => ws.twirl(['3', '4'])), {WsAspect.animating: 1});
      expect((ws.lanesOpen('3'), ws.lanesOpen('4'), ws.aimsOpen('3')), (true, true, true));
      ws.twirl(['3']);
      expect((ws.lanesOpen('3'), ws.lanesOpen('4')), (false, true));
      ws.twirl(['3', '4']);
      expect((ws.lanesOpen('3'), ws.lanesOpen('4')), (false, false));
    });

    test('turnGroup opens or closes a group and its own lanes with it, and tells animating', () {
      final ws = _ws();
      expect(ws.groupOpen('1'), isFalse);
      expect(_told(ws, () => ws.turnGroup('1')), {WsAspect.animating: 1});
      expect((ws.groupOpen('1'), ws.lanesOpen('1')), (true, true));
      expect(_told(ws, () => ws.turnGroup('1')), {WsAspect.animating: 1});
      expect((ws.groupOpen('1'), ws.lanesOpen('1')), (false, false));
    });

    test('under lists everything a group holds, however deep, and nothing for another kind of layer', () {
      final ws = _nested();
      expect(ws.under('1'), ['2', '3']);
      expect(ws.under('2'), ['3']);
      expect(ws.under('4'), isEmpty);
      expect(ws.under('no such layer'), isEmpty);
    });

    test('depth counts the groups around a layer', () {
      final ws = _nested();
      expect([for (final l in ws.layers) ws.depth(l)], [0, 1, 2, 0, 0]);
    });

    test('foldedAway maps each layer a closed group hides to the outermost closed group above it', () {
      final ws = _nested();
      expect(ws.foldedAway, {'2': '1', '3': '1'});
      ws.turnGroup('1');
      expect(ws.foldedAway, {'3': '2'});
      ws.turnGroup('2');
      expect(ws.foldedAway, isEmpty);
      ws.turnGroup('1');
      expect(ws.foldedAway, {'2': '1', '3': '1'});
    });
  });

  group('the document', () {
    test('shown counts one more look at the document, forgets what changed and tells document', () {
      final ws = _ws()..lastChange = (layers: true, values: const {});
      expect(_told(ws, ws.shown), {WsAspect.document: 1});
      expect((ws.rev, ws.reads, ws.lastChange), (1, 0, null));
    });

    test('with no engine, reread reads nothing and tells nothing, and Animate stays off though it tells animating', () {
      final ws = _ws();
      expect(_told(ws, ws.reread), isEmpty);
      expect((ws.rev, ws.waiting), (0, false));
      expect(_told(ws, () => ws.animating = true), {WsAspect.animating: 1});
      expect(ws.animating, isFalse);
    });

    test('fxFiles splits an effect list into its files, keeping the spaces inside a path that starts with /', () {
      expect(Ws.fxFiles(''), isEmpty);
      expect(Ws.fxFiles('none'), isEmpty);
      expect(Ws.fxFiles('blur.wgsl glow.fs'), ['blur.wgsl', 'glow.fs']);
      expect(Ws.fxFiles('/Users/me/My Effects/soft glow.wgsl /lib/tint.fs'), ['/Users/me/My Effects/soft glow.wgsl', '/lib/tint.fs']);
      expect(Ws.fxFiles('none /a b/c.json'), ['/a b/c.json']);
      expect(Ws.fxFiles('/x/script.anm2@Track1 /y/z.js'), ['/x/script.anm2@Track1', '/y/z.js']);
    });
  });

  test('dispose shuts the playhead and the counter of every aspect', () {
    final ws = Ws()..dispose();
    expect(() => ws.moment.addListener(() {}), throwsFlutterError);
    for (final a in WsAspect.values) {
      expect(() => ws.on[a]!.addListener(() {}), throwsFlutterError, reason: a.name);
    }
  });
}
