// The whole window: the inspector, under the menu.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'window/zoom.dart';
import 'commands/command_actions.dart';
import 'package:motolii/inspector/inspector_parts_insp_host.dart';

import '../inspector/inspector_parts.dart';
import '../skin/theme.dart';
import 'commands/keymap.dart';
import '../bridge/motolii.dart';
import 'state/state.dart';
part 'inspector_feed/panel.dart';
part 'inspector_feed/cards.dart';
part 'inspector_feed/values.dart';
part 'inspector_feed/keyframe_marks.dart';
part 'commands/menu_bar.dart';

class Workspace extends StatefulWidget {
  const Workspace({super.key, this.document});

  /// A document of the inside (motolii.dart) to join the window to: its stage is then the inside's own picture.
  /// null: the sample, with its stand-in art.
  final String? document;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> {
  late final _ws = Ws();
  Motolii? _inside;

  String? _doc; // (the document that is open: the one the window was given, or one made or opened from the menu)

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_keepKeys);
    ColorTheme.watch(() => WidgetsBinding.instance.reassembleApplication());
    _join(
      widget.document ?? '${Directory.systemTemp.createTempSync('motolii').path}/Untitled.motolii',
    ); // (no document given: a new one, as After Effects opens an untitled project)
  }

  /// Another document in place of the open one (made, if there is none at that place).
  Future<void> _open(String doc) {
    _inside?.close();
    _inside = null;
    return _join(doc);
  }

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

  /// The document and its media gathered into "<name> package" beside it (Alight Motion's project package).
  void _package() {
    final m = _inside, doc = _doc;
    if (m == null || doc == null) return;
    final name = doc.split('/').last.replaceFirst(RegExp(r'\.motolii$'), ''), folder = '${File(doc).parent.path}/$name package';
    m.pack(folder, name);
  }

  /// The picture at the playhead written beside the document (Premiere Pro's Export Frame).
  void _exportFrame() {
    final m = _inside, doc = _doc;
    if (m == null || doc == null) return;
    final png = '${doc.substring(0, doc.lastIndexOf('.'))}_${_ws.frame}.png';
    m.still(png);
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
    _ws.after(inside.later('follow_elements')); // (as the document is opened: AbsentMotion's elements followed as a project is loaded)
    _doc = doc;
    _beside = _documents();
    await inside.texture();
    if (!mounted) return;
    _ws
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
    _inside?.poster('${Directory.systemTemp.path}/motolii_poster_$pid.png'); // (as the window closes; not as another is opened in its place)
    FocusManager.instance.removeListener(_keepKeys);
    _windowFocus.dispose();
    _inside?.close();
    _ws.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final window = WsScope(
      ws: _ws,
      child: Focus(
        focusNode: _windowFocus,
        autofocus: true,
        child: ColoredBox(color: WsT.ground, child: const _Window()),
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
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(height: WsT.gutter),
      Expanded(child: WsPanel(child: _InspectorPanel())),
    ],
  );
}
