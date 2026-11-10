// The workspace state that every panel reads (WorkspaceController): the document's layers as rows, the selection, the playhead and the view.
// What is applied to the canvas is in effects.dart.
import 'dart:async' show Timer;
import 'dart:developer' show Timeline, TimelineTask;
import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_shelves.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/layer_colors.dart';
import 'package:motolii/workspace/easing/ease_curve.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/composition_settings.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';

/// Whether layer [t] is a sound: a video layer whose file has no image, hidden and only heard (see doc_add).
/// Like Alight Motion's audio layer (docs/design/alight_motion_ui.md).
bool isSoundLayer(Motolii m, int t) =>
    m.word(t, 'kind') == 'film' && m.kindOf(m.word(t, 'file')) == 'sound';

/// The window's state: the document's layers as rows (read from the engine), the selection, the playhead and the view.
/// Every panel listens to this and nothing else, and never keeps a copy of it.
/// Changes notify once per user action. Nothing ticks while idle; the playhead advances only while [playing].
class WorkspaceController extends ChangeNotifier {
  /// One counter per aspect, so a listener of one aspect never hears the others.
  late final on = {
    for (final a in WorkspaceAspect.values) a: ValueNotifier<int>(0),
  };
  void _tell(WorkspaceAspect a) {
    if (a == WorkspaceAspect.picked || a == WorkspaceAspect.document) _watch();
    on[a]!.value++;
    notifyListeners(); // WorkspaceScope passes the aspect on to the widgets below.
  }

  final layers = <Layer>[];

  // One for the whole app, because widgets read the three getters below without a controller at hand.
  static final _composition = CompositionSettings();

  /// The composition's frame rate and length in frames. After [join] they come from the document.
  static int get fps => _composition.frameRate;
  static int get duration => _composition.duration;

  /// The composition's size in pixels. After [join] it is the document's own size.
  static Size get comp => _composition.size;

  /// The engine this window is connected to (see motolii.dart), or null for the sample document.
  /// When connected, the layers are the document's layers, a change is a call to the engine, and the playhead is its time.
  Motolii? _inside;
  Motolii? get inside => _inside;

  void join(Motolii inside) {
    _inside = inside;
    inside.shaping; // Read once at opening: it decides how cards are built.
    inside.listener = ({required document, required moment, required cache}) {
      // The engine has a new snapshot, see docs/app/BRIDGE.md.
      if (_gone) return;
      if (cache) this.kept.value = inside.cache;
      if (document) reread();
      if (moment) seen.value++;
    };
    // The timeline counts frames at the document's rate, as the exported video does.
    _composition.frameRate = _fpsOf(inside);
    _composition.size = Size(
      inside.size.$1.toDouble(),
      inside.size.$2.toDouble(),
    );
    moment.value = (inside.now * fps)
        .round(); // The playhead starts at the engine's time.
    reread();
    final kept =
        inside.settings; // Choices saved with the document: its inks and fonts.
    _ink = kept['ink'] ?? '';
    _edge = kept['edge'] ?? '';
    _inkBlend = kept['ink_blend'] ?? '';
    _titleFont = kept['title_font'] ?? '';
    _bodyFont = kept['body_font'] ?? '';
  }

  /// The document's name.
  String? document;

  /// The folder holding the document's file. The dock offers it, so a new document is one step from its footage.
  String? documentFolder;

  /// Host callbacks: reopen the document at another size, refit it, and export it as a video.
  void Function(int wide, int high)? onSize;
  VoidCallback? refit;
  VoidCallback? onRender;

  /// Where the next export is written. Set by the settings window; null means the window's default.
  String? renderTo;

