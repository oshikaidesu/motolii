// The workspace state every panel reads: layers, selection, playhead and view.
import 'dart:developer' show Timeline;

import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_document.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/workspace/state/beats.dart';
import 'package:motolii/workspace/state/composition_settings.dart';
import 'package:motolii/workspace/state/drawing_inks.dart';
import 'package:motolii/workspace/state/layer.dart';
import 'package:motolii/workspace/state/live_edit.dart';
import 'package:motolii/workspace/state/notices.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/panel_layout.dart';
import 'package:motolii/workspace/state/playhead.dart';
import 'package:motolii/workspace/state/project_reader.dart';
import 'package:motolii/workspace/timeline/frame_snap.dart' show SnapTarget;
import 'package:motolii/workspace/state/row_folds.dart';
import 'package:motolii/workspace/state/selection.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';

/// Whether layer [t] is a sound-only video layer.
bool isSoundLayer(Motolii m, int t) => ProjectReader.isSound(m, t);

/// The window's state. Every panel listens to this and nothing else, and never keeps a copy.
/// Nothing ticks while idle; the playhead advances only while [playing].
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

  // Global so widgets can read fps/length/size without a controller at hand.
  static final _composition = CompositionSettings();

  /// The composition's frame rate and length in frames.
  static int get fps => _composition.frameRate;
  static int get duration => _composition.duration;

  /// The composition's size in pixels.
  static Size get comp => _composition.size;

  /// What is read from the engine's document, and the gesture in progress.
  late final live = LiveEdit(this);

  late final project = ProjectReader(
    composition: _composition,
    playhead: playhead,
    onLayersRead: () => selection.syncWithLayers(),
    onChanged: () => _tell(WorkspaceAspect.document),
    onListed: () => _tell(WorkspaceAspect.layers),
    onStageTextureChanged: () => _tell(WorkspaceAspect.stage),
  );
  List<Layer> get layers => project.layers;
  Motolii? get inside => project.inside;
  VoidCallback? get refit => project.refit;
  set refit(VoidCallback? reopen) => project.refit = reopen;
  int get rev => project.rev;
  int get reads => project.reads;
  void respan(int id) => project.respan(id);
  ValueNotifier<int> get seen => project.seen;
  ValueNotifier<List<(int, int)>> get kept => project.kept;
  void shown() => project.shown();
  double get bpm => project.bpm;
  Beats? get beats => project.beats;
  void reread() => project.reread();
  int? get stageTexture => project.stageTexture;
  set stageTexture(int? id) => project.stageTexture = id;
  List<String> fxOf(int? id) => project.fxOf(id);
  (double, double) get work => project.work;
  List<(double, String)> get marks => project.marks;
  Set<int> stops({Set<int> skip = const {}}) => project.stops(skip: skip);
  List<SnapTarget> snapTargets({Set<int> skip = const {}}) =>
      project.snapTargets(skip: skip);
  Map<double, int> get markColors => project.markColors;
  List<(String, double)> get guides => project.guides;
  List<int> under(int id) => project.under(id);
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

  /// Connects the window to the engine [inside].
  void join(Motolii inside) {
    project.join(inside);
    inks.restore(inside.settings);
  }

  String? document;

  /// The folder holding the document's file.
  String? documentFolder;

  /// Host callbacks: resize and export.
  void Function(int wide, int high)? onSize;
  VoidCallback? onRender;

  /// Where the next export is written. Null = default beside the project.
  String? renderTo;

  /// The inks and fonts a new layer is given. Saved with the document but not undo steps.
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

  /// The notice line and its tap action.
  late final notices = Notices(onChanged: () => _tell(WorkspaceAspect.notice));
  String? get notice => notices.notice;
  set notice(String? said) => notices.notice = said;
  void Function()? get noticeGo => notices.noticeGo;
  set noticeGo(void Function()? go) => notices.noticeGo = go;
  double? get noticeProgress => notices.progress;
  set noticeProgress(double? f) => notices.progress = f;

  static T timed<T>(String name, T Function() does) =>
      Timeline.timeSync(name, does);

  @override
  void dispose() {
    live.cancel();
    project.dispose();
    notices.dispose();
    playhead.dispose();
    for (final n in on.values) {
      n.dispose();
    }
    super.dispose();
  }

  /// Tells the engine which layers' changing values to report.
  void _watch() {
    final m = inside;
    if (m == null) return;
    final sel = selected;
    m.subscribe({
      ?sel,
      ...many,
      for (final l in layers)
        if (l.kind == LayerKind.camera) l.id,
      for (final l in layers)
        if (m.word(l.id, 'kind') == 'behaviour') l.id,
      if (sel != null && m.word(sel, 'kind') == 'behaviour')
        for (final w in m.word(sel, 'members').split(' ')) ?int.tryParse(w),
    });
  }

  /// Selection: layer(s), keyframes and a stretch between two keyframes.
  late final selection = Selection(
    engine: () => inside,
    layers: () => layers,
    composition: _composition,
    onChanged: () => _tell(WorkspaceAspect.picked),
    onLayerSelected: () => layout.toolPanelManual = null,
    onStretchSelected: () => layout.front('Ease'),
  );
  int? get selected => selection.selected;
  Layer? get layer => selection.layer;
  Set<int> get many => selection.many;
  bool get manyInOrder => selection.manyInOrder;
  int? get lead => selection.lead;
  Set<SelectedKeyframe> get keys => selection.keys;
  StretchPicked? get stretch => selection.stretch;
  void select(int? id) => selection.select(id);
  void pickMany(Iterable<int> ids, {bool inOrder = false, int? lead}) =>
      selection.pickMany(ids, inOrder: inOrder, lead: lead);
  void pickKey(SelectedKeyframe k, {bool add = false}) =>
      selection.pickKey(k, add: add);
  void pickKeys(Iterable<SelectedKeyframe> ks) => selection.pickKeys(ks);
  void clearKeys() => selection.clearKeys();
  void pickStretch(int layer, String name, int from) =>
      selection.pickStretch(layer, name, from);
  String? get aim => selection.aim;
  set aim(String? to) => selection.aim = to;

  /// The playhead.
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

  /// Panel layout and per-panel view state.
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

  /// Whether every change the user makes is keyframed. Engine-owned.
  bool get animating => inside?.keyingNow ?? false;
  set animating(bool on) {
    inside?.keying(on);
    if (!on) folds.forgetShut();
    _tell(WorkspaceAspect.animating);
  }

  /// Which timeline rows are expanded.
  late final folds = RowFolds(
    animating: () => animating,
    layers: () => layers,
    onChanged: () => _tell(WorkspaceAspect.animating),
  );
  bool lanesOpen(int id) => folds.lanesOpen(id);
  bool aimsOpen(int id) => folds.aimsOpen(id);
  void twirl(Iterable<int> ids) => folds.twirl(ids);
  bool groupOpen(int id) => folds.groupOpen(id);
  void turnGroup(int id) => folds.turnGroup(id);
  Map<int, int> get foldedAway => folds.foldedAway;

  // Splits an effect list entry into (id, path). Format: "a1b2c3:/…/blur.wgsl".
  static final _files = RegExp(
    r'(?:[0-9a-f]{6}:)?/.*?\.(?:(?:wgsl|fs|js|mjs|json|am)(?= |$)|(?:anm2|obj2)[^ ]*)|[^ ]+',
  );
  static final _useId = RegExp(r'^[0-9a-f]{6}:(?=.)');

  /// The entries of an effect list, each with its ID where it has one.
  static List<String> fxEntries(String fx) => [
    for (final f in _files.allMatches(fx).map((m) => m[0]!))
      if (f != 'none') f,
  ];

  /// The file an entry names, without its ID (fx_entry_path).
  static String fxFile(String entry) => entry.replaceFirst(_useId, '');

  /// The files of an effect list, in order. The same file put on twice is here twice.
  static List<String> fxFiles(String fx) => [
    for (final e in fxEntries(fx)) fxFile(e),
  ];

  // Whether an effect is being previewed on the selected layer while hovering its tile.
  // Not part of the document; ends when the pointer leaves or before any apply.
  bool trying = false;
}

/// Default font for new text layers (platform-universal).
final defaultTextFont = DrawingInks.defaultTextFont;

/// Applies the chosen inks to the layer just added (layer -1), wherever it was added from, including the Fonts and Create shelves.
/// A text or a flat shape takes all the inks, because the preview draws only those. A line takes its colour only.
void applyChosenInks(WorkspaceController ws, String kind, String shape) =>
    ws.inks.applyToNewLayer(kind, shape);
