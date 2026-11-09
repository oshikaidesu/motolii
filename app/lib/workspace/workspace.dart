// The whole window: top bar, then the panes (panes.dart) — browser shelves | Stage over Timeline, Inspector over Tool Panel, rearrangeable.
// Each panel is its own file and reads the shared Ws.
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
import 'shelf/script_code.dart';
import 'shelf/fx_code.dart';
part 'inspector_feed/panel.dart';
part 'inspector_feed/cards.dart';
part 'inspector_feed/values.dart';
part 'inspector_feed/keyframe_marks.dart';
part 'commands/menu_bar.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key, this.document, this.extra = const [], this.view = const {}});

  /// A document of the inside (motolii.dart) to join the window to: its stage is then the inside's own picture.
  /// null: the sample, with its stand-in art.
  final String? document;

  /// Panes of your own, beside the window's: each joins the Inspector's tabs. A pane reads and changes the document
  /// through [WsScope.of] (its `inside` is the document, `selected` the picked thing, `frame` the moment).
  final List<WsPane> extra;

  /// How the window looks when it opens (Ws.view: as it was left, say).
  final Map<String, Object?> view;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  late final _ws = Ws()
    ..panes = [..._panes, ...widget.extra]
    ..view.addAll(widget.view);
  Motolii? _inside;
  StreamSubscription<FileSystemEvent>? _own; // (the maker's own folder watched: effect_tiles.dart)

  String? _doc; // (the document that is open: the one the window was given, or one made or opened from the menu)

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepKeys);
    ColorTheme.watch(() => WidgetsBinding.instance.reassembleApplication());
    SkinParts.follow(); // (the theme's drawn parts: an SVG folder, read when the theme names it)   // (the theme file: read, and read again when written; the window built again in place)
    _join(
      widget.document ?? '${Directory.systemTemp.createTempSync('motolii').path}/Untitled.motolii',
    ); // (no document given: a new one, as After Effects opens an untitled project)
  }

  /// Another document in place of the open one (made, if there is none at that place).
  Future<void> _open(String doc) {
    _ws.stageTexture = null;
    _inside?.close();
    _inside = null;
    return _join(doc);
  }

  /// The open document's own picture kept in it as it is left for the list of them, and as the window closes (AbsentMotion
  /// keeps a project's as its editor is closed for its home: MainActivity.kt saveThumbnail), at its playhead or at the
  /// moment it was told (file.poster). Not as another is opened in its place: its last asks would go unanswered.
  void _keepPoster() => _inside?.poster('${Directory.systemTemp.path}/motolii_poster_$pid.png');

  /// The documents beside the open one listed over the window (AbsentMotion's home: home.dart).
  bool _home = false;

  /// The documents beside the open one (read as one is opened), and a place for a new one there.
  List<String> _beside = const [];
  List<String> _documents() {
    final here = Directory(File(_doc!).parent.path);
    return [
      for (final f in here.listSync().whereType<File>())
        if (f.path.endsWith('.motolii')) f.path,
    ]..sort();
  }

  /// A text box has the keys: the act is its own, by Flutter's own text actions (true: it was given it).
  /// Where a copied thing, or a copied look, is kept between windows (the inside's own document of it: document/presets.h).
  static String _clipboard(String what) {
    final dir = Directory('${Platform.environment['HOME']}/Library/Caches/Motolii')..createSync(recursive: true);
    return '${dir.path}/clipboard_$what.motolii';
  }

  /// The things picked: together if more than one is, else the one.
  List<int> _picked() => [
    for (final id in _ws.many.isNotEmpty ? _ws.many : {?_ws.selected}) ?int.tryParse(id),
  ];

  /// One step for each picked thing told so, all of it one step to undo.
  void _eachPicked(int Function(int) tell) {
    final m = _inside, all = _picked();
    if (m == null || all.isEmpty) return;
    m.later('together', number: 1);
    for (final t in all) {
      tell(t);
    }
    _ws.after(m.later('together'));
  }

  /// The text the machine's clipboard held when something was last copied here: what was copied last is what is pasted.
  String? _textWhenCopied;

  void _copy(String call, String what) {
    Clipboard.getData(Clipboard.kTextPlain).then((said) => _textWhenCopied = said?.text);
    final t = int.tryParse(_ws.selected ?? '');
    if (_inside != null && t != null) _inside!.later(call, layer: t, word: _clipboard(what));
  }

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

  /// The document written as a film beside itself; the top bar says how it went.
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

  /// A film just written looked over for flashes that may cause seizures, as YouTube Studio's Checks look over a video
  /// while it uploads and say "No issues found" or what and where (EA's IRIS: flashesOf); the top bar says it.
  Future<void> _checkFlashes(Motolii m, String film) async {
    final written = 'Written: ${film.split('/').last}', checking = '$written · Checking flashes…';
    _ws.notice = checking;
    final fails = await flashesOf(m.libPath, film);
    if (!mounted || _ws.notice != checking) return; // (something said meanwhile stands)
    String clock(double s) => '${s ~/ 60}:${(s % 60).toStringAsFixed(1).padLeft(4, '0')}';
    final name = film.split('/').last; // (what it found first, the name after: the bar's end is cut. NN/g's F-shaped reading, words that carry the news first)
    _ws.notice = switch (fails) {
      null => written,
      [] => 'Flash check: no issues found · $name',
      _ => 'Flash check: too many flashes at ${fails.map((f) => '${clock(f.$1)}–${clock(f.$2)}').join(', ')} · $name',
    };
    if (fails case [(final from, _), ...]) _ws.noticeGo = () => _ws.frame = (from * Ws.fps).floor();
  }

  /// Documents of the list written out: one as AbsentMotion's list does it (opened, and its export settings asked:
  /// MainActivity.kt exportFromList); more, each beside itself at its own settings, one after another as DaVinci Resolve's
  /// Render Queue goes through other projects' jobs (opening each in turn), and the one that was open opened again.
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

  /// The document and its media gathered into "<name> package" beside it, to be taken elsewhere whole (Alight Motion's
  /// project package, After Effects' Collect Files); the top bar says so.
  void _package() {
    final m = _inside, doc = _doc;
    if (m == null || doc == null) return;
    final name = doc.split('/').last.replaceFirst(RegExp(r'\.motolii$'), ''), folder = '${File(doc).parent.path}/$name package';
    final n = m.pack(folder, name);
    _ws.notice = n < 0 ? 'Not packaged: ${m.error}' : 'Packaged with $n ${n == 1 ? 'file' : 'files'}: $name package';
  }

  /// The picture at the playhead written beside the document (Premiere Pro's Export Frame); the top bar says so.
  void _exportFrame() {
    final m = _inside, doc = _doc;
    if (m == null || doc == null) return;
    final png = '${doc.substring(0, doc.lastIndexOf('.'))}_${_ws.frame}.png';
    _ws.notice = m.still(png) ? 'Written: ${png.split('/').last}' : 'Not written: ${m.error}';
  }

  /// The window's menus, in the system's own menu bar: what the sample window has no panel for (a new document,
  /// another document, the film written out) and what the keyboard does elsewhere (undo, redo, take a thing out).
  // The window holds the focus when nothing in it does (a field left, a pane closed): its keys are heard there.
  final _windowFocus = FocusNode(debugLabel: 'window');
  void _keepKeys() {
    bool fallen() {
      // (out of the window)
      final now = FocusManager.instance.primaryFocus;
      return now == null || (now is FocusScopeNode && _windowFocus.ancestors.contains(now));
    }

    if (!mounted || !fallen() || _windowFocus.context == null) return;
    // (once the frame's own asking is done: a field built in it asks for the keys after the frame, and was robbed of them: golf_noise.md (111))
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scheduleMicrotask(() {
        if (mounted && fallen()) _windowFocus.requestFocus();
      }),
    );
  }

  /// The window's commands by name (keymap.dart: the keys that say them, the window's own and the maker's file).
  late final _keymap = Keymap.load();
  Future<void> _join(String doc) async {
    final inside = Motolii.open(doc);
    if (inside == null) return;
    _inside = inside;
    _own = EffectTiles.watch(
      inside,
      () {
        // (a file put in the maker's own folder: on the shelves at once; an element written over: followed where it is put in)
        if (mounted) _ws.after(inside.later('follow_elements'), (_, _) => _ws.reread());
      },
      program: (file) {
        if (mounted) _ws.after(inside.later('code', word: file), (_, _) => _ws.reread());
      },
    );
    _ws.after(inside.later('follow_elements')); // (as the document is opened: AbsentMotion's elements followed as a project is loaded)
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
        _ws.after(inside.later('size', word: '$wide $high')); // (without waiting: the document's picture then says it does not fit, and it is opened again)
      }
      ..refit = () {
        // (a stage is opened at a size: the document closed and opened again, at the moment it was at)
        final at = inside.now;
        _open(doc);
        _inside?.at(at);
      }
      ..join(inside);
    setState(() {}); // (the menus are the open document's)
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

  /// The panes drag their tabs on an overlay; the window brings its own so it works under any host.
  late final _entry = OverlayEntry(
    maintainState: true,
    builder: (context) => LayoutBuilder(
      builder: (context, box) {
        const window = _Window(); // (one widget, kept: a card or a tab carried is a change of the overlay, and the whole window, every shelf's tiles, was built again for it: 18,358 widgets, 90 ms, each time one was taken up or let go)
        if (box.maxWidth >= WsT.minWindow.width && box.maxHeight >= WsT.minWindow.height) return window;
        return FittedBox(
          // (laid out no smaller than the least window, shrunk only as far as that needs: a zoomed window stays zoomed)
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
    if (_ws.inside == null) return ColoredBox(color: WsT.ground); // (the document still opening: no panel is built on nothing)
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

/// A pane's tab strip, added on top of the reference heights so the panels keep theirs.
const _strip = 22.0;

/// The reference arrangement: the browser shelves (one strip of tabs) | Stage over Timeline and Ease on the left, Inspector over Camera on the right.
/// Side and lower panes start at their reference sizes in px and the panes without one share what is left.
/// contract: give the filling panes no weight; `multi_split_view` turns sizes into weights and would scale them against any weight given.
DockingArea _preset(DockingArea Function(WsAt at, {double? size}) strip) => DockingRow([
  DockingColumn([
    DockingRow([strip(WsAt.shelves, size: WsT.dock), strip(WsAt.stage)]),
    DockingRow([strip(WsAt.timeline), strip(WsAt.ease, size: WsT.inspector)], size: WsT.lower + _strip, minimalSize: 220), // (the stretch between two keys, beside the keys; never lower than its seven shapes and its curve can be read: docking's own minimum, as VS Code's views say theirs)
  ]),
  DockingColumn(
    [strip(WsAt.inspector), strip(WsAt.tools, size: WsT.lower + _strip)],
    size: WsT.inspector,
    minimalSize: 340,
  ), // (the camera, whatever is picked)
]);

/// The paint each layer wears on the stage, so the Inspector's Fill names the colour you see.