  /// The inks the drawing tools give a new layer: fill, stroke colour and gradient blend (gradient_blend).
  /// An empty string means the document's own, or sRGB. Saved with the document but not undo steps, like a PowerPoint theme.
  String _ink = '', _edge = '', _inkBlend = '';
  String get ink => _ink;
  set ink(String v) => _ink = _kept('ink', _ink, v);
  String get edge => _edge;
  set edge(String v) => _edge = _kept('edge', _edge, v);
  String get inkBlend => _inkBlend;
  set inkBlend(String v) => _inkBlend = _kept('ink_blend', _inkBlend, v);
  String _kept(String name, String was, String now) {
    if (now != was) _inside?.later('setting', name: name, word: now);
    return now;
  }

  /// The fonts for a new title and a new body text, and which of the two the Fonts shelf sets ([fontRole]).
  /// Modelled on PowerPoint's theme fonts and Canva's brand fonts. An empty string means the default font.
  /// Saved with the document, like a PowerPoint theme.
  String _titleFont = '', _bodyFont = '', fontRole = 'title';
  String get titleFont => _titleFont;
  set titleFont(String v) => _titleFont = _kept('title_font', _titleFont, v);
  String get bodyFont => _bodyFont;
  set bodyFont(String v) => _bodyFont = _kept('body_font', _bodyFont, v);
  String get bodyFace => bodyFont.isEmpty ? defaultTextFont : bodyFont;
  String get titleFace => titleFont.isEmpty ? bodyFace : titleFont;

  String? _notice;
  String? get notice => _notice;
  Timer? _noticeEnds;

  /// The frames where sounds strike, as the timeline last computed them for its beats.
  List<int> strikes = const [];

  /// What clicking the notice does while it is shown. A time in it is a place to go to, like a YouTube timestamp.
  void Function()? noticeGo;
  set notice(String? said) {
    if (said == _notice) return;
    _notice = said;
    noticeGo = null;
    _noticeEnds?.cancel();
    // Disappears after ten seconds like a Material snackbar, unless it ends in "…" (work still going on).
    if (said != null && !said.endsWith('…')) {
      _noticeEnds = Timer(const Duration(seconds: 10), () => notice = null);
    }
    _tell(WorkspaceAspect.notice);
  }

  /// How many times the document has been read again.
  int rev = 0;

  /// Like [rev] but without drags. Things built from the document's structure, such as the cards, rebuild when it changes.
  int reads = 0;

  static T timed<T>(String name, T Function() does) =>
      Timeline.timeSync(name, does);

  // A layer that lasts forever (negative [lasts]) runs to the document's end.
  static int _outF(int from, double lasts) => lasts < 0
      ? duration
      : (from + (lasts * fps).round()).clamp(from + 1, duration);

  /// Reads layer [id]'s bar from the engine again, for example during a drag, so the drawn bar matches the engine.
  void respan(String id) {
    final m = _inside,
        l = layers.where((l) => l.id == id).firstOrNull,
        t = int.tryParse(id);
    if (m == null || l == null || t == null) return;
    l.inF = ((m.value(t, 'start', 0) ?? 0) * fps).round();
    l.outF = _outF(l.inF, m.lasts(t));
    shown();
  }

  bool _gone = false;
  final seen = ValueNotifier<int>(0);

  /// The frame ranges cached on disk for playback. The timeline marks them like After Effects' green line.
  final kept = ValueNotifier<List<(int, int)>>(const []);

