// The whole window: top bar, shelves, Stage, Timeline, Inspector and tool panels.
import 'package:motolii/workspace/workspace_panes.dart';

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart' show Clipboard, MethodChannel;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/skin_parts.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/parent_folder.dart' show parentFolderOf;
import 'package:motolii/storage/pasteboard_files.dart' show onDroppedFiles;
import 'package:motolii/storage/project_files.dart' show projectFilesIn;
import 'package:motolii/storage/window_paths.dart';
import 'package:motolii/workspace/commands/keymap.dart';
import 'package:motolii/workspace/commands/menu_bar.dart';
import 'package:motolii/workspace/commands/menu_items.dart';
import 'package:motolii/workspace/commands/menu_shown.dart';
import 'package:motolii/workspace/commands/panel_requests.dart';
import 'package:motolii/workspace/shelf/effect_tiles.dart';
import 'package:motolii/workspace/state/document/command_writes.dart'
    show copyLayerStyle, copyLayerThing;
import 'package:motolii/workspace/state/engine_access.dart' show projectOpen;
import 'package:motolii/workspace/state/layers/layer_edits.dart'
    show groupBegin, groupEnd;
import 'package:motolii/workspace/state/media/media_service.dart'
    show placeFileLayer;
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/storage/window_settings.dart' show WindowFile;
import 'package:motolii/workspace/state/effect_credits.dart'
    show writeCreditsFile;
import 'package:motolii/workspace/state/project_session.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/stage/stage_service.dart'
    show stageError, stageErrorWithHint, stageTakeStill;
import 'package:motolii/workspace/state/workspace_scope.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/top_bar/top_bar.dart';
import 'package:motolii/workspace/window/home.dart';
import 'package:motolii/workspace/window/panes.dart';
import 'package:motolii/workspace/window/zoom.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key, this.document, this.extra = const []});

  /// When null, the window opens a new untitled project.
  final String? document;

  /// Extra panes that join the Inspector's tabs.
  final List<Pane> extra;
  @override
  State<Workspace> createState() => WorkspaceState();
}

class WorkspaceState extends State<Workspace> {
  late final ws = WorkspaceController()
    ..panes = [...workspacePanes, ...widget.extra];
  final _session = ProjectSession();
  // Watches the user's own effects folder.
  StreamSubscription<String>? _own;

