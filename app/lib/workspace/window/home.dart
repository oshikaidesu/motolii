// The home screen: a grid of the projects in a folder.
//
// The layout follows CapCut's desktop home: a wide "New Project" button, then "Projects" with a search field and a grid
// of square thumbnails, each with its name and "size | length" below.
// The facts shown (aspect ratio, resolution, frame rate) and the grouping follow AbsentMotion (Apache-2.0,
// ui/home/HomeScreen.kt, ProjectFacts.kt aspectName, ExportOptions.kt formatBytes):
// projects are grouped under the day they were last changed, newest first, or listed by name.
// Clicking a card opens it. Its menu can select, export, duplicate, or move it to the Trash after a confirmation.
// The thumbnail, size and length come from what the project last saved (Motolii.poster), read without opening it.
import 'package:motolii/widgets/picks.dart' show clickKeys, pickOnClick;
import 'package:motolii/workspace/window/home_project.dart';
import 'package:motolii/workspace/window/home_card.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/open_in_host.dart' show pickFolder;
import 'package:motolii/storage/project_files.dart';
import 'package:motolii/storage/thumbnail_folder.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show IconPress;
import 'package:motolii/workspace/dock/common/shelf_search_field.dart';
import 'package:motolii/workspace/state/project_facts.dart';

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
    this.lastProject,
    this.onFolder,
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

  /// The last project the user worked on, shown as "continue from here" at the top (UAT 94).
  final String? lastProject;

  /// Called with a folder path to change where the home screen looks for projects (UAT 98).
  final void Function(String folder)? onFolder;
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
  // The project the last pick was on, where a Shift range starts.
  String? _lead;
  late final String _pictures = makeThumbnailFolder();

  @override
  void initState() {
    super.initState();
    _findText.addListener(_found);
    _read();
  }

  void _found() {
    if (_findText.text != _find) setState(() => _find = _findText.text);
  }

  @override
  void dispose() {
    _findText.dispose();
    try {
      removeThumbnailFolder(_pictures);
    } catch (_) {}
    super.dispose();
  }

  // Counts reads so each read writes thumbnails under new names and never overwrites one that is on screen.
  var _reads = 0;
  void _read() {
    final docs = <HomeProject>[], read = _reads++;
    for (final f in projectFilesIn(widget.folder)) {
      docs.add(HomeProject(f.path, f.modified, f.size));
    }
    setState(() => _docs = docs);
    for (final (i, d) in docs.indexed) {
      final png = '$_pictures/$read-$i.png';
      savedProjectFacts(widget.lib, d.path, png).then((facts) {
        if (!mounted) return;
        setState(
          () => d
            ..facts = facts
            ..picture = facts != null && existsFile(png) ? png : null,
        );
      });
    }
  }

  Future<void> _pickFolder() async {
    final folder = await pickFolder(prompt: 'Choose projects folder');
    if (folder != null && mounted) widget.onFolder?.call(folder);
  }

  /// The "continue from here" card: the last project the user worked on, shown large (UAT 94).
  Widget? _continueCard() {
    final last = widget.lastProject;
    if (last == null || !existsFile(last)) return null;
    final name = last.split('/').last.replaceFirst(RegExp(r'\.motolii$'), '');
    final lastDoc = _docs.where((d) => d.path == last).firstOrNull;
    final facts = lastDoc != null ? homeFacts(lastDoc) : const <String>[];
    return NakedButton(
      enableFeedback: false,
      key: const ValueKey('home-continue'),
      onPressed: () => widget.onOpen(last),
      child: Container(
        height: Shape.z(80),
        padding: EdgeInsets.symmetric(horizontal: Shape.s(28)),
        decoration: BoxDecoration(
          color: WindowTokens.card,
          borderRadius: Shape.round(14),
          border: Border.all(color: WindowTokens.accent, width: 1.5),
        ),
        child: Row(
          children: [
            Glyph(AppGlyphs.chevron, size: Shape.z(14), color: Grey.g91),
            SizedBox(width: Shape.s(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: TextStyles.title(Grey.g95).bold),
                  if (facts.isNotEmpty) ...[
                    SizedBox(height: Shape.s(3)),
                    Text(facts.join(' · '), style: TextStyles.label(Grey.g56)),
                  ],
                ],
              ),
            ),
            Text('Continue', style: TextStyles.label(Grey.g63)),
          ],
        ),
      ),
    );
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
            // A press opens the project; with some picked, or with Cmd or Shift held, it picks by the rule of picks.dart.
            onTap: () {
              final k = clickKeys();
              if (_picked.isEmpty && !k.add && !k.span) {
                return widget.onOpen(d.path);
              }
              final r = pickOnClick(
                now: _picked,
                lead: _lead,
                id: d.path,
                order: [for (final e in docs) e.path],
                add: k.add || !k.span,
                span: k.span,
              );
              setState(() {
                _picked
                  ..clear()
                  ..addAll(r.picked);
                _lead = r.lead;
              });
            },
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
              padding: EdgeInsets.only(
                top: rows.isEmpty ? 0 : Shape.s(28),
                bottom: Shape.s(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(day, style: TextStyles.name(Grey.g91).bold),
                  SizedBox(width: Shape.s(10)),
                  // A hair-line that stretches across the remaining width ties the group together and separates it from the one above.
                  Expanded(
                    child: Container(height: 1, color: WindowTokens.line),
                  ),
                ],
              ),
            ),
          )
          ..add(grid(docs));
      }
    }
    return ColoredBox(
      key: const ValueKey('ws-home'),
      color: WindowTokens.ground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(Shape.s(40), Shape.s(28), Shape.s(40), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top band: the same wordmark as the main window's top bar, so Home reads as the app's front door, and a plain close icon on the right.
            Row(
              children: [
                _HomeWordmark(),
                const Spacer(),
                IconPress(
                  (c) => Glyph(AppGlyphs.close, size: Shape.z(14), color: c),
                  key: const ValueKey('home-close'),
                  tip: 'Close',
                  onTap: widget.onClose,
                  size: Shape.z(28),
                  ink: Grey.g63,
                ),
              ],
            ),
            SizedBox(height: Shape.s(22)),
            if (_continueCard() case final card?) ...[
              card,
              SizedBox(height: Shape.s(14)),
            ],
            NakedButton(
              enableFeedback: false,
              // "New Project" is the first thing after the wordmark: a wide button with an accent "+" badge to the left of the label, so the action reads as first-class.
              key: const ValueKey('home-new'),
              onPressed: widget.onNew,
              child: Container(
                height: Shape.z(112),
                padding: EdgeInsets.symmetric(horizontal: Shape.s(28)),
                decoration: BoxDecoration(
                  color: WindowTokens.card,
                  borderRadius: Shape.round(14),
                  border: Border.all(color: WindowTokens.line),
                ),
                child: Row(
                  children: [
                    Container(
                      width: Shape.z(40),
                      height: Shape.z(40),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WindowTokens.accent,
                        borderRadius: Shape.round(10),
                      ),
                      child: Text(
                        '+',
                        style: TextStyles.title(WindowTokens.onAccent).copyWith(
                          fontSize: TextStyles.px(24),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: Shape.s(16)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'New Project',
                            style: TextStyles.title(Grey.g91).bold,
                          ),
                          SizedBox(height: Shape.s(3)),
                          Text(
                            'Start with an empty composition',
                            style: TextStyles.label(Grey.g56),
                          ),
                        ],
                      ),
                    ),
                    Glyph(
                      AppGlyphs.chevron,
                      size: Shape.z(14),
                      color: Grey.g56,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: Shape.s(32)),
            // "Projects · N" header line with search on the right and the sort chips next to it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Projects', style: TextStyles.title(Grey.g91).bold),
                SizedBox(width: Shape.s(10)),
                Text('${shown.length}', style: TextStyles.title(Grey.g56)),
                if (widget.onFolder != null) ...[
                  SizedBox(width: Shape.s(10)),
                  IconPress(
                    (c) => Glyph(AppGlyphs.folder, size: Shape.z(12), color: c),
                    key: const ValueKey('home-folder'),
                    tip: 'Change Folder',
                    onTap: _pickFolder,
                    size: Shape.z(22),
                    ink: Grey.g56,
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: Shape.z(220),
                  child: ShelfSearchField(
                    controller: _findText,
                    hint: 'Search',
                  ),
                ),
                SizedBox(width: Shape.s(10)),
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
                  SizedBox(width: Shape.s(8)),
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
            SizedBox(height: Shape.s(16)),
            Expanded(child: ListView(children: rows)),
          ],
        ),
      ),
    );
  }

  final _findText = TextEditingController();
}

/// The lime "M" square and "Motolii" wordmark, as in the main window's top bar. One manner used in both places so Home
/// reads as the same app, not a splash screen.
class _HomeWordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: Shape.z(28),
        height: Shape.z(28),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: WindowTokens.accent),
        child: Text(
          'M',
          style: TextStyles.title(WindowTokens.onAccent).copyWith(
            fontSize: TextStyles.px(16),
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
      SizedBox(width: Shape.s(10)),
      Text(
        'Motolii',
        style: TextStyles.title(Grey.g95).copyWith(
          fontSize: TextStyles.px(18),
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
        ),
      ),
    ],
  );
}
