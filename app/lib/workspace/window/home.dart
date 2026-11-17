// The home screen: the user's projects, filling the window edge to edge.
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

    Widget card(HomeProject d, int i, List<HomeProject> docs) => HomeCard(
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

    // The last-worked project leads the grid at double width.
    final last = widget.lastProject;
    final hasLast =
        last != null &&
        existsFile(last) &&
        _find.isEmpty &&
        shown.any((d) => d.path == last);

    return ColoredBox(
      key: const ValueKey('ws-home'),
      color: Grey.g07,
      child: Column(
        children: [
          _TopBar(
            count: shown.length,
            find: _findText,
            byName: byName,
            picked: _picked,
            onNew: widget.onNew,
            onClose: widget.onClose,
            onFolder: widget.onFolder != null ? _pickFolder : null,
            onExport: () => widget.onExport([..._picked]),
            onUnpick: () => setState(_picked.clear),
            onByDate: () => setState(() => byName = false),
            onByName: () => setState(() => byName = true),
          ),
          Expanded(
            child: shown.isEmpty
                ? _Empty(searching: _find.isNotEmpty)
                : LayoutBuilder(
                    builder: (context, box) {
                      final pad = Shape.s(20);
                      final gap = Shape.s(12);
                      final w = box.maxWidth - pad * 2;
                      final cols = (w / 280).floor().clamp(2, 5);
                      final tile = (w - gap * (cols - 1)) / cols;
                      final items = <Widget>[];
                      for (final (i, d) in shown.indexed) {
                        final isLast = hasLast && d.path == last;
                        final span = isLast && cols >= 3 ? 2 : 1;
                        items.add(
                          SizedBox(
                            width: tile * span + gap * (span - 1),
                            child: card(d, i, shown),
                          ),
                        );
                      }
                      return ListView(
                        padding: EdgeInsets.fromLTRB(
                          pad,
                          Shape.s(8),
                          pad,
                          Shape.s(40),
                        ),
                        children: [
                          Wrap(spacing: gap, runSpacing: gap, children: items),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  final _findText = TextEditingController();
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.count,
    required this.find,
    required this.byName,
    required this.picked,
    required this.onNew,
    required this.onClose,
    required this.onFolder,
    required this.onExport,
    required this.onUnpick,
    required this.onByDate,
    required this.onByName,
  });
  final int count;
  final TextEditingController find;
  final bool byName;
  final Set<String> picked;
  final VoidCallback onNew, onClose, onExport, onUnpick, onByDate, onByName;
  final VoidCallback? onFolder;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(
      Shape.s(20),
      Shape.s(10),
      Shape.s(20),
      Shape.s(10),
    ),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Grey.g15)),
    ),
    child: Row(
      children: [
        Container(
          width: Shape.z(22),
          height: Shape.z(22),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: WindowTokens.accent,
            borderRadius: Shape.round(5),
          ),
          child: Text(
            'M',
            style: TextStyles.title(WindowTokens.onAccent).copyWith(
              fontSize: TextStyles.px(13),
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        SizedBox(width: Shape.s(8)),
        Text(
          'Motolii',
          style: TextStyles.name(Grey.g76)
              .copyWith(fontWeight: FontWeight.w700, letterSpacing: -.3),
        ),
        SizedBox(width: Shape.s(16)),
        SizedBox(
          width: Shape.z(180),
          child: ShelfSearchField(controller: find, hint: 'Search'),
        ),
        const Spacer(),
        if (picked.isNotEmpty) ...[
          homeButton('home-export', 'Export ${picked.length}', true, onExport),
          homeButton('home-unpick', 'Cancel', false, onUnpick),
          SizedBox(width: Shape.s(8)),
        ],
        homeButton('home-by-date', 'Date', !byName, onByDate),
        homeButton('home-by-name', 'Name', byName, onByName),
        SizedBox(width: Shape.s(12)),
        _NewButton(onTap: onNew),
        SizedBox(width: Shape.s(4)),
        if (onFolder != null)
          IconPress(
            (c) => Glyph(AppGlyphs.folder, size: Shape.z(12), color: c),
            key: const ValueKey('home-folder'),
            tip: 'Change Folder',
            onTap: onFolder!,
            size: Shape.z(28),
            ink: Grey.g56,
          ),
        IconPress(
          (c) => Glyph(AppGlyphs.close, size: Shape.z(14), color: c),
          key: const ValueKey('home-close'),
          tip: 'Close',
          onTap: onClose,
          size: Shape.z(28),
          ink: Grey.g56,
        ),
      ],
    ),
  );
}

class _NewButton extends StatefulWidget {
  const _NewButton({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_NewButton> createState() => _NewButtonState();
}

class _NewButtonState extends State<_NewButton> {
  bool _h = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: NakedButton(
      enableFeedback: false,
      key: const ValueKey('home-new'),
      onPressed: widget.onTap,
      child: AnimatedContainer(
        duration: Motion.dur,
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(12),
          vertical: Shape.s(5),
        ),
        decoration: BoxDecoration(
          color: _h ? WindowTokens.accent : null,
          border: Border.all(color: _h ? WindowTokens.accent : Grey.g26),
          borderRadius: Shape.round(6),
        ),
        child: Text(
          '+ New',
          style: TextStyles.label(_h ? WindowTokens.onAccent : Grey.g76)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.searching});
  final bool searching;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          searching ? 'No matches' : 'No projects yet',
          style: TextStyles.title(
            Grey.g38,
          ).copyWith(fontSize: TextStyles.px(18), fontWeight: FontWeight.w300),
        ),
        SizedBox(height: Shape.s(6)),
        Text(
          searching ? 'Try a different search.' : 'Create one to get started.',
          style: TextStyles.label(Grey.g26),
        ),
      ],
    ),
  );
}
