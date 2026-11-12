// The whole window: the top bar above the panes (panes.dart).
// The panes are the media shelves, Stage over Timeline, and Inspector over Tool Panel. The user can rearrange them.
// Each panel lives in its own file and reads the shared WorkspaceController.
import 'package:motolii/workspace/workspace_panes.dart';

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard;
import 'package:flutter/widgets.dart';

import 'package:motolii/bridge/motolii.dart';
import 'package:motolii/bridge/motolii_moment.dart';
import 'package:motolii/bridge/motolii_questions.dart';
import 'package:motolii/bridge/motolii_watch.dart';
import 'package:motolii/bridge/motolii_writes.dart';
import 'package:motolii/skin/skin_parts.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/commands/keymap.dart';
import 'package:motolii/workspace/commands/menu_bar.dart';
import 'package:motolii/workspace/commands/menu_items.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/top_bar/top_bar.dart';
import 'package:motolii/workspace/window/home.dart';
import 'package:motolii/workspace/window/panes.dart';
import 'package:motolii/workspace/window/zoom.dart';

/// The app's main window: top bar, shelves, Stage, Timeline, Inspector and tool panels.
class Workspace extends StatefulWidget {
  const Workspace({super.key, this.document, this.extra = const []});

  /// The path of the project to open in this window (the engine side is in motolii.dart).
  /// When null, the window shows the sample with its placeholder art.
  final String? document;

  /// Extra panes that join the Inspector's tabs.
  ///
  /// A pane reads and changes the project through [WorkspaceScope.of]: `inside` is the engine's project,
  /// `selected` the selected layer and `frame` the current time.
  final List<Pane> extra;
  @override
  State<Workspace> createState() => WorkspaceState();
}

class WorkspaceState extends State<Workspace> {
  late final ws = WorkspaceController()
    ..panes = [...workspacePanes, ...widget.extra];
  Motolii? engine;
  // Watches the user's own effects folder (effect_tiles.dart).
  StreamSubscription<FileSystemEvent>? _own;

