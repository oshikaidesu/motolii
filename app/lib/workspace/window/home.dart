// The home screen: a grid of the projects in a folder.
//
// The layout follows CapCut's desktop home: a wide "New Project" button, then "Projects" with a search field and a grid
// of square thumbnails, each with its name and "size | length" below.
// The facts shown (aspect ratio, resolution, frame rate) and the grouping follow AbsentMotion (Apache-2.0,
// ui/home/HomeScreen.kt, ProjectFacts.kt aspectName, ExportOptions.kt formatBytes):
// projects are grouped under the day they were last changed, newest first, or listed by name.
// Clicking a card opens it. Its menu can select, export, duplicate, or move it to the Trash after a confirmation.
// The thumbnail, size and length come from what the project last saved (Motolii.poster), read without opening it.
import 'package:motolii/workspace/window/home_project.dart';
import 'package:motolii/workspace/window/home_card.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:io';

import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/bridge/motolii.dart' show docFactsOf;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/text_gestures.dart';

class HomeWindow extends StatefulWidget {
  const HomeWindow({
    super.key,
    required this.folder,
    required this.lib,
    required this.open,
    required this.onOpen,
    required this.onExport,
    required this.onNew,
    required this.onClose,
  });

  /// The folder whose projects are listed.
  final String folder;

  /// The engine library, used to read each project's facts on another isolate.
  final String lib;

  /// The path of the project that is open now.
  final String open;
  final void Function(String doc) onOpen;
  final void Function(List<String> docs) onExport;
  final VoidCallback onNew, onClose;
  @override
  State<HomeWindow> createState() => _HomeWindowState();
}

class _HomeWindowState extends State<HomeWindow> {
  // The last sort order chosen, kept like AbsentMotion's sortBy.
  static var byName = false;
  List<HomeProject> _docs = const [];
  // The card whose menu is open.
  String? _menu;
  // The card waiting for the user to confirm moving it to the Trash.
  String? _asking;
  // The search text, matched against project names.
  String _find = '';
  // Selected projects, as in Alight Motion's menu "Select" or Cmd-click in the Finder.
  // While any is selected, a click toggles selection instead of opening.
  final _picked = <String>{};
  late final Directory _pictures = Directory.systemTemp.createTempSync(
    'motolii_home',
  );

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void dispose() {
    _findText.dispose();
    _findFocus.dispose();
    try {
      _pictures.deleteSync(recursive: true);
    } catch (_) {}
    super.dispose();
  }

  // Counts reads so each read writes thumbnails under new names and never overwrites one that is on screen.
  var _reads = 0;
  void _read() {
    final docs = <HomeProject>[], read = _reads++;
    for (final f in Directory(widget.folder).listSync().whereType<File>()) {
      if (!f.path.endsWith('.motolii')) continue;
      final s = f.statSync();
      docs.add(HomeProject(f.path, s.modified, s.size));
    }
    setState(() => _docs = docs);
    for (final (i, d) in docs.indexed) {
      final png = '${_pictures.path}/$read-$i.png';
      docFactsOf(widget.lib, d.path, png).then((facts) {
        if (!mounted) return;
        setState(
          () => d
            ..facts = facts
            ..picture = facts != null && File(png).existsSync() ? png : null,
        );
      });
    }
  }

  void _duplicate(HomeProject d) {
    duplicateProject(widget.folder, d);
    _menu = null;
    _read();
  }

  void _trash(HomeProject d) {
    if (!trashProject(d)) return;
    _menu = _asking = null;
    _read();
  }

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[],
        shown = [
          for (final d in _docs)
            if (d.name.toLowerCase().contains(_find.toLowerCase())) d,
        ];
    Widget grid(List<HomeProject> docs) => Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        for (final d in docs)
          HomeCard(
            d,
            open: d.path == widget.open,
            picked: _picked.contains(d.path),
            menu: _menu == d.path,
            asking: _asking == d.path,
            onTap: () =>
                _picked.isNotEmpty || HardwareKeyboard.instance.isMetaPressed
                ? setState(() {
                    if (!_picked.remove(d.path)) _picked.add(d.path);
                  })
                : widget.onOpen(d.path),
            onMore: () =>
                setState(() => _menu = _menu == d.path ? null : d.path),
            onOpen: () => widget.onOpen(d.path),
            onSelect: () => setState(() {
              _picked.add(d.path);
              _menu = null;
            }),
            onExport: () => widget.onExport([d.path]),
            onDuplicate: () => _duplicate(d),
            onAskTrash: () => setState(() => _asking = d.path),
            onTrash: () => _trash(d),
            onKeep: () => setState(() => _asking = null),
          ),
      ],
    );
    if (byName) {
      rows.add(
        grid(
          shown..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          ),
        ),
      );
    } else {
      final byDay = <String, List<HomeProject>>{};
      for (final d in shown..sort((a, b) => b.changed.compareTo(a.changed))) {
        (byDay[homeDay(d.changed)] ??= []).add(d);
      }
      for (final MapEntry(key: day, value: docs) in byDay.entries) {
        rows
          ..add(
            Padding(
              padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 24, bottom: 12),
              child: Text(day, style: TextStyles.label(Grey.g76)),
            ),
          )
          ..add(grid(docs));
      }
    }
    return ColoredBox(
      key: const ValueKey('ws-home'),
      color: WindowTokens.ground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                homeButton('home-close', '×', false, widget.onClose),
              ],
            ),
            const SizedBox(height: 8),
            NakedButton(
              enableFeedback: false,
              // CapCut's "Create project": a button as wide as the page.
              key: const ValueKey('home-new'),
              onPressed: widget.onNew,
              child: Container(
                height: 120,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WindowTokens.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: WindowTokens.raised),
                ),
                child: Text(
                  '+  New Project',
                  style: TextStyles.title(Grey.g91),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Projects', style: TextStyles.title(Grey.g91)),
                const Spacer(),
                SizedBox(
                  width: 180,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: WindowTokens.inset,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: WindowTokens.card,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: TextGestures(
                      key: const ValueKey('home-find'),
                      field: (k) => EditableText(
                        key: k,
                        rendererIgnoresPointer: true,
                        controller: _findText,
                        focusNode: _findFocus,
                        style: TextStyles.label(Grey.g91),
                        cursorColor: WindowTokens.accent,
                        backgroundCursorColor: Grey.g63,
                        onChanged: (v) => setState(() => _find = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_picked.isNotEmpty) ...[
                  homeButton(
                    'home-export',
                    'Export ${_picked.length}',
                    true,
                    () => widget.onExport([..._picked]),
                  ),
                  homeButton(
                    'home-unpick',
                    'Cancel',
                    false,
                    () => setState(_picked.clear),
                  ),
                  const SizedBox(width: 8),
                ],
                homeButton(
                  'home-by-date',
                  'Date',
                  !byName,
                  () => setState(() => byName = false),
                ),
                homeButton(
                  'home-by-name',
                  'Name',
                  byName,
                  () => setState(() => byName = true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: ListView(children: rows)),
          ],
        ),
      ),
    );
  }

  final _findText = TextEditingController();
  final _findFocus = FocusNode();
}
