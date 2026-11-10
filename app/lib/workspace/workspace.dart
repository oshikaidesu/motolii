// The whole window: the top bar above the panes (panes.dart).
// The panes are the media shelves, Stage over Timeline, and Inspector over Tool Panel. The user can rearrange them.
// Each panel lives in its own file and reads the shared Ws.
import 'dock/dock_widgets.dart' show askDockSearch;

import 'dart:developer' show Timeline;
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:docking/docking.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter/widgets.dart';

import '../skin/svg_parts.dart';
import 'stage/stage_art.dart' show WsArt;
import 'window/zoom.dart';
import 'shelf/effect_tiles.dart';
import 'commands/command_actions.dart';

import 'package:motolii/inspector/inspector_parts_insp_host.dart';

import '../inspector/inspector_parts.dart';
import '../skin/theme.dart';
import 'tool_panel/tool_panel.dart';
import 'tool_panel/tool_panel_depth.dart';
import 'tool_panel/tool_panel_blend.dart';
import 'tool_panel/tool_panel_align.dart';
import 'tool_panel/tool_panel_relations.dart';
import 'tool_panel/tool_panel_ease.dart';
import 'dock/dock.dart';
import 'dock/dock_glyphs.dart';
import 'window/home.dart';
import 'window/panes.dart';
import 'edits/keyframe_edits.dart';
import 'commands/keymap.dart';
import 'stage/stage.dart';
import 'stage/stage_camera.dart';
import 'stage/stage_view.dart' show WsRelationStack;
import 'timeline/timeline.dart';
import 'top_bar/top_bar.dart';
import '../bridge/motolii.dart';
import 'edits/make_relation.dart';
import 'state/state.dart';
import 'shelf/fx_code.dart';
part 'inspector_feed/panel.dart';
part 'inspector_feed/cards.dart';
part 'inspector_feed/values.dart';
part 'inspector_feed/keyframe_marks.dart';
part 'commands/menu_bar.dart';

/// The app's main window: top bar, shelves, Stage, Timeline, Inspector and tool panels.
class Workspace extends StatefulWidget {
  const Workspace({super.key, this.document, this.extra = const []});

  /// The path of the project to open in this window (the engine side is in motolii.dart).
  /// When null, the window shows the sample with its placeholder art.
  final String? document;

  /// Extra panes that join the Inspector's tabs.
  ///
  /// A pane reads and changes the project through [WsScope.of]: `inside` is the engine's project,
  /// `selected` the selected layer and `frame` the current time.
  final List<WsPane> extra;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  late final _ws = Ws()..panes = [..._panes, ...widget.extra];
  Motolii? _inside;
  // Watches the user's own effects folder (effect_tiles.dart).
  StreamSubscription<FileSystemEvent>? _own;

