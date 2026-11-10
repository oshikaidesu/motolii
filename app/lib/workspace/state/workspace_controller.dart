// The workspace state that every panel reads (WorkspaceController): the document's layers as rows, the selection, the playhead and the view.
// What is applied to the canvas is in effects.dart.
import 'dart:developer' show Timeline, TimelineTask;

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
import 'package:motolii/workspace/state/drawing_inks.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/notices.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/playhead.dart';
import 'package:motolii/workspace/state/row_folds.dart';
import 'package:motolii/workspace/state/selection.dart';
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
      if (cache) kept.value = inside.cache;
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
    // Choices saved with the document: its inks and fonts.
    inks.restore(inside.settings);
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

  /// The inks and fonts a new layer is given: fill, stroke colour and gradient blend, and the fonts for a new title and
  /// a new body text. Saved with the document but not undo steps, like a PowerPoint theme.
  late final inks = DrawingInks(engine: () => _inside);
  String get ink => inks.ink;
  set ink(String v) => inks.ink = v;
  String get edge => inks.edge;
  set edge(String v) => inks.edge = v;
  String get inkBlend => inks.inkBlend;
  set inkBlend(String v) => inks.inkBlend = v;
  String get titleFont => inks.titleFont;
  set titleFont(String v) => inks.titleFont = v;
  String get bodyFont => inks.bodyFont;
  set bodyFont(String v) => inks.bodyFont = v;
  String get fontRole => inks.fontRole;
  set fontRole(String role) => inks.fontRole = role;
  String get bodyFace => inks.bodyFace;
  String get titleFace => inks.titleFace;

  /// The one line the window tells the user, and what clicking it does.
  late final notices = Notices(onChanged: () => _tell(WorkspaceAspect.notice));
  String? get notice => notices.notice;
  set notice(String? said) => notices.notice = said;
  void Function()? get noticeGo => notices.noticeGo;
  set noticeGo(void Function()? go) => notices.noticeGo = go;

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
    notices.dispose();
    seen.dispose();
    kept.dispose();
    playhead.dispose();
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
    selection.syncWithLayers();
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
    final sel = int.tryParse(selected ?? '');
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

  /// What is selected: a layer, the layers selected together, keyframes and a stretch between two keyframes.
  late final selection = Selection(
    engine: () => _inside,
    layers: () => layers,
    composition: _composition,
    onChanged: () => _tell(WorkspaceAspect.picked),
    onLayerSelected: () => toolPanelManual = null,
    onStretchSelected: () => front('Ease'),
  );
  String? get selected => selection.selected;
  Layer? get layer => selection.layer;
  Set<String> get many => selection.many;
  bool get manyInOrder => selection.manyInOrder;
  Set<SelectedKeyframe> get keys => selection.keys;
  StretchPicked? get stretch => selection.stretch;
  void select(String? id) => selection.select(id);
  void pickMany(Iterable<String> ids, {bool inOrder = false}) =>
      selection.pickMany(ids, inOrder: inOrder);
  void pickKey(SelectedKeyframe k, {bool add = false}) =>
      selection.pickKey(k, add: add);
  void pickKeys(Iterable<SelectedKeyframe> ks) => selection.pickKeys(ks);
  void clearKeys() => selection.clearKeys();
  void pickStretch(String layer, String name, int from) =>
      selection.pickStretch(layer, name, from);
  String? get aim => selection.aim;
  set aim(String? to) => selection.aim = to;

  /// The playhead: the frame shown, and whether the preview is playing.
  late final playhead = Playhead(
    engine: () => _inside,
    composition: _composition,
    onPlayingChanged: () => _tell(WorkspaceAspect.playing),
  );
  ValueNotifier<int> get moment => playhead.moment;
  int get frame => playhead.frame;
  set frame(int f) => playhead.frame = f;
  bool get playing => playhead.playing;
  set playing(bool p) => playhead.playing = p;
  List<int> get strikes => playhead.strikes;
  set strikes(List<int> frames) => playhead.strikes = frames;
  String timecode([int? f]) => playhead.timecode(f);

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
    if (!on) folds.forgetShut();
    _tell(WorkspaceAspect.animating);
  }

  /// Which rows of the timeline are open: the keyframe lanes under a layer, and the members of a group.
  late final folds = RowFolds(
    animating: () => animating,
    layers: () => layers,
    onChanged: () => _tell(WorkspaceAspect.animating),
  );
  bool lanesOpen(String id) => folds.lanesOpen(id);
  bool aimsOpen(String id) => folds.aimsOpen(id);
  void twirl(Iterable<String> ids) => folds.twirl(ids);
  bool groupOpen(String id) => folds.groupOpen(id);
  void turnGroup(String id) => folds.turnGroup(id);
  Map<String, String> get foldedAway => folds.foldedAway;

  /// The ids of everything a group holds, however deep. Empty for other layers (see doc_under).
  List<String> under(String id) {
    final of = {for (final l in layers) l.id: l};
    if (of[id]?.kind != LayerKind.group) return const [];
    return [
      for (final l in layers)
        if (l.ancestors(of).any((p) => p.id == id)) l.id,
    ];
  }

  /// How many groups contain layer [l]. Its row is indented by that many levels.
  int depth(Layer l) => l
      .ancestors({for (final x in layers) x.id: x})
      .where((p) => p.kind == LayerKind.group)
      .length;

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
}

/// The font a new text layer uses: one that every machine of the platform has. The Create shelf and the preview's text tool share it.
final defaultTextFont = DrawingInks.defaultTextFont;

/// Applies the chosen inks to the layer just added (layer -1), wherever it was added from, including the Fonts and Create shelves.
/// A text or a flat shape takes all the inks, because the preview draws only those. A line takes its colour only.
void applyChosenInks(WorkspaceController ws, String kind, String shape) =>
    ws.inks.applyToNewLayer(kind, shape);
