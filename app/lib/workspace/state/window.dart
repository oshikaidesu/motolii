// Part of state.dart: the workspace state every panel reads (Ws).
part of 'state.dart';

/// A sound: a film whose file has no picture, hidden and heard (doc_add), Alight Motion's audio layer: docs/internal/reports/alight_motion/alight_ui.md 177.
bool wsSound(Motolii m, int t) => m.word(t, 'kind') == 'film' && m.kindOf(m.word(t, 'file')) == 'sound';

class Ws extends ChangeNotifier {
  /// Each aspect told on its own (a Flutter ValueNotifier: what listens to one hears only it).
  late final on = {for (final a in WsAspect.values) a: ValueNotifier<int>(0)};
  void _tell(WsAspect a) {
    if (a == WsAspect.picked || a == WsAspect.document) _watch(); // (what the inside puts in the moment's picture follows what is picked)
    on[a]!.value++;
    notifyListeners(); // (WsScope's own: it says which aspects to the parts below)
  }

  final layers = <WsLayer>[];

  /// The composition's rate and length in frames (the sample's; a joined document's own length).
  static int fps = 30, duration = 240;

  /// The inside this window is joined to (motolii.dart), if it is: the layers are then the document's things, a
  /// change is a call to it, and the playhead is its moment. null: the sample's mock document.
  Motolii? _inside;
  Motolii? get inside => _inside;
  void join(Motolii inside) {
    _inside = inside;
    inside.shaping; // (read once, at the opening: what a card is made by)
    inside.listener = ({required document, required moment, required cache}) {
      // (the inside's pictures are new: docs/app/BRIDGE.md)
      if (_gone) return;
      if (document) reread();
      if (moment) seen.value++;
    };
    fps = _fpsOf(inside); // (a frame is the document's: the timeline counts what a written film has)
    WsArt.comp = Size(inside.size.$1.toDouble(), inside.size.$2.toDouble());
    moment.value = (inside.now * fps).round(); // (the playhead is the inside's moment from the first)
    reread();
  }

  /// Joined: the document's name, and how the window is told to open it again at another size (the host does it).
  String? document;
  String? documentFolder; // (where the document's file is: the dock offers it, so a new document is one step from its footage)
  void Function(int wide, int high)? onSize;
  VoidCallback? refit;

  String? _notice;
  String? get notice => _notice;
  Timer? _noticeEnds;
  set notice(String? said) {
    if (said == _notice) return;
    _notice = said;
    _noticeEnds?.cancel();
    if (said != null && !said.endsWith('…')) {
      _noticeEnds = Timer(
        const Duration(seconds: 10),
        () => notice = null,
      ); // (said for a moment, Material's snackbar: four to ten seconds; what is still going on, "…", stays)
    }
    _tell(WsAspect.notice);
  }

  /// How many times the document has been read again.
  int rev = 0;

  /// How many times the document has been read again (not counting what a hand only carries): what is made from its
  /// shape (the cards) is made again when this moves.
  int reads = 0;

  /// Where a bar ends, in frames: a thing on for good runs to the document's end.
  static int _outF(int from, double lasts) => lasts < 0 ? duration : (from + (lasts * fps).round()).clamp(from + 1, duration);

  bool _gone = false;
  final seen = ValueNotifier<int>(0);