  /// The path of the open project: the one passed in, or one created or opened from the menu.
  String? documentPath;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepKeys);
    // The theme file is read again whenever it is written, and the window is rebuilt in place.
    ColorTheme.watch(() => WidgetsBinding.instance.reassembleApplication());
    // Reads the theme's SVG parts from the folder the theme names.
    SkinParts.follow();
    // With no project given, start a new untitled one, as After Effects does.
    _join(
      widget.document ??
          '${Directory.systemTemp.createTempSync('motolii').path}/Untitled.motolii',
    );
  }

  /// Opens another project in place of the current one, creating it if it does not exist.
  Future<void> open(String doc) {
    ws.stageTexture = null;
    engine?.close();
    engine = null;
    return _join(doc);
  }

  /// Saves the open project's thumbnail for the project list when the window closes.
  ///
  /// AbsentMotion does the same when its editor closes (MainActivity.kt saveThumbnail).
  /// The thumbnail is taken at the playhead, or at the time set by file.poster.
  /// It is not saved when another project is opened in place of this one, because its last requests would go unanswered.
  void keepPoster() =>
      engine?.poster('${Directory.systemTemp.path}/motolii_poster_$pid.png');

  /// Whether the project list is shown over the window (AbsentMotion's home screen; see home.dart).
  bool home = false;

  /// The projects in the open project's folder, read when a project is opened.
  List<String> beside = const [];
  List<String> _documents() {
    final here = Directory(File(documentPath!).parent.path);
    return [
      for (final f in here.listSync().whereType<File>())
        if (f.path.endsWith('.motolii')) f.path,
    ]..sort();
  }

  /// The file where a copied layer or preset is kept between windows (the engine's own format: document/edit/presets.h).
  static String clipboard(String what) {
    final dir = Directory(
      '${Platform.environment['HOME']}/Library/Caches/Motolii',
    )..createSync(recursive: true);
    return '${dir.path}/clipboard_$what.motolii';
  }

  /// The selected layers: all of the multi-selection if there is one, otherwise the single selected layer.
  List<int> pickedLayers() => [
    for (final id in ws.many.isNotEmpty ? ws.many : {?ws.selected})
      ?int.tryParse(id),
  ];

  /// Applies [tell] to each selected layer, as a single undo step.
  void eachPicked(int Function(int) tell) {
    final m = engine, all = pickedLayers();
    if (m == null || all.isEmpty) return;
    m.later('together', number: 1);
    for (final t in all) {
      tell(t);
    }
    ws.after(m.later('together'));
  }

  /// The text on the system clipboard when something was last copied here.
  /// It lets a paste tell whether the clipboard still holds this app's copy, so that what was copied last is what gets pasted.
  String? textWhenCopied;

  void copy(String call, String what) {
    Clipboard.getData(Clipboard.kTextPlain)
        .then((said) => textWhenCopied = said?.text);
    final t = int.tryParse(ws.selected ?? '');
    if (engine != null && t != null) {
      engine!.later(call, layer: t, word: clipboard(what));
    }
  }

  /// Runs [act] on the focused text field if it handles that intent, so the field keeps its own keys.
  /// Returns true if the field handled it. This uses Flutter's text actions.
  bool typed<T extends Intent>(T act) {
    final box = primaryFocus?.context;
    if (box == null || Actions.maybeFind<T>(box, intent: act) == null) {
      return false;
    }
    Actions.maybeInvoke(box, act);
    return true;
  }

  String fresh() {
    final here = File(documentPath!).parent.path;
    for (var n = 1; ; n++) {
      if (!File('$here/untitled_$n.motolii').existsSync()) {
        return '$here/untitled_$n.motolii';
      }
    }
  }

  /// Exports the project as a video file beside it. The top bar shows how it went.
  Future<bool> _render() async {
    final m = engine, doc = documentPath;
    if (m == null || doc == null) return false;
    final mp4 = ws.renderTo ?? '${doc.substring(0, doc.lastIndexOf('.'))}.mp4';
    ws.renderTo = null;
    ws.notice = 'Writing ${mp4.split('/').last} …';
    final done = await m.exportVideo(mp4);
    if (mounted) {
      ws.notice = done
          ? 'Written: ${mp4.split('/').last}'
          : 'Not written: ${m.error}';
    }
    if (done && RegExp(r'\.(mp4|mov|m4v)$').hasMatch(mp4)) {
      unawaited(_checkFlashes(m, mp4));
    }
    return done;
  }

  /// Checks a newly exported video for flashes that may cause seizures and shows the result in the top bar.
  ///
  /// YouTube Studio's Checks do the same while a video uploads (EA's IRIS: flashesOf).
  Future<void> _checkFlashes(Motolii m, String film) async {
    final written = 'Written: ${film.split('/').last}',
        checking = '$written · Checking flashes…';
    ws.notice = checking;
    final fails = await flashesOf(m.libPath, film);
    // If the notice changed in the meantime, the newer notice stays.
    if (!mounted || ws.notice != checking) return;
    String clock(double s) =>
        '${s ~/ 60}:${(s % 60).toStringAsFixed(1).padLeft(4, '0')}';
    // The result comes first and the name after, because the bar cuts off its end (NN/g: F-shaped reading).
    final name = film.split('/').last;
    ws.notice = switch (fails) {
      null => written,
      [] => 'Flash check: no issues found · $name',
      _ =>
        'Flash check: too many flashes at ${fails.map((f) => '${clock(f.$1)}–${clock(f.$2)}').join(', ')} · $name',
    };
    if (fails case [(final from, _), ...]) {
      ws.noticeGo = () => ws.frame = (from * WorkspaceController.fps).floor();
    }
  }

  /// Exports the listed projects.
  ///
  /// One project is opened and the user is asked for export settings, as AbsentMotion's list does (MainActivity.kt exportFromList).
  /// Several are each exported beside themselves with their own settings, one after another, opening each in turn,
  /// as DaVinci Resolve's Render Queue does. The project that was open is reopened at the end.
  Future<void> _exportFrom(List<String> docs) async {
    setState(() => home = false);
    if (docs.length == 1) {
      if (docs.first != documentPath) await open(docs.first);
      renderRequested.value++;
      return;
    }
    final back = documentPath;
    var written = 0;
    for (final d in docs) {
      if (d != documentPath) await open(d);
      if (mounted && documentPath == d && await _render()) written++;
    }
    if (back != null && back != documentPath) await open(back);
    if (mounted) {
      ws.notice =
          'Written: $written of ${docs.length} films, each beside its document';
    }
  }

  /// Gathers the project and its media into `<name> package` beside it, so it can be moved elsewhere whole
  /// (Alight Motion's project package, After Effects' Collect Files). The top bar shows the result.
  void package() {
    final m = engine, doc = documentPath;
    if (m == null || doc == null) return;
    final name = doc.split('/').last.replaceFirst(RegExp(r'\.motolii$'), ''),
        folder = '${File(doc).parent.path}/$name package';
    final n = m.pack(folder, name);
    ws.notice = n < 0
        ? 'Not packaged: ${m.error}'
        : 'Packaged with $n ${n == 1 ? 'file' : 'files'}: $name package';
  }

  /// Exports the frame at the playhead as a PNG beside the project (Premiere Pro's Export Frame). The top bar shows the result.
  void exportFrame() {
    final m = engine, doc = documentPath;
    if (m == null || doc == null) return;
    final png = '${doc.substring(0, doc.lastIndexOf('.'))}_${ws.frame}.png';
    ws.notice = m.still(png)
        ? 'Written: ${png.split('/').last}'
        : 'Not written: ${m.error}';
  }

  /// Holds the focus when nothing else in the window does (a field was left or a pane closed), so the window's keys still work.
  final _windowFocus = FocusNode(debugLabel: 'window');
  void _keepKeys() {
    bool fallen() {
      // True when the focus is outside the window.
      final now = FocusManager.instance.primaryFocus;
      return now == null ||
          (now is FocusScopeNode && _windowFocus.ancestors.contains(now));
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
  late final keymap = Keymap.load();
  Future<void> _join(String doc) async {
    final inside = Motolii.open(doc);
    if (inside == null) return;
    engine = inside;
    _own = EffectTiles.watch(
      inside,
      () {
        // A file put in the user's effects folder shows on the shelves at once. An element file that is overwritten is followed wherever it is used.
        if (mounted) {
          ws.after(inside.later('follow_elements'), (_, _) => ws.reread());
        }
      },
      codeFile: (file) {
        if (mounted) {
          ws.after(inside.later('code', word: file), (_, _) => ws.reread());
        }
      },
    );
    // Follow the elements when the project opens, as AbsentMotion does when a project loads.
    ws.after(inside.later('follow_elements'));
    documentPath = doc;
    beside = _documents();
    final id = await inside.texture();
    if (!mounted) return;
    if (id >= 0) ws.stageTexture = id;
    ws
      ..document = doc.split('/').last
      ..documentFolder = File(doc).parent.path
      ..notice = null
      ..onRender = _render
      ..onSize = (wide, high) {
        // Not awaited: the project's image then reports that it does not fit, and the project is reopened.
        ws.after(inside.later('size', word: '$wide $high'));
      }
      ..refit = () {
        // The stage was opened at a new size: close the project and reopen it at the current time.
        final at = inside.now;
        open(doc);
        engine?.at(at);
      }
      ..join(inside);
    // The menus belong to the open project.
    setState(() {});
  }

  @override
  void dispose() {
    keepPoster();
    FocusManager.instance.removeListener(_keepKeys);
    _windowFocus.dispose();
    _own?.cancel();
    engine?.close();
    ws.dispose();
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
        if (box.maxWidth >= WindowTokens.minWindow.width &&
            box.maxHeight >= WindowTokens.minWindow.height) {
          return window;
        }
        return FittedBox(
          // Laid out at no less than the minimum window size and shrunk only as far as needed, so a zoomed window stays zoomed.
          child: SizedBox(
            width: math.max(box.maxWidth, WindowTokens.minWindow.width),
            height: math.max(box.maxHeight, WindowTokens.minWindow.height),
            child: window,
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final window = WorkspaceScope(
      ws: ws,
      child: Focus(
        focusNode: _windowFocus,
        autofocus: true,
        child: ColoredBox(
          color: WindowTokens.ground,
          child: Stack(
            children: [
              Overlay(initialEntries: [_entry]),
              if (home && documentPath != null && ws.inside != null)
                Positioned.fill(
                  child: HomeWindow(
                    folder: File(documentPath!).parent.path,
                    lib: ws.inside!.libPath,
                    open: documentPath!,
                    onOpen: (d) {
                      setState(() => home = false);
                      if (d != documentPath) open(d);
                    },
                    onExport: _exportFrom,
                    onNew: () {
                      setState(() => home = false);
                      commands()['file.new']!();
                    },
                    onClose: () => setState(() => home = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // The project is still opening, so no panel is built yet.
    if (ws.inside == null) return ColoredBox(color: WindowTokens.ground);
    return PlatformMenuBar(
      menus: menus(),
      child: KeymapShortcuts(
        keymap: keymap,
        commands: commands(),
        child: WindowZoomed(child: window),
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
      SizedBox(height: WindowTokens.topBar, child: TopBar()),
      const SizedBox(height: WindowTokens.gutter),
      Expanded(
        child: Panes(
          panes: WorkspaceScope.read(context).panes,
          preset: workspacePreset,
        ),
      ),
    ],
  );
}
