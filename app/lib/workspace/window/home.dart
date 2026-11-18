// The home screen: a sidebar, a preview of the chosen project, and a bento of every project.
// It is drawn flat, in the manner of a design tool's concept art: solid blocks, one outline width, very large type, and
// the tool's own marks (a bounding box with handles, a tag beside a cursor, a pen path) used as the decoration.
// A collage of those marks covers the whole window; the parts above it are opaque, so it shows wherever they leave room.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/storage/disk.dart' show existsFile;
import 'package:motolii/storage/open_in_host.dart' show pickFolder;
import 'package:motolii/storage/project_files.dart';
import 'package:motolii/storage/thumbnail_folder.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/picks.dart' show clickKeys, pickOnClick;
import 'package:motolii/workspace/state/project_facts.dart';
import 'package:motolii/workspace/window/home_card.dart';
import 'package:motolii/workspace/window/home_collage.dart';
import 'package:motolii/workspace/window/home_grid.dart';
import 'package:motolii/workspace/window/home_hero.dart';
import 'package:motolii/workspace/window/crash_dialog.dart';
import 'package:motolii/workspace/window/home_project.dart';
import 'package:motolii/workspace/window/home_sidebar.dart';
import 'package:motolii/workspace/window/settings/settings_popover.dart';

// A second press on the same project within this time opens it.
const _twice = Duration(milliseconds: 350);

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

  final String folder;
  final String lib;
  final String open;
  final void Function(String doc) onOpen;
  final void Function(List<String> docs) onExport;
  final VoidCallback onNew, onClose;
  final String? lastProject;
  final void Function(String folder)? onFolder;
  @override
  State<HomeWindow> createState() => _HomeWindowState();
}

class _HomeWindowState extends State<HomeWindow> {
  static var byName = false;
  List<HomeProject> _docs = const [];
  String? _menu;
  String? _asking;
  String _find = '';
  final _picked = <String>{};
  String? _lead;
  bool _settings = false;
  late final String _pictures = makeThumbnailFolder();
  final _findText = TextEditingController();

  String? _selected;
  String? _pressed;
  var _pressedAt = DateTime(0);

  @override
  void initState() {
    super.initState();
    _findText.addListener(_found);
    _read();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showCrashDialogIfNeeded(context);
    });
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

  void _choose(String path) {
    final now = DateTime.now();
    if (_pressed == path && now.difference(_pressedAt) < _twice) {
      _pressed = null;
      widget.onOpen(path);
      return;
    }
    _pressed = path;
    _pressedAt = now;
    setState(() => _selected = path);
  }

  List<HomeProject> _sorted() {
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
    return shown;
  }

  @override
  Widget build(BuildContext context) {
    final shown = _sorted();

    final sel = _selected ?? widget.lastProject;
    final hero =
        shown.where((d) => d.path == sel).firstOrNull ?? shown.firstOrNull;

    Widget card(HomeProject d, int i) => HomeCard(
      d,
      index: i,
      open: d.path == widget.open,
      picked: _picked.contains(d.path),
      selected: d.path == hero?.path,
      menu: _menu == d.path,
      asking: _asking == d.path,
      onTap: () {
        final k = clickKeys();
        if (_picked.isEmpty && !k.add && !k.span) return _choose(d.path);
        final r = pickOnClick(
          now: _picked,
          lead: _lead,
          id: d.path,
          order: [for (final e in shown) e.path],
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
      onMore: () => setState(() => _menu = _menu == d.path ? null : d.path),
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
    );

    final side = Shape.z(232), ground = Grey.g00;
    return ColoredBox(
      key: const ValueKey('ws-home'),
      color: ground,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: HomeCollage(
                  tones: homeTones(),
                  ink: Grey.g95,
                  ground: ground,
                  keep: Size(side, Shape.z(440)),
                ),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: side,
                child: HomeSidebar(
                  docs: _docs,
                  folder: widget.folder,
                  selected: hero?.path,
                  find: _findText,
                  onChoose: _choose,
                  onClose: widget.onClose,
                  settings: _settings,
                  onSettings: () => setState(() => _settings = !_settings),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final pad = Shape.s(16), gap = Shape.s(10);
                    final sides = EdgeInsets.only(right: pad);
                    final heroTall = (box.maxHeight * .26)
                        .clamp(180.0, 260.0)
                        .roundToDouble();
                    final rowTall = ((box.maxWidth - pad) * .13)
                        .clamp(100.0, 160.0)
                        .roundToDouble();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ColoredBox(
                          color: ground,
                          child: Padding(
                            padding: sides.copyWith(
                              top: pad,
                              bottom: Shape.s(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: heroTall,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        child: hero == null
                                            ? HomeEmpty(
                                                searching: _find.isNotEmpty,
                                              )
                                            : HomeHero(
                                                d: hero,
                                                index: shown.indexOf(hero),
                                                note: hero.path == widget.open
                                                    ? 'OPEN NOW'
                                                    : hero.path ==
                                                          widget.lastProject
                                                    ? 'LAST OPENED'
                                                    : 'PREVIEW',
                                                action: hero.path == widget.open
                                                    ? 'CONTINUE EDITING →'
                                                    : 'OPEN →',
                                                onOpen: () =>
                                                    widget.onOpen(hero.path),
                                              ),
                                      ),
                                      SizedBox(width: gap),
                                      SizedBox(
                                        width: Shape.z(160),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Expanded(
                                              child: HomeActionCard(
                                                key: const ValueKey('home-new'),
                                                glyph: AppGlyphs.plus,
                                                label: 'NEW PROJECT',
                                                solid: true,
                                                onTap: widget.onNew,
                                              ),
                                            ),
                                            if (widget.onFolder != null) ...[
                                              SizedBox(height: gap),
                                              Expanded(
                                                child: HomeActionCard(
                                                  key: const ValueKey(
                                                    'home-folder',
                                                  ),
                                                  glyph: AppGlyphs.folder,
                                                  label: 'CHANGE FOLDER',
                                                  solid: false,
                                                  onTap: _pickFolder,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: Shape.s(10)),
                                HomeGridHeader(
                                  count: shown.length,
                                  byName: byName,
                                  picked: _picked.length,
                                  onByDate: () =>
                                      setState(() => byName = false),
                                  onByName: () => setState(() => byName = true),
                                  onExport: () => widget.onExport([..._picked]),
                                  onUnpick: () => setState(_picked.clear),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.only(bottom: Shape.s(80)),
                            children: [
                              for (final block in homeBento(
                                [
                                  for (final (i, d) in shown.indexed)
                                    card(d, i),
                                ],
                                rowTall,
                                gap,
                              ))
                                Padding(padding: sides, child: block),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (_settings) ...[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _settings = false),
                child: ColoredBox(color: Grey.g00.withValues(alpha: .3)),
              ),
            ),
            Center(
              child: HomeSettingsPopover(
                folder: widget.folder,
                onFolder: widget.onFolder != null ? _pickFolder : null,
                onSkin: (name) => setState(() => ColorTheme.wear(name)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