  @override
  void dispose() {
    _gone = true;
    _noticeEnds?.cancel();
    seen.dispose();
    moment.dispose();
    for (final n in on.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// What the inside shows changed without the document changing (a thing held and carried): the panels look again.
  void shown() {
    lastChange = null; // (not a step of the document: what it changed is not known)
    rev++;
    _tell(WsAspect.document);
  }

  /// The document read again, after any change to it: what the panels list is what the document holds.
  /// The document's frame rate (its `frame_rate`, the stage's own), or the inside's when it says none.
  static int _fpsOf(Motolii m) => switch ((m.value(0, 'frame_rate', 0) ?? 0).round()) {
    > 0 && final r => r,
    _ => m.rate,
  };
  void reread() => Timeline.timeSync('ws reread', _reread); // (named in Flutter's timeline)
  void _reread() {
    final m = _inside;
    if (m == null) return;
    if (!m.fits && refit != null) return refit!(); // (the document says another size, by a hand or by undo: the host opens it again, and that reads it)
    lastChange = m.changes();
    if (_fpsOf(m) != fps) {
      // (the document's frame rate said again: the playhead kept where it is in time)
      final at = moment.value / fps;
      fps = _fpsOf(m);
      moment.value = (at * fps).round();
    }
    rev++;
    reads++;
    duration = Timeline.timeSync('MARK seconds', () => (m.seconds * fps).round().clamp(1, 1 << 20));
    final tl = TimelineTask()..start('MARK layers');
    final holding = {for (final t in m.layers) (m.value(t, 'parent', 0) ?? 0).round()}; // (who has things going with it)
    layers
      ..clear()
      ..addAll([
        for (final t in m.layers.reversed) // (the sample's manner: the nearest thing is the top row)
          () {
            final kind = m.word(t, 'kind'), from = ((m.value(t, 'start', 0) ?? 0) * fps).round(), lasts = m.lasts(t);
            final name = m.word(t, 'name'); // (what it is called is the inside's to say)
            // (a key on any value of it that takes keys is a key on its bar: the inside says which those are)
            final keys = <int>{for (final s in m.layerKeyTimes(t)) (s * fps).round()}.toList()..sort();
            return WsLayer(
              '$t',
              name,
              switch (kind) {
                'text' => WsKind.text,
                'camera' => WsKind.camera,
                'film' when wsSound(m, t) => WsKind.audio,
                'film' || 'picture' => WsKind.image,
                'shape' when m.word(t, 'shape') == 'null' && holding.contains(t) => WsKind.group,
                _ => WsKind.shape,
              },
              from,
              _outF(from, lasts),
              keys,
              solo: (m.value(t, 'solo', 0) ?? 0) > .5,
            );
          }(),
      ]);
    if (_sel != null && layers.every((l) => l.id != _sel)) {
      _sel = layers.firstOrNull?.id; // (a picked thing gone: the first; nothing picked stays so, the stage's)
    }
    _keys.removeWhere((k) => !layers.any((l) => l.id == k.layer && l.keys.contains(k.frame))); // (a picked key stays picked while it is still there)
    if (_stretch case final s?) _stretch = _stretchOf(s.layer, s.name, s.from); // (and a picked stretch: to where that value's next key now is)
    tl.finish();
    _tell(WsAspect.document);
  }

  /// The things whose moving values the window shows (told the inside: Motolii.subscribe): the picked one and those picked
  /// with it, the cameras (the Depth tool panel's lens), the relations (the Relations tool panel's map), and a picked relation's things.
  void _watch() {
    final m = _inside;
    if (m == null) return;
    final sel = int.tryParse(_sel ?? '');
    m.subscribe({
      ?sel,
      for (final id in many) ?int.tryParse(id),
      for (final l in layers)
        if (l.kind == WsKind.camera) ?int.tryParse(l.id),
      for (final l in layers)
        if (int.tryParse(l.id) case final t? when m.word(t, 'kind') == 'behaviour')
          t, // (the relations: the Relations tool panel draws each by its knobs, at the moment)
      if (sel != null && m.word(sel, 'kind') == 'behaviour')
        for (final w in m.word(sel, 'members').split(' ')) ?int.tryParse(w),
    });
  }

  String? _sel; // (nothing picked, as a document opens)
  String? get selected => _sel;
  WsLayer? get layer => layers.where((l) => l.id == _sel).firstOrNull;

  /// The things picked together: what a relation is made of. Picking one alone clears them.
  final many = <String>{};
  final _keys = <WsKey>{};
  Set<WsKey> get keys => _keys;

  /// The stretch picked by its line, as Theatre.js's connector between two keyframes is pressed to edit its curve
  /// (BasicKeyframeConnector.tsx, Apache-2.0): one value's, where a key is every value's there.
  WsStretchPicked? _stretch;
  WsStretchPicked? get stretch => _stretch;

  /// The playhead, told on its own (Flutter's ValueNotifier): only what shows the moment listens ([WsScope.frameOf]),
  /// the rest of the window is not built again as it moves.
  final moment = WsMomentNow(112);
  int get frame => moment.value;
  set frame(int f) {
    final v = f.clamp(0, duration);
    if (v == moment.value) return;
    moment.value = v;
    if (!_playing) _inside?.at(v / fps); // (standing: the stage goes to the moment the playhead is put at)
  }

  bool _playing = false;
  bool get playing => _playing;
  set playing(bool p) {
    if (p == _playing) return;
    _playing = p;
    if (p) _inside?.at(frame / fps);
    _inside?.play(p); // (the inside keeps the clock; the playhead follows its moment)
    if (!p) _inside?.at(frame / fps); // (its clock runs ahead of a stage that is late with its pictures: stopped, it stands where the hand sees it)
    _tell(WsAspect.playing);
  }

  /// How the window looks, by name ('fold.Transform'...): what a pane keeps of itself that is not the document's.
  final view = <String, Object?>{};

  /// Joined: whether every change a hand makes is keyed (the inspector's Animate all: one truth, the inside's).
  bool get animating => _inside?.keyingNow ?? false;

  /// Where the hand comes to rest and J and K go: the marks and the other things' ends and keys.
  List<(double, String)> get marks => _inside!.marks;
  Set<int> stops({Set<String> skip = const {}}) => {
    for (final (at, _) in marks) (at * fps).round(),
    for (final l in layers)
      if (!skip.contains(l.id)) ...[l.inF, l.outF, ...l.keys],
  };
  set animating(bool on) {
    _inside?.keying(on);
    _tell(WsAspect.animating);
  }

  /// Joined: a change asked without waiting ([Motolii.later]): looked at once a picture till the inside has done it, then
  /// the document read again and [then] told (done or not, and why not). The window never stands still for the inside.
  /// Joined: what the steps changed that the last reading of the document took in (null: not known, as after a hand's
  /// carry): a panel that shows only some values builds itself again only when they are among these.
  ({bool layers, Set<(int, String)> values})? lastChange;

  int _afters = 0; // (tickets still looked at: the document is read again once, when the last of them is done)

  /// Whether changes told to the inside are not all done yet (the window shows them before the document has them).
  bool get waiting => _afters > 0;
  void after(int ticket, [void Function(bool done, String why)? then, void Function(int answer)? got]) {
    final m = _inside;
    if (m == null) return;
    _afters++;
    m.answered(ticket).then((r) {
      // (told by the inside when it is done: nothing looked at each picture)
      final (a, why) = r;
      then?.call(a >= 1, why);
      if (a >= 1) got?.call(a); // (an add's or a make's answer: the new thing)
      _afters--; // (what it changed comes with the inside's next picture of the document)
    });
  }

}
