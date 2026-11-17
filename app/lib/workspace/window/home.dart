// The home screen: a responsive grid of the projects in a folder.
//
// A hero banner shows the last project ("Continue"), then a responsive grid of 16:9 cards with hover-reveal metadata.
// Clicking a card opens it. Its menu can select, export, duplicate, or move it to the Trash after a confirmation.
// The thumbnail, size and length come from what the project last saved (Motolii.poster), read without opening it.
import 'package:motolii/widgets/picks.dart' show clickKeys, pickOnClick;
import 'package:motolii/workspace/window/home_project.dart';
import 'package:motolii/workspace/window/home_card.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/storage/disk.dart' show existsFile, imageFile;
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
  bool _hoverBanner = false;
  bool _hoverNew = false;
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

  /// The hero banner: the last project, shown as a wide 16:9 card with its thumbnail.
  Widget? _continueCard() {
    final last = widget.lastProject;
    if (last == null || !existsFile(last)) return null;
    final name = last.split('/').last.replaceFirst(RegExp(r'\.motolii$'), '');
    final lastDoc = _docs.where((d) => d.path == last).firstOrNull;
    final facts = lastDoc != null ? homeFacts(lastDoc) : const <String>[];
    final hb = _hoverBanner;
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverBanner = true),
      onExit: (_) => setState(() => _hoverBanner = false),
      child: NakedButton(
        enableFeedback: false,
        key: const ValueKey('home-continue'),
        onPressed: () => widget.onOpen(last),
        child: AnimatedScale(
          scale: hb ? 1.01 : 1.0,
          duration: Motion.dur,
          curve: Motion.ease,
          child: AnimatedContainer(
            duration: Motion.dur,
            height: Shape.z(220),
            decoration: BoxDecoration(
              borderRadius: Shape.round(12),
              boxShadow: [
                BoxShadow(
                  color: Grey.g00.withValues(alpha: hb ? .3 : 0),
                  blurRadius: hb ? 20 : 0,
                  offset: Offset(0, hb ? 8 : 0),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (lastDoc?.picture != null)
                  Image(image: imageFile(lastDoc!.picture!), fit: BoxFit.cover)
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [seedColor(name), seedColorLight(name)],
                      ),
                    ),
                    child: Align(
                      alignment: const Alignment(.85, -.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'M',
                        style: TextStyle(
                          fontSize: 140,
                          fontWeight: FontWeight.w900,
                          color: Grey.g95.withValues(alpha: .04),
                          letterSpacing: -5,
                        ),
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Grey.g00.withValues(alpha: 0),
                        Grey.g00.withValues(alpha: .15),
                        Grey.g00.withValues(alpha: .75),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Shape.s(32),
                    vertical: Shape.s(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 24,
                        height: 2,
                        color: WindowTokens.accent,
                      ),
                      SizedBox(height: Shape.s(10)),
                      Text(
                        'CONTINUE',
                        style: TextStyles.micro(WindowTokens.accent).copyWith(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                          fontSize: TextStyles.px(9),
                        ),
                      ),
                      SizedBox(height: Shape.s(4)),
                      Text(
                        name,
                        style: TextStyles.title(Grey.g95).copyWith(
                          fontSize: TextStyles.px(28),
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.5,
                        ),
                      ),
                      if (facts.isNotEmpty) ...[
                        SizedBox(height: Shape.s(4)),
                        Text(
                          facts.join(' · '),
                          style: TextStyles.label(Grey.g56),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static int _totalBytes(List<HomeProject> docs) =>
      docs.fold(0, (sum, d) => sum + d.bytes);
  static double _totalSeconds(List<HomeProject> docs) =>
      docs.fold(0.0, (sum, d) => sum + (d.facts?.seconds ?? 0));

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
    final shown = [
      for (final d in _docs)
        if (d.name.toLowerCase().contains(_find.toLowerCase())) d,
    ];
    if (!byName) {
      shown.sort((a, b) => b.changed.compareTo(a.changed));
    } else {
      shown.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    }
    Widget grid(List<HomeProject> docs) => LayoutBuilder(
      builder: (context, box) {
        final gap = box.maxWidth > 800 ? 36.0 : 24.0;
        final maxCols = docs.length.clamp(1, 4);
        final cols = ((box.maxWidth + gap) / (homeTile + gap)).floor().clamp(
          1,
          maxCols,
        );
        final tile = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (i, d) in docs.indexed)
              SizedBox(
                width: tile,
                child: HomeCard(
                  d,
                  index: i,
                  open: d.path == widget.open,
                  picked: _picked.contains(d.path),
                  menu: _menu == d.path,
                  asking: _asking == d.path,
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
              ),
          ],
        );
      },
    );
    return Stack(
      key: const ValueKey('ws-home'),
      children: [
        Positioned.fill(child: ColoredBox(color: Grey.g10)),
        Positioned(
          top: -100,
          left: 0,
          right: 0,
          height: 500,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-.4, .3),
                radius: 1.0,
                colors: [
                  WindowTokens.accent.withValues(alpha: .04),
                  Grey.g10.withValues(alpha: 0),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 3, color: WindowTokens.accent),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  Shape.s(48),
                  Shape.s(24),
                  Shape.s(48),
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _HomeWordmark(),
                        const Spacer(),
                        MouseRegion(
                          onEnter: (_) => setState(() => _hoverNew = true),
                          onExit: (_) => setState(() => _hoverNew = false),
                          child: NakedButton(
                            enableFeedback: false,
                            key: const ValueKey('home-new'),
                            onPressed: widget.onNew,
                            child: AnimatedContainer(
                              duration: Motion.dur,
                              padding: EdgeInsets.symmetric(
                                horizontal: Shape.s(14),
                                vertical: Shape.s(6),
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _hoverNew ? Grey.g56 : Grey.g38,
                                ),
                                borderRadius: Shape.round(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '+',
                                    style: TextStyles.name(
                                      _hoverNew ? Grey.g91 : Grey.g76,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: Shape.s(6)),
                                  Text(
                                    'New',
                                    style: TextStyles.name(
                                      _hoverNew ? Grey.g91 : Grey.g76,
                                    ).copyWith(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Shape.s(12)),
                        if (widget.onFolder != null)
                          IconPress(
                            (c) => Glyph(
                              AppGlyphs.folder,
                              size: Shape.z(12),
                              color: c,
                            ),
                            key: const ValueKey('home-folder'),
                            tip: 'Change Folder',
                            onTap: _pickFolder,
                            size: Shape.z(28),
                            ink: Grey.g56,
                          ),
                        IconPress(
                          (c) => Glyph(
                            AppGlyphs.close,
                            size: Shape.z(14),
                            color: c,
                          ),
                          key: const ValueKey('home-close'),
                          tip: 'Close',
                          onTap: widget.onClose,
                          size: Shape.z(28),
                          ink: Grey.g56,
                        ),
                      ],
                    ),
                    SizedBox(height: Shape.s(24)),
                    if (_find.isEmpty)
                      if (_continueCard() case final card?) ...[
                        card,
                        SizedBox(height: Shape.s(28)),
                      ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${shown.length}',
                          style: TextStyles.title(Grey.g95).copyWith(
                            fontSize: TextStyles.px(26),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(width: Shape.s(6)),
                        Padding(
                          padding: EdgeInsets.only(top: Shape.s(2)),
                          child: Text(
                            [
                              shown.length == 1 ? 'project' : 'projects',
                              if (shown.isNotEmpty)
                                homeBytes(_totalBytes(shown)),
                              if (_totalSeconds(shown) > 0)
                                homeLength(_totalSeconds(shown)),
                            ].join(' · '),
                            style: TextStyles.label(Grey.g44)
                                .copyWith(letterSpacing: 1.5),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: Shape.z(200),
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
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: Shape.s(16)),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 2,
                            color: WindowTokens.accent,
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Grey.g20.withValues(alpha: .4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: shown.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _find.isNotEmpty
                                        ? 'No matches'
                                        : 'No projects yet',
                                    style: TextStyles.title(Grey.g44).copyWith(
                                      fontSize: TextStyles.px(20),
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: .5,
                                    ),
                                  ),
                                  SizedBox(height: Shape.s(10)),
                                  Text(
                                    _find.isNotEmpty
                                        ? 'Try a different search.'
                                        : 'Create one to get started.',
                                    style: TextStyles.label(Grey.g38),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              padding: EdgeInsets.only(bottom: Shape.s(48)),
                              children: [grid(shown)],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
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
        decoration: BoxDecoration(
          color: WindowTokens.accent,
          borderRadius: Shape.round(6),
        ),
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
      SizedBox(width: Shape.s(10)),
      Container(width: 2, height: Shape.z(20), color: WindowTokens.accent),
    ],
  );
}