  /// The path of the open project: the one passed in, or one created or opened from the menu.
  String? _doc;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepKeys);
    // The theme file is read again whenever it is written, and the window is rebuilt in place.
    ColorTheme.watch(() => WidgetsBinding.instance.reassembleApplication());
    // Reads the theme's SVG parts from the folder the theme names.
    SkinParts.follow();
    // With no project given, start a new untitled one, as After Effects does.
    _join(widget.document ?? '${Directory.systemTemp.createTempSync('motolii').path}/Untitled.motolii');
  }

  /// Opens another project in place of the current one, creating it if it does not exist.
  Future<void> _open(String doc) {
    _ws.stageTexture = null;
    _inside?.close();
    _inside = null;
    return _join(doc);
  }

  /// Saves the open project's thumbnail for the project list when the window closes.
  ///
  /// AbsentMotion does the same when its editor closes (MainActivity.kt saveThumbnail).
  /// The thumbnail is taken at the playhead, or at the time set by file.poster.
  /// It is not saved when another project is opened in place of this one, because its last requests would go unanswered.
  void _keepPoster() => _inside?.poster('${Directory.systemTemp.path}/motolii_poster_$pid.png');

  /// Whether the project list is shown over the window (AbsentMotion's home screen; see home.dart).
  bool _home = false;

  /// The projects in the open project's folder, read when a project is opened.
  List<String> _beside = const [];
  List<String> _documents() {
    final here = Directory(File(_doc!).parent.path);
    return [
      for (final f in here.listSync().whereType<File>())
        if (f.path.endsWith('.motolii')) f.path,
    ]..sort();
  }

  /// The file where a copied layer or preset is kept between windows (the engine's own format: document/presets.h).
  static String _clipboard(String what) {
    final dir = Directory('${Platform.environment['HOME']}/Library/Caches/Motolii')..createSync(recursive: true);
    return '${dir.path}/clipboard_$what.motolii';
  }

  /// The selected layers: all of the multi-selection if there is one, otherwise the single selected layer.
  List<int> _picked() => [
    for (final id in _ws.many.isNotEmpty ? _ws.many : {?_ws.selected}) ?int.tryParse(id),
  ];

  /// Applies [tell] to each selected layer, as a single undo step.
  void _eachPicked(int Function(int) tell) {
    final m = _inside, all = _picked();
    if (m == null || all.isEmpty) return;
    m.later('together', number: 1);
    for (final t in all) {
      tell(t);
    }
    _ws.after(m.later('together'));
  }

  /// The text on the system clipboard when something was last copied here.
  /// It lets a paste tell whether the clipboard still holds this app's copy, so that what was copied last is what gets pasted.
  String? _textWhenCopied;

  void _copy(String call, String what) {
    Clipboard.getData(Clipboard.kTextPlain).then((said) => _textWhenCopied = said?.text);
    final t = int.tryParse(_ws.selected ?? '');
    if (_inside != null && t != null) _inside!.later(call, layer: t, word: _clipboard(what));
  }

  /// Runs [act] on the focused text field if it handles that intent, so the field keeps its own keys.
  /// Returns true if the field handled it. This uses Flutter's text actions.
  bool _typed<T extends Intent>(T act) {
    final box = primaryFocus?.context;
    if (box == null || Actions.maybeFind<T>(box, intent: act) == null) return false;
    Actions.maybeInvoke(box, act);
    return true;
  }

  String _fresh() {
    final here = File(_doc!).parent.path;
    for (var n = 1; ; n++) {
      if (!File('$here/untitled_$n.motolii').existsSync()) return '$here/untitled_$n.motolii';
    }
  }

  /// Exports the project as a video file beside it. The top bar shows how it went.
  Future<bool> _render() async {
    final m = _inside, doc = _doc;
    if (m == null || doc == null) return false;
    final mp4 = _ws.renderTo ?? '${doc.substring(0, doc.lastIndexOf('.'))}.mp4';
    _ws.renderTo = null;
    _ws.notice = 'Writing ${mp4.split('/').last} …';
    final done = await m.exportVideo(mp4);
    if (mounted) _ws.notice = done ? 'Written: ${mp4.split('/').last}' : 'Not written: ${m.error}';
    if (done && RegExp(r'\.(mp4|mov|m4v)$').hasMatch(mp4)) unawaited(_checkFlashes(m, mp4));
    return done;
  }

  /// Checks a newly exported video for flashes that may cause seizures and shows the result in the top bar.
  ///
  /// YouTube Studio's Checks do the same while a video uploads (EA's IRIS: flashesOf).
  Future<void> _checkFlashes(Motolii m, String film) async {
    final written = 'Written: ${film.split('/').last}', checking = '$written · Checking flashes…';
    _ws.notice = checking;
    final fails = await flashesOf(m.libPath, film);
    // If the notice changed in the meantime, the newer notice stays.
    if (!mounted || _ws.notice != checking) return;
    String clock(double s) => '${s ~/ 60}:${(s % 60).toStringAsFixed(1).padLeft(4, '0')}';
    // The result comes first and the name after, because the bar cuts off its end (NN/g: F-shaped reading).
    final name = film.split('/').last;
    _ws.notice = switch (fails) {
      null => written,
      [] => 'Flash check: no issues found · $name',
      _ => 'Flash check: too many flashes at ${fails.map((f) => '${clock(f.$1)}–${clock(f.$2)}').join(', ')} · $name',
    };
    if (fails case [(final from, _), ...]) _ws.noticeGo = () => _ws.frame = (from * Ws.fps).floor();
  }

  /// Exports the listed projects.
  ///
  /// One project is opened and the user is asked for export settings, as AbsentMotion's list does (MainActivity.kt exportFromList).
  /// Several are each exported beside themselves with their own settings, one after another, opening each in turn,
  /// as DaVinci Resolve's Render Queue does. The project that was open is reopened at the end.
  Future<void> _exportFrom(List<String> docs) async {
    setState(() => _home = false);
    if (docs.length == 1) {
      if (docs.first != _doc) await _open(docs.first);
      wsAskRender.value++;
      return;
    }
    final back = _doc;
    var written = 0;
    for (final d in docs) {
      if (d != _doc) await _open(d);
      if (mounted && _doc == d && await _render()) written++;
    }
    if (back != null && back != _doc) await _open(back);
    if (mounted) _ws.notice = 'Written: $written of ${docs.length} films, each beside its document';
  }

  /// Gathers the project and its media into `<name> package` beside it, so it can be moved elsewhere whole
  /// (Alight Motion's project package, After Effects' Collect Files). The top bar shows the result.
  void _package() {
    final m = _inside, doc = _doc;
    if (m == null || doc == null) return;
    final name = doc.split('/').last.replaceFirst(RegExp(r'\.motolii$'), ''), folder = '${File(doc).parent.path}/$name package';
    final n = m.pack(folder, name);
    _ws.notice = n < 0 ? 'Not packaged: ${m.error}' : 'Packaged with $n ${n == 1 ? 'file' : 'files'}: $name package';
  }

  /// Exports the frame at the playhead as a PNG beside the project (Premiere Pro's Export Frame). The top bar shows the result.
  void _exportFrame() {
    final m = _inside, doc = _doc;
    if (m == null || doc == null) return;
    final png = '${doc.substring(0, doc.lastIndexOf('.'))}_${_ws.frame}.png';
    _ws.notice = m.still(png) ? 'Written: ${png.split('/').last}' : 'Not written: ${m.error}';
  }

  /// Holds the focus when nothing else in the window does (a field was left or a pane closed), so the window's keys still work.
  final _windowFocus = FocusNode(debugLabel: 'window');
  void _keepKeys() {
    bool fallen() {
      // True when the focus is outside the window.
      final now = FocusManager.instance.primaryFocus;
      return now == null || (now is FocusScopeNode && _windowFocus.ancestors.contains(now));
    }

    if (!mounted || !fallen() || _windowFocus.context == null) return;
    // Wait until the frame's own focus requests are done. A field built in this frame requests focus after it, and would lose it to us.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scheduleMicrotask(() {
        if (mounted && fallen()) _windowFocus.requestFocus();
      }),
    );
  }

  /// The window's commands by name, with the keys bound to them: the defaults and the user's own file (keymap.dart).
  late final _keymap = Keymap.load();
  Future<void> _join(String doc) async {
    final inside = Motolii.open(doc);
    if (inside == null) return;
    _inside = inside;
    _own = EffectTiles.watch(
      inside,
      () {
        // A file put in the user's effects folder shows on the shelves at once. An element file that is overwritten is followed wherever it is used.
        if (mounted) _ws.after(inside.later('follow_elements'), (_, _) => _ws.reread());
      },
      program: (file) {
        if (mounted) _ws.after(inside.later('code', word: file), (_, _) => _ws.reread());
      },
    );
    // Follow the elements when the project opens, as AbsentMotion does when a project loads.
    _ws.after(inside.later('follow_elements'));
    _doc = doc;
    _beside = _documents();
    final id = await inside.texture();
    if (!mounted) return;
    if (id >= 0) _ws.stageTexture = id;
    _ws
      ..document = doc.split('/').last
      ..documentFolder = File(doc).parent.path
      ..notice = null
      ..onRender = _render
      ..onSize = (wide, high) {
        // Not awaited: the project's image then reports that it does not fit, and the project is reopened.
        _ws.after(inside.later('size', word: '$wide $high'));
      }
      ..refit = () {
        // The stage was opened at a new size: close the project and reopen it at the current time.
        final at = inside.now;
        _open(doc);
        _inside?.at(at);
      }
      ..join(inside);
    // The menus belong to the open project.
    setState(() {});
  }

  @override
  void dispose() {
    _keepPoster();
    FocusManager.instance.removeListener(_keepKeys);
    _windowFocus.dispose();
    _own?.cancel();
    _inside?.close();
    _ws.dispose();
    super.dispose();
  }

  /// The panes drag their tabs on an overlay. The window provides its own so this works under any host.
  late final _entry = OverlayEntry(
    maintainState: true,
    builder: (context) => LayoutBuilder(
      builder: (context, box) {
        // One widget instance, reused. Carrying a card or tab changes the overlay, and the whole window,
        // including every shelf's tiles, used to be rebuilt each time (18,358 widgets, 90 ms per pick-up or drop).
        const window = _Window();
        if (box.maxWidth >= WsT.minWindow.width && box.maxHeight >= WsT.minWindow.height) return window;
        return FittedBox(
          // Laid out at no less than the minimum window size and shrunk only as far as needed, so a zoomed window stays zoomed.
          child: SizedBox(width: math.max(box.maxWidth, WsT.minWindow.width), height: math.max(box.maxHeight, WsT.minWindow.height), child: window),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final window = WsScope(
      ws: _ws,
      child: Focus(
        focusNode: _windowFocus,
        autofocus: true,
        child: ColoredBox(
          color: WsT.ground,
          child: Stack(
            children: [
              Overlay(initialEntries: [_entry]),
              if (_home && _doc != null && _ws.inside != null)
                Positioned.fill(
                  child: WsHome(
                    folder: File(_doc!).parent.path,
                    lib: _ws.inside!.libPath,
                    open: _doc!,
                    onOpen: (d) {
                      setState(() => _home = false);
                      if (d != _doc) _open(d);
                    },
                    onExport: _exportFrom,
                    onNew: () {
                      setState(() => _home = false);
                      _commands()['file.new']!();
                    },
                    onClose: () => setState(() => _home = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // The project is still opening, so no panel is built yet.
    if (_ws.inside == null) return ColoredBox(color: WsT.ground);
    return PlatformMenuBar(
      menus: _menus(),
      child: WsKeys(
        keymap: _keymap,
        commands: _commands(),
        child: WsZoomed(child: window),
      ),
    );
  }
}

class _Window extends StatelessWidget {
  const _Window();
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: WsT.topBar, child: WsTopBar()),
      const SizedBox(height: WsT.gutter),
      Expanded(
        child: WsPanes(panes: WsScope.read(context).panes, preset: _preset),
      ),
    ],
  );
}

final _panes = [
  WsPane('Media', DockG.media, () => const WsShelf('Media', 'Search files and media'), at: WsAt.shelves, minSize: 240, iconOnly: true),
  WsPane('Effects', DockG.effects, () => const WsShelf('Effects', 'Search effects and features'), at: WsAt.shelves, minSize: 240, iconOnly: true),
  WsPane('Fonts', DockG.fonts, () => const WsShelf('Fonts', 'Search fonts'), at: WsAt.shelves, minSize: 240, iconOnly: true),
  WsPane('Colors', DockG.colors, () => const WsShelf('Colors', 'Search palettes'), at: WsAt.shelves, minSize: 240, iconOnly: true),
  WsPane('Create', DockG.create, () => const WsShelf('Create', 'Search layers and shapes'), at: WsAt.shelves, minSize: 240, iconOnly: true),
  WsPane('Program', DockG.program, () => const WsShelf('Program', 'Search code'), at: WsAt.shelves, minSize: 240, iconOnly: true),
  WsPane('Presets', DockG.files, () => const WsShelf('Presets', 'Search presets'), at: WsAt.shelves, minSize: 240, iconOnly: true),
  WsPane('Stage', DockG.stage, () => const WsStage(), at: WsAt.stage, minSize: 320),
  WsPane('Camera View', DockG.camera, () => const WsCameraView(), at: WsAt.stage, minSize: 240),
  WsPane('Inspector', DockG.inspector, () => const _InspectorPanel(), minSize: 200),
  WsPane('Timeline', DockG.timeline, () => const WsTimeline(), at: WsAt.timeline, minSize: 160),
  WsPane('Ease', DockG.time, () => const EaseTool(), at: WsAt.ease, minSize: 260),
  WsPane('Camera', DockG.camera, () => const DepthTool(), at: WsAt.tools, minSize: WsT.lower),
  WsPane('Tool Panel', DockG.toolPanel, () => const WsToolPanel(), at: WsAt.tools, minSize: WsT.lower),
  WsPane('Relations', DockG.toolPanel, () => const RelationsTool(), at: WsAt.tools, minSize: WsT.lower),
  WsPane('Blend', DockG.blend, BlendTool.new, at: WsAt.catalog, tone: Pop.toneBlend, acts: 'Layer stack'),
  WsPane('Align', DockG.align, AlignTool.new, at: WsAt.catalog, tone: Pop.toneLayout, acts: 'Selection'),
];

/// Height of a pane's tab strip, added to the reference heights so the panels keep theirs.
const _strip = 22.0;

/// The default arrangement: the media shelves (one strip of tabs) and Stage over Timeline and Ease on the left,
/// Inspector over Camera on the right.
///
/// Side and lower panes start at their reference sizes in px. The panes without a size share what is left.
/// The filling panes must be given no weight: `multi_split_view` turns sizes into weights and would scale them against any weight given.
DockingArea _preset(DockingArea Function(WsAt at, {double? size}) strip) => DockingRow([
  DockingColumn([
    DockingRow([strip(WsAt.shelves, size: WsT.dock), strip(WsAt.stage)]),
    // Ease edits the easing between two keyframes, so it sits beside Timeline. It is never made shorter than 220,
    // the height at which its seven shapes and curve stay readable. This is docking's own minimum, as in VS Code's views.
    DockingRow([strip(WsAt.timeline), strip(WsAt.ease, size: WsT.inspector)], size: WsT.lower + _strip, minimalSize: 220),
  ]),
  // The lower strip holds the Camera tool, whatever is selected.
  DockingColumn([strip(WsAt.inspector), strip(WsAt.tools, size: WsT.lower + _strip)], size: WsT.inspector, minimalSize: 340),
]);