  @override
  void dispose() {
    _gone = true;
    _noticeEnds?.cancel();
    seen.dispose();
    kept.dispose();
    moment.dispose();
    for (final n in on.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// Tells the panels to look again after the engine's view changed without the document changing, such as during a drag.
  void shown() {
    lastChange = null; // This is not an undo step, so what changed is unknown.
    rev++;
    _tell(WorkspaceAspect.document);
  }

  /// The document's tempo in beats per minute (0 for none), and its beat grid.
  double get bpm => _inside?.value(0, 'bpm', 0) ?? 0;
  Beats? get beats => bpm > 0
      ? Beats(
          (_inside?.value(0, 'bpm_from', 0) ?? 0) * WorkspaceController.fps,
          60 / bpm * WorkspaceController.fps,
        )
      : null;

  static int _fpsOf(Motolii m) =>
      switch ((m.value(0, 'frame_rate', 0) ?? 0).round()) {
        > 0 && final r => r,
        _ => m.rate,
      };

  /// Reads the document again after any change, so the panels list what the document holds.
  void reread() => Timeline.timeSync('ws reread', _reread);
  void _reread() {
    final m = _inside;
    if (m == null) return;
    // The document now has another size, from an edit or an undo. The host reopens it, which reads it again.
    if (!m.fits && refit != null) return refit!();
    lastChange = m.changes();
    if (_fpsOf(m) != fps) {
      // The frame rate changed. Keep the playhead at the same time.
      final at = moment.value / fps;
      _composition.frameRate = _fpsOf(m);
      moment.value = (at * fps).round();
    }
    rev++;
    reads++;
    _composition.duration = Timeline.timeSync(
      'MARK seconds',
      () => (m.seconds * fps).round().clamp(1, 1 << 20),
    );
    chosenLabelColors
      ..clear()
      ..addAll({
        for (final t in m.layers)
          if (m.words(t, 'label').indexOf(m.word(t, 'label')) case final i
              when i > 0)
            '$t': i - 1,
      });
    final tl = TimelineTask()..start('MARK layers');
    final holding = {
      for (final t in m.layers) (m.value(t, 'parent', 0) ?? 0).round(),
    }; // The ids of layers that are parents.
    layers
      ..clear()
      ..addAll([
        for (final t
            in m
                .layers
                .reversed) // The topmost layer comes first, as in the sample.
          () {
            final kind = m.word(t, 'kind'),
                from = ((m.value(t, 'start', 0) ?? 0) * fps).round(),
                lasts = m.lasts(t);
            final name = m.word(t, 'name');
            // A keyframe on any animatable property shows as a keyframe on the bar. The engine says which properties those are.
            final keys = <int>{
              for (final s in m.layerKeyTimes(t)) (s * fps).round(),
            }.toList()..sort();
            return Layer(
              '$t',
              name,
              switch (kind) {
                'text' => LayerKind.text,
                'camera' => LayerKind.camera,
                'film' when isSoundLayer(m, t) => LayerKind.audio,
                'film' || 'picture' => LayerKind.image,
                'shape'
                    when m.word(t, 'shape') == 'null' && holding.contains(t) =>
                  LayerKind.group,
                _ => LayerKind.shape,
              },
              from,
              _outF(from, lasts),
              keys,
              parent: switch ((m.value(t, 'parent', 0) ?? 0).round()) {
                > 0 && final p => '$p',
                _ => null,
              },
              lined:
                  (kind == 'picture' || kind == 'solid') &&
                  m.values(t).any((n) => n.startsWith('js_line_')),
              hidden: (m.value(t, 'visible', 0) ?? 1) < .5,
              solo: (m.value(t, 'solo', 0) ?? 0) > .5,
              locked: (m.value(t, 'lock', 0) ?? 0) > .5,
              clipped: (m.value(t, 'clip', 0) ?? 0) > .5,
              stretches: [
                for (final (a, b, way) in m.layerStretches(t))
                  (
                    from: (a * fps).round(),
                    to: (b * fps).round(),
                    way: way,
                    shape: easeCurve(way, m),
                  ),
              ],
            );
          }(),
      ]);
    if (_sel != null && layers.every((l) => l.id != _sel)) {
      // The selected layer is gone: select the first. With nothing selected, the selection stays empty.
      _sel = layers.firstOrNull?.id;
    }
    // A selected keyframe stays selected while it exists; a selected stretch moves to that property's next keyframe.
    _keys.removeWhere(
      (k) => !layers.any((l) => l.id == k.layer && l.keys.contains(k.frame)),
    );
    if (_stretch case final s?) _stretch = _stretchOf(s.layer, s.name, s.from);
    tl.finish();
    _tell(WorkspaceAspect.document);
  }

  /// The engine's preview as a Flutter texture id, when connected. Null means the stand-in artwork.
  int? _stageTexture;
  int? get stageTexture => _stageTexture;
  set stageTexture(int? id) {
    if (id == _stageTexture) return;
    _stageTexture = id;
    _tell(WorkspaceAspect.stage);
  }

  /// Tells the engine (Motolii.subscribe) which layers' changing values to report: the selected layers, the cameras for the
  /// Depth tool panel, the relations for the Relations tool panel's map, and the members of a selected relation.
  void _watch() {
    final m = _inside;
    if (m == null) return;
    final sel = int.tryParse(_sel ?? '');
    m.subscribe({
      ?sel,
      for (final id in many) ?int.tryParse(id),
      for (final l in layers)
        if (l.kind == LayerKind.camera) ?int.tryParse(l.id),
      for (final l in layers)
        if (int.tryParse(l.id) case final t?
            when m.word(t, 'kind') == 'behaviour')
          t, // Relations: the Relations tool panel draws each from its parameters at the current time.
      if (sel != null && m.word(sel, 'kind') == 'behaviour')
        for (final w in m.word(sel, 'members').split(' ')) ?int.tryParse(w),
    });
  }

  String? _sel; // Nothing is selected when a document opens.
  String? get selected => _sel;
  Layer? get layer => layers.where((l) => l.id == _sel).firstOrNull;

  /// The layers selected together, outlined in the preview. A relation is made of them. Selecting one layer clears them.
  /// [manyInOrder] is true when they were picked one by one, so the first leads; a box selection has no order.
  final many = <String>{};
  bool manyInOrder = false;
  final _keys = <SelectedKeyframe>{};
  Set<SelectedKeyframe> get keys => _keys;

  /// The stretch selected by clicking its line, like Theatre.js's connector between two keyframes
  /// (BasicKeyframeConnector.tsx, Apache-2.0). It belongs to one property, whereas a keyframe covers every property at that time.
  StretchPicked? _stretch;
  StretchPicked? get stretch => _stretch;

  /// Selects the layer [id], or clears the selection when null.
  void select(String? id) {
    if (id == _sel && many.isEmpty) return;
    _sel = id;
    many.clear();
    _aim = null;
    _keys.clear();
    _stretch = null;
    toolPanelManual = null;
    _tell(WorkspaceAspect.picked);
  }

  /// Selects several layers. With [inOrder] the first one leads.
  void pickMany(Iterable<String> ids, {bool inOrder = false}) {
    many
      ..clear()
      ..addAll(ids);
    manyInOrder = inOrder;
    _tell(WorkspaceAspect.picked);
  }

  /// Selects one keyframe, or adds it to the selection when [add] is true.
  void pickKey(SelectedKeyframe k, {bool add = false}) {
    if (!add) _keys.clear();
    _keys.add(k);
    _stretch = null;
    _sel = k.layer;
    toolPanelManual = null;
    _tell(WorkspaceAspect.picked);
  }

  /// Selects exactly these keyframes, for example after a box selection.
  void pickKeys(Iterable<SelectedKeyframe> ks) {
    _keys
      ..clear()
      ..addAll(ks);
    _stretch = null;
    if (_keys.isNotEmpty) _sel = _keys.first.layer;
    toolPanelManual = null;
    _tell(WorkspaceAspect.picked);
  }

  /// Deselects all keyframes and the selected stretch.
  void clearKeys() {
    if (_keys.isEmpty && _stretch == null) return;
    _keys.clear();
    _stretch = null;
    _tell(WorkspaceAspect.picked);
  }

  StretchPicked? _stretchOf(String layer, String name, int from) {
    final t = int.tryParse(layer),
        at = t == null
            ? const <double>[]
            : _inside?.keyTimes(t, name) ?? const <double>[];
    final i = at.indexWhere(
      (s) => (s * WorkspaceController.fps).round() == from,
    );
    return i < 0 || i + 1 >= at.length
        ? null
        : (
            layer: layer,
            name: name,
            at: at[i],
            from: from,
            to: (at[i + 1] * WorkspaceController.fps).round(),
          );
  }

  /// Selects the stretch of property [name] on [layer] that starts at frame [from], and shows the Ease panel.
  void pickStretch(String layer, String name, int from) {
    _keys.clear();
    _stretch = _stretchOf(layer, name, from);
    _sel = layer;
    toolPanelManual = null;
    _tell(WorkspaceAspect.picked);
    if (_stretch != null) front('Ease');
  }

  /// The playhead frame. It is a separate notifier, so only widgets that show the current time listen to it
  /// ([WorkspaceScope.frameOf]) and the rest of the window is not rebuilt as it moves.
  final moment = ValueNotifier<int>(112);
  int get frame => moment.value;
  set frame(int f) {
    final v = f.clamp(0, duration);
    if (v == moment.value) return;
    moment.value = v;
    if (!_playing) {
      _inside?.at(v / fps); // While stopped, the preview jumps to the new time.
    }
  }

  bool _playing = false;
  bool get playing => _playing;
  set playing(bool p) {
    if (p == _playing) return;
    _playing = p;
    if (p) _inside?.at(frame / fps);
    _inside?.play(p); // The engine keeps the clock and the playhead follows it (see timeline.dart).
    // The clock can run ahead of a preview that is late with its frames, so on stop it returns to the playhead.
    if (!p) _inside?.at(frame / fps);
    _tell(WorkspaceAspect.playing);
  }

  /// View state by name ('stage.tool', 'fold.Transform'): what a panel keeps of itself that is not part of the document.
  final view = <String, Object?>{};
  T viewOf<T>(String name, T otherwise) => view[name] as T? ?? otherwise;
  void setView(String name, Object? value) {
    if (view[name] == value) return;
    view[name] = value;
    _tell(WorkspaceAspect.view);
  }

  /// Whether the preview uses the working camera, not the document's camera layer (AbsentMotion's cameraMode off).
  bool get freeEye =>
      !viewOf('stage.camera', false) &&
      layers.any((l) => l.kind == LayerKind.camera);

  /// The working camera's position as an orbit around the world's centre: yaw, pitch and distance.
  List<double> get eye => viewOf('stage.eye', const [0.0, 0.0, 1.0]);

  /// The tool the user opened in the tool panel. Null lets the tool panel follow the selection.
  String? toolPanelManual;

  /// Every tab in the window, set once by Workspace. The tool panel's catalog is the tabs that do not start in a strip.
  List<Pane> panes = const [];
  List<Pane> get tools => [
    for (final p in panes)
      if (p.at == PaneStrip.catalog) p,
  ];
  void openToolPanel(String? name) {
    toolPanelManual = name;
    front('Tool Panel');
  }

  /// Brings a panel to the front of its tabs (the panels follow, see panes.dart).
  void front(String pane) {
    fronted = (pane, (fronted?.$2 ?? 0) + 1);
    _tell(WorkspaceAspect.fronted);
  }

  (String, int)? fronted;

  String get toolPanel => toolPanelManual ?? 'Tools';

  /// The property that a colour picked on the Colors shelf is written to, on the selected layer or the canvas.
  /// A card's colour link or the tool strip's ink or edge sets it; null means the fill. It notifies as a selection.
  String? _aim;
  String? get aim => _aim;
  set aim(String? to) {
    if (to == _aim) return;
    _aim = to;
    _tell(WorkspaceAspect.picked);
  }

  /// Handles a link from another panel to a panel (fonts, colours, ease): the dock or tool panel shows it.
  void route(String to) => front(to.split('›').last.trim());

  /// The shelf effects on layer [id]: those whose card the engine shows. An effect's card shows while the effect is on.
  List<String> fxOf(String? id) {
    final m = _inside, t = int.tryParse(id ?? '');
    if (m == null || t == null) return const [];
    final shown = {for (final (title, _) in m.cards(t)) title};
    return [
      for (final (name, _) in m.layerEffects)
        if (shown.contains(name)) name,
    ];
  }

  /// Whether every change the user makes is keyframed. The top bar's Animate and the inspector's Animate all share it; the engine owns it.
  bool get animating => _inside?.keyingNow ?? false;

  (double, double) get work => _inside!.work;
  List<(double, String)> get marks => _inside!.marks;

  /// The frames that dragging snaps to and that J and K jump to, like Alight Motion's snapTargets: the marks, the
  /// other layers' ends and keyframes, and a sound's strikes (the beat marks CapCut's bars snap to).
  Set<int> stops({Set<String> skip = const {}}) => {
    for (final (at, _) in marks) (at * fps).round(),
    for (final l in layers)
      if (!skip.contains(l.id)) ...[l.inF, l.outF, ...l.keys],
    ...strikes,
  };
  Map<double, int> get markColors => _inside!.markColors;
  List<(String, double)> get guides => _inside!.guides;
  set animating(bool on) {
    _inside?.keying(on);
    if (!on) _lanesShut.clear();
    _tell(WorkspaceAspect.animating);
  }

  // Which layers show their keyframed properties in lanes under their rows. The user opens them (After Effects' twirl,
  // Ableton's unfolded track). With Animate on, every layer is open and only the ones the user shut are tracked.
  final _lanesOpen = <String>{}, _lanesShut = <String>{};
  bool lanesOpen(String id) =>
      animating ? !_lanesShut.contains(id) : _lanesOpen.contains(id);
  // Whether the user opened the lanes of what a relation aims at. Animate opens keyframe lanes only.
  bool aimsOpen(String id) =>
      _lanesOpen.contains(id) && !_lanesShut.contains(id);
  void twirl(Iterable<String> ids) {
    final open = ids.any(lanesOpen), s = animating ? _lanesShut : _lanesOpen;
    open == animating ? s.addAll(ids) : s.removeAll(ids);
    _tell(WorkspaceAspect.animating);
  }

  // The open groups. A closed group is one row, like a precomposed layer or Alight Motion's group (the triangle is
  // Apple Motion's and Cavalry's). Only the rows fold; the document does not know and the file does not save it.
  final _groupsOpen = <String>{};
  bool groupOpen(String id) => _groupsOpen.contains(id);
  void turnGroup(String id) {
    if (!_groupsOpen.remove(id)) _groupsOpen.add(id);
    // The group's own keyframe lanes follow it: one triangle per row, as in Apple Motion.
    _groupsOpen.contains(id) ? _lanesOpen.add(id) : _lanesOpen.remove(id);
    _tell(WorkspaceAspect.animating);
  }

  Iterable<Layer> _over(Layer l, Map<String, Layer> of) sync* {
    var p = of[l.parent];
    for (var n = 0; p != null && n < 64; p = of[p.parent], n++) {
      // The limit of 64 matches Group's walk up the parents in stage_view_2.dart.
      yield p;
    }
  }

  /// Each layer hidden by a closed group, mapped to the row standing for it: the outermost closed group above it (Cavalry marks that row).
  Map<String, String> get foldedAway {
    final of = {for (final l in layers) l.id: l}, away = <String, String>{};
    for (final l in layers) {
      for (final p in _over(l, of)) {
        if (p.kind == LayerKind.group && !groupOpen(p.id)) away[l.id] = p.id;
      }
    }
    return away;
  }

  /// The ids of everything a group holds, however deep. Empty for other layers (see doc_under).
  List<String> under(String id) {
    final of = {for (final l in layers) l.id: l};
    if (of[id]?.kind != LayerKind.group) return const [];
    return [
      for (final l in layers)
        if (_over(l, of).any((p) => p.id == id)) l.id,
    ];
  }

  /// How many groups contain layer [l]. Its row is indented by that many levels.
  int depth(Layer l) => _over(l, {
    for (final x in layers) x.id: x,
  }).where((p) => p.kind == LayerKind.group).length;

  /// What the undo steps changed since the last read (null when unknown, as after a drag).
  /// A panel showing only some properties rebuilds only when they are among these.
  ({bool layers, Set<(int, String)> values})? lastChange;

  // Requests still pending. The document is read again once, when the last one finishes.
  int _afters = 0;

  /// Whether requests sent to the engine are still pending. The window shows them before the document has them.
  bool get waiting => _afters > 0;

  /// Waits without blocking for a request made with [Motolii.later], then reads the document again and calls
  /// [then] with whether it succeeded and why not. [got] receives the answer, such as the id of a new layer.
  void after(
    int ticket, [
    void Function(bool done, String why)? then,
    void Function(int answer)? got,
  ]) {
    final m = _inside;
    if (m == null) return;
    _afters++;
    m.answered(ticket).then((r) {
      final (a, why) = r;
      then?.call(a >= 1, why);
      if (a >= 1) got?.call(a);
      _afters--; // What it changed arrives with the engine's next snapshot.
    });
  }

  // Splits an effect list the way the engine reads it: a path, spaces included, up to its extension (see script_files in script.h).
  static final _files = RegExp(
    r'/.*?\.(?:(?:wgsl|fs|js|mjs|json|am)(?= |$)|(?:anm2|obj2)[^ ]*)|[^ ]+',
  );

  static List<String> fxFiles(String fx) => [
    for (final f in _files.allMatches(fx).map((m) => m[0]!))
      if (f != 'none') f,
  ];

  // Whether an effect is being previewed on the selected layer while the pointer is on its tile (see doc_carry_effect).
  // The preview is not part of the document and ends when the pointer leaves, and before any apply. Final Cut Pro's
  // effects browser and DaVinci Resolve's Live Preview work the same way. With nothing selected, nothing is shown.
  bool trying = false;
  String timecode([int? f]) {
    final v = f ?? frame, s = v ~/ fps, fr = v % fps;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}:${fr.toString().padLeft(2, '0')}';
  }
}

/// The font a new text layer uses: one that every machine of the platform has. The Create shelf and the preview's text tool share it.
final defaultTextFont = Platform.isWindows
    ? 'C:/Windows/Fonts/arial.ttf'
    : '/System/Library/Fonts/Supplemental/Arial Unicode.ttf';

/// Applies the chosen inks to the layer just added (layer -1), wherever it was added from, including the Fonts and Create shelves.
/// A text or a flat shape takes all the inks, because the preview draws only those. A line takes its colour only.
void applyChosenInks(WorkspaceController ws, String kind, String shape) {
  final m = ws.inside;
  if (m == null || !(kind == 'text' || kind == 'shape' && shape != 'null')) {
    return;
  }
  final line = shape == 'line';
  if (ws.ink.isNotEmpty) m.later('say', layer: -1, name: 'fill', word: ws.ink);
  // With no ink chosen, a shape gets a random colour as in Alight Motion (AbsentMotion's addShape, randomColor): any hue,
  // saturation 0.3 to 0.8, value 0.55 to 1. It is written to the document so the Inspector and Colors shelf show it.
  if (ws.ink.isEmpty && kind == 'shape') {
    final r = math.Random(),
        c = HSVColor.fromAHSV(
          1,
          r.nextDouble() * 360,
          .3 + r.nextDouble() * .5,
          .55 + r.nextDouble() * .45,
        ).toColor();
    m.later(
      'say',
      layer: -1,
      name: 'fill',
      word: [
        c.r,
        c.g,
        c.b,
      ].map((v) => (v * 255).round().toRadixString(16).padLeft(2, '0')).join(),
    );
  }
  if (ws.ink.contains(' ') && ws.inkBlend.isNotEmpty && !line) {
    m.later(
      'say',
      layer: -1,
      name: 'gradient_blend',
      word: ws.inkBlend,
    ); // A gradient ink is mixed as it was chosen.
  }
  if (ws.edge.isNotEmpty && !line) {
    m
      ..later('say', layer: -1, name: 'stroke', word: ws.edge)
      ..later('set', layer: -1, name: 'stroke_width', number: 6);
  }
}
