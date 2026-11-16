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
                top: rows.isEmpty ? 0 : Shape.s(24),
                bottom: Shape.s(12),
              ),
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
        padding: EdgeInsets.fromLTRB(Shape.s(32), Shape.s(24), Shape.s(32), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Spacer(),
                // Icon button with the standard close glyph, matching the rest of the app.
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
            SizedBox(height: Shape.s(8)),
            NakedButton(
              enableFeedback: false,
              // CapCut's "Create project": a button as wide as the page, with the + glyph set apart from the label so it reads as a button, not a line of text.
              key: const ValueKey('home-new'),
              onPressed: widget.onNew,
              child: Container(
                height: Shape.z(112),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WindowTokens.card,
                  borderRadius: Shape.round(12),
                  border: Border.all(
                    color: WindowTokens.raised,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // The lime "+" badge: the same manner as the top bar's wordmark, so a "create" action reads as a first-class control.
                    Container(
                      width: Shape.z(36),
                      height: Shape.z(36),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: WindowTokens.accent,
                        borderRadius: Shape.round(8),
                      ),
                      child: Text(
                        '+',
                        style: TextStyles.title(WindowTokens.onAccent).copyWith(
                          fontSize: TextStyles.px(22),
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    SizedBox(width: Shape.s(14)),
                    Text('New Project', style: TextStyles.title(Grey.g91).bold),
                  ],
                ),
              ),
            ),
            SizedBox(height: Shape.s(28)),
            Row(
              children: [
                Text('Projects', style: TextStyles.title(Grey.g91)),
                const Spacer(),
                SizedBox(
                  width: Shape.z(180),
                  child: ShelfSearchField(
                    controller: _findText,
                    hint: 'Search',
                  ),
                ),
                SizedBox(width: Shape.s(8)),
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
