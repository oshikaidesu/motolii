// The workspace state that every panel reads (WorkspaceController): the document's layers as rows, the selection, the playhead and the view.
// It owns one class for each of those and the one channel they all notify through. What is applied to the canvas is in effects.dart.
import 'dart:developer' show Timeline;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/composition_settings.dart';
import 'package:motolii/workspace/state/drawing_inks.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/notices.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/panel_layout.dart';
import 'package:motolii/workspace/state/playhead.dart';
import 'package:motolii/workspace/state/project_reader.dart';
import 'package:motolii/workspace/state/row_folds.dart';
import 'package:motolii/workspace/state/selection.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';

/// Whether layer [t] is a sound: a video layer whose file has no image, hidden and only heard (see doc_add).
bool isSoundLayer(Motolii m, int t) => ProjectReader.isSound(m, t);

/// The window's state: the document's layers as rows (read from the engine), the selection, the playhead and the view.
/// Every panel listens to this and nothing else, and never keeps a copy of it.
/// Changes notify once per user action. Nothing ticks while idle; the playhead advances only while [playing].
///
/// The state itself is held by the classes this one owns ([project], [selection], [playhead], [layout], [notices],
/// [inks], [folds]). Each tells its changes through this controller, and the members listed under each forward to it.
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

  // One for the whole app, because widgets read the three getters below without a controller at hand.
  static final _composition = CompositionSettings();

  /// The composition's frame rate and length in frames. After [join] they come from the document.
  static int get fps => _composition.frameRate;
  static int get duration => _composition.duration;

  /// The composition's size in pixels. After [join] it is the document's own size.
  static Size get comp => _composition.size;

  /// What is read from the engine's document: the layers as rows, the marks, the guides and the tempo, and the
  /// requests still on their way to the engine.
  late final project = ProjectReader(
    composition: _composition,
    playhead: playhead,
    onLayersRead: () => selection.syncWithLayers(),
    onChanged: () => _tell(WorkspaceAspect.document),
    onStageTextureChanged: () => _tell(WorkspaceAspect.stage),
  );
  List<Layer> get layers => project.layers;
  Motolii? get inside => project.inside;
  VoidCallback? get refit => project.refit;
  set refit(VoidCallback? reopen) => project.refit = reopen;
  int get rev => project.rev;
  int get reads => project.reads;
  void respan(String id) => project.respan(id);
  ValueNotifier<int> get seen => project.seen;
  ValueNotifier<List<(int, int)>> get kept => project.kept;
  void shown() => project.shown();
  double get bpm => project.bpm;
  Beats? get beats => project.beats;
  void reread() => project.reread();
  int? get stageTexture => project.stageTexture;
  set stageTexture(int? id) => project.stageTexture = id;
  List<String> fxOf(String? id) => project.fxOf(id);
  (double, double) get work => project.work;
  List<(double, String)> get marks => project.marks;
  Set<int> stops({Set<String> skip = const {}}) => project.stops(skip: skip);
  Map<double, int> get markColors => project.markColors;
  List<(String, double)> get guides => project.guides;
  List<String> under(String id) => project.under(id);
  int depth(Layer l) => project.depth(l);
  ({bool layers, Set<(int, String)> values})? get lastChange =>
      project.lastChange;
  set lastChange(({bool layers, Set<(int, String)> values})? changed) =>
      project.lastChange = changed;
  bool get waiting => project.waiting;
  void after(
    int ticket, [
    void Function(bool done, String why)? then,
    void Function(int answer)? got,
  ]) => project.after(ticket, then, got);

  /// Connects the window to the engine [inside]: reads its document, then the inks and fonts saved with it.
  void join(Motolii inside) {
    project.join(inside);
    // Choices saved with the document: its inks and fonts.
    inks.restore(inside.settings);
  }

  /// The document's name.
  String? document;

  /// The folder holding the document's file. The dock offers it, so a new document is one step from its footage.
  String? documentFolder;

  /// Host callbacks: reopen the document at another size, and export it as a video.
  void Function(int wide, int high)? onSize;
  VoidCallback? onRender;

  /// Where the next export is written. Set by the settings window; null means the window's default.
  String? renderTo;

  /// The inks and fonts a new layer is given: fill, stroke colour and gradient blend, and the fonts for a new title and
  /// a new body text. Saved with the document but not undo steps, like a PowerPoint theme.
  late final inks = DrawingInks(engine: () => inside);
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

  static T timed<T>(String name, T Function() does) =>
      Timeline.timeSync(name, does);

  @override
  void dispose() {
    project.dispose();
    notices.dispose();
    playhead.dispose();
    for (final n in on.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// Tells the engine (Motolii.subscribe) which layers' changing values to report: the selected layers, the cameras for the
  /// Depth tool panel, the relations for the Relations tool panel's map, and the members of a selected relation.
  void _watch() {
    final m = inside;
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
    engine: () => inside,
    layers: () => layers,
    composition: _composition,
    onChanged: () => _tell(WorkspaceAspect.picked),
    onLayerSelected: () => layout.toolPanelManual = null,
    onStretchSelected: () => layout.front('Ease'),
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
    engine: () => inside,
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

  /// The window's panels: the tabs, the panel brought to the front, the tool open in the tool panel, and the view
  /// state each panel keeps by name.
  late final layout = PanelLayout(
    layers: () => layers,
    onViewChanged: () => _tell(WorkspaceAspect.view),
    onFronted: () => _tell(WorkspaceAspect.fronted),
  );
  Map<String, Object?> get view => layout.view;
  T viewOf<T>(String name, T otherwise) => layout.viewOf(name, otherwise);
  void setView(String name, Object? value) => layout.setView(name, value);
  bool get freeEye => layout.freeEye;
  List<double> get eye => layout.eye;
  String? get toolPanelManual => layout.toolPanelManual;
  set toolPanelManual(String? name) => layout.toolPanelManual = name;
  List<Pane> get panes => layout.panes;
  set panes(List<Pane> all) => layout.panes = all;
  List<Pane> get tools => layout.tools;
  void openToolPanel(String? name) => layout.openToolPanel(name);
  void front(String pane) => layout.front(pane);
  (String, int)? get fronted => layout.fronted;
  String get toolPanel => layout.toolPanel;
  void route(String to) => layout.route(to);

  /// Whether every change the user makes is keyframed. The top bar's Animate and the inspector's Animate all share it; the engine owns it.
  bool get animating => inside?.keyingNow ?? false;
  set animating(bool on) {
    inside?.keying(on);
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