  String? documentPath;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepKeys);
    // Rebuild the window in place whenever the theme file is written.
    ColorTheme.watch(() => WidgetsBinding.instance.reassembleApplication());
    SkinParts.follow();
    // The Edit menu's undo label and the window's title follow the document.
    ws.on[WorkspaceAspect.document]!.addListener(_rebuildMenus);
    onDroppedFiles(_addDroppedPaths);
    final doc = widget.document ?? untitledProjectPath();
    _join(doc);
    home = true;
  }

  void _addDroppedPaths(List<String> paths) {
    if (!projectOpen(ws) || paths.isEmpty) return;
    groupBegin(ws);
    for (final p in paths) {
      placeFileLayer(
        ws,
        file: p,
        verb: 'add',
        fit: false,
        stillSeconds: null,
        cut: null,
        settled: (done, why) {
          if (!done && why.isNotEmpty) {
            ws.notice = 'Not taken: ${why.split(':').first}';
          }
        },
      );
    }
    ws.after(groupEnd(ws));
  }

  // The menus as last made, whose actions are the ones run; the list the menu bar was handed, which runs them
  // (menu_shown.dart); and what that list shows.
  List<PlatformMenuItem> _menusNow = const [], _menusHanded = const [];
  String _menusShown = '';
  // What the last build showed of what a read of the document can change. Null: no project was open.
  (String?, String)? _framed;

  // A read of the document comes with every step of a drag: the window is built again only when what it shows
  // of the document differs.
  void _rebuildMenus() {
    if (!mounted) return;
    final open = projectOpen(ws);
    if (open) _menusNow = menus();
    final frame = open ? (ws.document, menusShown(_menusNow)) : null;
    if (frame != _framed) setState(() {});
  }

  /// Opens another project in place of the current one.
  Future<void> open(String doc) {
    ws.stageTexture = null;
    _session.close();
    return _join(doc);
  }

  /// Saves the project's thumbnail. Not called when switching projects (the old session's requests would go unanswered).
  void keepPoster() => _session.keepPoster(posterPath());

  bool home = false;

  /// The other projects in the same folder.
  List<String> beside = const [];
  List<String> _documents() =>
      [for (final f in projectFilesIn(parentFolderOf(documentPath!))) f.path]
        ..sort();

  /// The file where a copied layer or preset is kept between windows.
  static String clipboard(String what) => clipboardFile(what);

  List<int> pickedLayers() => [
    ...ws.many.isNotEmpty ? ws.many : {?ws.selected},
  ];

  /// Applies [tell] to each selected layer, as a single undo step.
  void eachPicked(int Function(int) tell) {
    final all = pickedLayers();
    if (!projectOpen(ws) || all.isEmpty) return;
    groupBegin(ws);
    for (final t in all) {
      tell(t);
    }
    ws.after(groupEnd(ws));
  }

  /// The system clipboard text at the time of our last copy, to detect whether the clipboard still holds it.
  String? textWhenCopied;

  void copy({bool style = false}) {
    Clipboard.getData(Clipboard.kTextPlain)
        .then((said) => textWhenCopied = said?.text);
    final t = ws.selected;
    if (!projectOpen(ws) || t == null) return;
    if (style) {
      copyLayerStyle(ws, t);
    } else {
      copyLayerThing(ws, t);
    }
  }

  /// Forwards [act] to the focused text field if it handles that intent, so the field keeps its own keys.
  bool typed<T extends Intent>(T act) {
    final box = primaryFocus?.context;
    if (box == null || Actions.maybeFind<T>(box, intent: act) == null) {
      return false;
    }
    Actions.maybeInvoke(box, act);
    return true;
  }

  String fresh() => freeUntitledPath(parentFolderOf(documentPath!));

  /// Exports the project as a video file beside it.
  Future<bool> _render() async {
    final doc = documentPath;
    if (!projectOpen(ws) || doc == null) return false;
    final mp4 = ws.renderTo ?? '${doc.substring(0, doc.lastIndexOf('.'))}.mp4';
    ws.renderTo = null;
    final name = mp4.split('/').last;
    ws.notice = 'Writing $name · Cancel …';
    ws.noticeGo = () => cancelExportOf(ws);
    ws.noticeProgress = 0;
    final poll = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final f = exportFractionOf(ws);
      if (f > 0 && f < 1) {
        ws.notice = 'Writing $name · ${(f * 100).round()}%  ·  Cancel';
        ws.noticeGo = () => cancelExportOf(ws);
        ws.noticeProgress = f;
      }
    });
    final done = await exportVideoTo(ws, mp4);
    poll.cancel();
    if (mounted) {
      final cancelled = !done && stageError(ws) == 'cancelled';
      ws.notice = done
          ? 'Written: $name'
          : cancelled
          ? 'Cancelled writing $name'
          : 'Not written: ${stageErrorWithHint(ws)}';
      ws.noticeProgress = null;
    }
    if (done) {
      writeCreditsFile(ws, mp4);
      if (RegExp(r'\.(mp4|mov|m4v)$').hasMatch(mp4)) {
        unawaited(_checkFlashes(mp4));
      }
    }
    return done;
  }

  /// Checks a newly exported video for flashes that may cause seizures.
  Future<void> _checkFlashes(String film) async {
    final written = 'Written: ${film.split('/').last}',
        checking = '$written · Checking flashes…';
    ws.notice = checking;
    final fails = await flashesIn(ws, film);
    // If the notice changed in the meantime, the newer notice stays.
    if (!mounted || ws.notice != checking) return;
    String clock(double s) =>
        '${s ~/ 60}:${(s % 60).toStringAsFixed(1).padLeft(4, '0')}';
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

  /// Exports the listed projects, one after another. The project that was open is reopened at the end.
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

  /// Gathers the project and its media into `<name> package` beside it.
  void package() {
    final doc = documentPath;
    if (!projectOpen(ws) || doc == null) return;
    final name = doc.split('/').last.replaceFirst(RegExp(r'\.motolii$'), ''),
        folder = '${parentFolderOf(doc)}/$name package';
    final n = packProject(ws, folder, name);
    ws.notice = n < 0
        ? 'Not packaged: ${stageErrorWithHint(ws)}'
        : 'Packaged with $n ${n == 1 ? 'file' : 'files'}: $name package';
  }

  /// Exports the frame at the playhead as a PNG beside the project.
  void exportFrame() {
    final doc = documentPath;
    if (!projectOpen(ws) || doc == null) return;
    final png = '${doc.substring(0, doc.lastIndexOf('.'))}_${ws.frame}.png';
    ws.notice = stageTakeStill(ws, png)
        ? 'Written: ${png.split('/').last}'
        : 'Not written: ${stageErrorWithHint(ws)}';
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

    // If a text field has focus, leave it alone.
    final pf = FocusManager.instance.primaryFocus;
    if (pf != null &&
        pf.context?.findAncestorStateOfType<EditableTextState>() != null) {
      return;
    }
    if (!mounted || !fallen() || _windowFocus.context == null) return;
    // Wait until the frame's own focus requests are done. A field built in this frame requests focus after it, and would lose it to us.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => scheduleMicrotask(() {
        if (mounted && fallen()) _windowFocus.requestFocus();
      }),
    );
  }

  late final keymap = Keymap.load();
  Future<void> _join(String doc) async {
    if (!_session.open(doc)) return;
    _session.followOnOpen(ws);
    documentPath = doc;
    beside = _documents();
    const MethodChannel('motolii/recent')
        .invokeMethod<void>('note', doc)
        .catchError((_) {});
    final id = await _session.texture();
    if (!mounted) return;
    if (id >= 0) ws.stageTexture = id;
    ws
      ..document = doc.split('/').last
      ..documentFolder = parentFolderOf(doc)
      ..notice = null
      ..onRender = _render
      ..onSize = (wide, high) {
        // Not awaited: the project's image then reports that it does not fit, and the project is reopened.
        ws.after(resizeProject(ws, wide, high));
      }
      ..refit = () {
        // The stage was opened at a new size: close the project and reopen it at the current time.
        final at = _session.now;
        open(doc);
        _session.seek(at);
      };
    _session.joinInto(ws);
    // Live-reload when the user's effects folder or an element file changes.
    _own = EffectTiles.watch(
      ws,
      () {
        if (mounted) {
          ws.after(followElements(ws), (_, _) => ws.reread());
        }
      },
      codeFile: (file) {
        if (mounted) {
          ws.after(codeChanged(ws, file), (_, _) => ws.reread());
        }
      },
    );
    WindowFile.lastProject = doc;
    // The menus belong to the open project.
    setState(() {});
  }

  @override
  void dispose() {
    keepPoster();
    FocusManager.instance.removeListener(_keepKeys);
    ws.on[WorkspaceAspect.document]!.removeListener(_rebuildMenus);
    _windowFocus.dispose();
    _own?.cancel();
    _session.close();
    ws.dispose();
    super.dispose();
  }

  /// The panes drag their tabs on an overlay. The window provides its own so this works under any host.
  late final _entry = OverlayEntry(
    maintainState: true,
    builder: (context) => LayoutBuilder(
      builder: (context, box) {
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
              if (home && documentPath != null && projectOpen(ws))
                Positioned.fill(
                  child: Overlay(
                    initialEntries: [
                      OverlayEntry(
                        builder: (_) => HomeWindow(
                          folder:
                              WindowFile.projectsFolder ??
                              parentFolderOf(documentPath!),
                          lib: engineLibPath(ws),
                          open: documentPath!,
                          lastProject: WindowFile.lastProject,
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
                          onFolder: (folder) {
                            WindowFile.projectsFolder = folder;
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    // The project is still opening, so no panel is built yet.
    if (!projectOpen(ws)) {
      _framed = null;
      return ColoredBox(color: WindowTokens.ground);
    }
    _menusNow = menus();
    if (menusShown(_menusNow) case final shown when shown != _menusShown) {
      _menusShown = shown;
      _menusHanded = menusCalling(_menusNow, () => _menusNow);
    }
    _framed = (ws.document, _menusShown);
    return Title(
      title: ws.document ?? 'Motolii',
      color: WindowTokens.ground,
      child: PlatformMenuBar(
        menus: _menusHanded,
        child: KeymapShortcuts(
          keymap: keymap,
          commands: commands(),
          child: WindowZoomed(child: window),
        ),
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
          workspaces: workspaces,
        ),
      ),
    ],
  );
}
