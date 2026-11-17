// The home screen: a sidebar, a preview of the chosen project, and a bento of every project.
//
// It is drawn flat, in the manner of a design tool's concept art: solid blocks, one outline width, very large type, and
// the tool's own marks (a bounding box with handles, a tag beside a cursor, a pen path) used as the decoration.
// A collage of those marks covers the whole window; the parts above it are opaque, so it shows wherever they leave room.
import 'dart:math' as math;
import 'dart:ui' show ClipOp;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoTheme, CupertinoThemeData;
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:settings_ui/settings_ui.dart';

import 'package:motolii/skin/layer_colors.dart' show labelColor;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/theme.dart';
import 'package:motolii/workspace/commands/keymap.dart'
    show defaultKeys, keyLabel, activatorOf;
import 'package:motolii/workspace/state/window_zoom.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/window_settings.dart' show WindowFile;
import 'package:motolii/storage/disk.dart' show existsFile, imageFile;
import 'package:motolii/storage/host_platform.dart' show homeFolder;
import 'package:motolii/storage/open_in_host.dart' show pickFolder;
import 'package:motolii/storage/project_files.dart';
import 'package:motolii/storage/thumbnail_folder.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show IconPress, Pressable;
import 'package:motolii/widgets/picks.dart' show clickKeys, pickOnClick;
import 'package:motolii/workspace/dock/common/shelf_search_field.dart';
import 'package:motolii/workspace/state/project_facts.dart';
import 'package:motolii/workspace/window/home_card.dart';
import 'package:motolii/workspace/window/home_project.dart';

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

  // The project the preview shows, and the last press, to tell a second press from a first.
  String? _selected;
  String? _pressed;
  var _pressedAt = DateTime(0);

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

  /// A first press shows the project in the preview; a second one right after opens it.
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

    // The preview shows the pressed project, else the last-opened, else the first listed.
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
                painter: _Collage(
                  tones: homeTones(),
                  ink: Grey.g95,
                  ground: ground,
                  // The sidebar's title, search and list stay clear of it.
                  keep: Size(side, Shape.z(440)),
                ),
              ),
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: side,
                child: _Sidebar(
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
                    // Whole numbers, so that the opaque parts meet without a seam the collage could show through.
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
                                            ? _Empty(
                                                searching: _find.isNotEmpty,
                                              )
                                            : _Hero(
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
                                              child: _ActionCard(
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
                                                child: _ActionCard(
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
                                _GridHeader(
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
                              for (final block in _bento(
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
              child: _SettingsPopover(
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

/// Lays [cards] out as bento blocks of up to six: a tall card beside two rows of unequal ones.
///
/// Every other block is mirrored. A card fills whatever cell it gets, so its picture is cropped, not stretched.
/// Each block carries the gap below it.
List<Widget> _bento(List<Widget> cards, double rowTall, double gap) {
  Widget across(List<(int, Widget)> parts) => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, (flex, child)) in parts.indexed) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(flex: flex, child: child),
      ],
    ],
  );
  Widget down(Widget a, Widget b) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: a),
      SizedBox(height: gap),
      Expanded(child: b),
    ],
  );

  final blocks = <Widget>[];
  for (var at = 0, n = 0; at < cards.length; n++) {
    final c = cards.sublist(at, math.min(at + 6, cards.length));
    at += c.length;
    List<(int, Widget)> side(List<(int, Widget)> parts) =>
        n.isOdd ? parts.reversed.toList() : parts;
    final (rows, body) = switch (c.length) {
      1 => (1, across([(4, c[0]), (6, const SizedBox())])),
      2 => (1, across(side([(6, c[0]), (4, c[1])]))),
      3 => (2, across(side([(4, c[0]), (6, down(c[1], c[2]))]))),
      4 => (
        2,
        across(
          side([
            (3, c[0]),
            (7, down(across([(1, c[1]), (1, c[2])]), c[3])),
          ]),
        ),
      ),
      5 => (
        2,
        across(
          side([
            (3, c[0]),
            (
              7,
              down(
                across([(4, c[1]), (6, c[2])]),
                across([(6, c[3]), (4, c[4])]),
              ),
            ),
          ]),
        ),
      ),
      _ => (
        2,
        across(
          side([
            (6, c[0]),
            (
              13,
              down(
                across([(1, c[1]), (1, c[2])]),
                across([(4, c[3]), (6, c[4])]),
              ),
            ),
            (5, c[5]),
          ]),
        ),
      ),
    };
    blocks.add(
      Padding(
        padding: EdgeInsets.only(bottom: gap),
        child: SizedBox(height: rowTall * rows + gap * (rows - 1), child: body),
      ),
    );
  }
  return blocks;
}

String _folderName(String folder) {
  final home = homeFolder;
  return home != null && folder.startsWith(home)
      ? '~${folder.substring(home.length)}'
      : folder;
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.docs,
    required this.folder,
    required this.selected,
    required this.find,
    required this.onChoose,
    required this.onClose,
    required this.settings,
    required this.onSettings,
  });
  final List<HomeProject> docs;
  final String folder;
  final String? selected;
  final TextEditingController find;
  final void Function(String path) onChoose;
  final VoidCallback onClose;
  final bool settings;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final recent = [...docs]..sort((a, b) => b.changed.compareTo(a.changed));
    final bytes = docs.fold(0, (sum, d) => sum + d.bytes);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Shape.s(14),
        Shape.s(16),
        Shape.s(10),
        Shape.s(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(width: Shape.s(8)),
              Container(
                width: Shape.z(22),
                height: Shape.z(22),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WindowTokens.accent,
                  borderRadius: Shape.round(7),
                ),
                child: Text(
                  'M',
                  style: TextStyles.name(
                    WindowTokens.onAccent,
                    13,
                    FontWeight.w900,
                  ),
                ),
              ),
              SizedBox(width: Shape.s(8)),
              Text(
                'Motolii',
                style: TextStyles.name(
                  Grey.g95,
                  16,
                  FontWeight.w800,
                ).copyWith(letterSpacing: -.5),
              ),
              const Spacer(),
              IconPress(
                (c) => Glyph(AppGlyphs.tools, size: Shape.z(13), color: c),
                key: const ValueKey('home-settings'),
                tip: 'Settings',
                onTap: onSettings,
                size: Shape.z(24),
                ink: settings ? WindowTokens.accent : Grey.g56,
              ),
              SizedBox(width: Shape.s(4)),
              IconPress(
                (c) => Glyph(AppGlyphs.close, size: Shape.z(12), color: c),
                key: const ValueKey('home-close'),
                tip: 'Close',
                onTap: onClose,
                size: Shape.z(24),
                ink: Grey.g56,
              ),
            ],
          ),
          SizedBox(height: Shape.s(24)),
          SizedBox(
            height: Shape.z(28),
            child: ShelfSearchField(controller: find, hint: 'Search'),
          ),
          SizedBox(height: Shape.s(28)),
          Padding(
            padding: EdgeInsets.only(left: Shape.s(8)),
            child: Text('RECENT', style: homeCaps(Grey.g56)),
          ),
          SizedBox(height: Shape.s(8)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final d in recent.take(6))
                  _SidebarItem(
                    d: d,
                    selected: d.path == selected,
                    onTap: () => onChoose(d.path),
                  ),
              ],
            ),
          ),
          // On a solid block, so it reads over the collage.
          Container(
            padding: EdgeInsets.all(Shape.s(10)),
            decoration: BoxDecoration(
              color: Grey.g07,
              borderRadius: Shape.round(12),
            ),
            child: Row(
              children: [
                Glyph(AppGlyphs.folder, size: Shape.z(14), color: Grey.g76),
                SizedBox(width: Shape.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _folderName(folder),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.label(Grey.g91),
                      ),
                      SizedBox(height: Shape.s(4)),
                      Text(
                        '${docs.length} projects · ${homeBytes(bytes)}',
                        style: TextStyles.micro(Grey.g63),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A recent project in the sidebar. The chosen one is drawn inverted: dark words on a light block.
class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.d,
    required this.selected,
    required this.onTap,
  });
  final HomeProject d;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (context, hot) => AnimatedContainer(
      duration: Motion.dur,
      padding: EdgeInsets.all(Shape.s(8)),
      decoration: BoxDecoration(
        color: selected
            ? Grey.g20
            : hot
            ? Grey.g13
            : Grey.g00,
        borderRadius: Shape.round(10),
      ),
      child: Row(
        children: [
          Container(
            width: Shape.z(44),
            height: Shape.z(28),
            decoration: BoxDecoration(
              color: Grey.g13,
              borderRadius: Shape.round(5),
            ),
            clipBehavior: Clip.antiAlias,
            child: d.picture != null
                ? Image(image: imageFile(d.picture!), fit: BoxFit.cover)
                : null,
          ),
          SizedBox(width: Shape.s(10)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.name(
                    selected
                        ? Grey.g100
                        : hot
                        ? Grey.g95
                        : Grey.g76,
                    11,
                    selected ? FontWeight.w700 : null,
                  ),
                ),
                SizedBox(height: Shape.s(4)),
                Text(
                  homeAge(d.changed),
                  style: TextStyles.micro(selected ? Grey.g63 : Grey.g56),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The preview of the chosen project: on one side its name set very large over a strip of its facts, on the other its
/// picture, shown as a design tool shows a selected layer.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.d,
    required this.index,
    required this.note,
    required this.action,
    required this.onOpen,
  });
  final HomeProject d;
  final int index;
  final String note, action;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final f = d.facts;
    final facts = [
      ('EDITED', homeAge(d.changed)),
      if (f != null && f.seconds > 0) ('LENGTH', homeLength(f.seconds)),
      if (f != null) ('FRAME', '${f.wide}×${f.high}'),
      if (f != null && f.rate > 0)
        (
          'RATE',
          '${f.rate == f.rate.roundToDouble() ? f.rate.round() : f.rate} fps',
        ),
      ('FILE', homeBytes(d.bytes)),
    ];
    return Container(
      decoration: BoxDecoration(color: Grey.g07, borderRadius: Shape.round(20)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: homeSheen(homeTones()[index % homeTones().length]),
              padding: EdgeInsets.all(Shape.s(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  homeTag(note, WindowTokens.usuki),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        d.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.name(
                          Grey.g100,
                          34,
                          FontWeight.w800,
                        ).copyWith(letterSpacing: -1.2),
                      ),
                    ),
                  ),
                  SizedBox(height: Shape.s(16)),
                  Container(height: 1, color: Grey.g63),
                  SizedBox(height: Shape.s(10)),
                  Wrap(
                    spacing: Shape.s(22),
                    runSpacing: Shape.s(10),
                    children: [
                      for (final (label, value) in facts)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label, style: homeCaps(Grey.g56)),
                            SizedBox(height: Shape.s(5)),
                            Text(
                              value,
                              style: TextStyles.name(
                                Grey.g95,
                                12,
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  SizedBox(height: Shape.s(18)),
                  Pressable(
                    key: const ValueKey('home-hero-open'),
                    onTap: onOpen,
                    builder: (context, hot) => AnimatedContainer(
                      duration: Motion.dur,
                      padding: EdgeInsets.symmetric(
                        horizontal: Shape.s(16),
                        vertical: Shape.s(11),
                      ),
                      decoration: BoxDecoration(
                        color: hot
                            ? WindowTokens.accentHot
                            : WindowTokens.accent,
                        borderRadius: Shape.round(100),
                      ),
                      child: Text(
                        action,
                        style: homeCaps(WindowTokens.onAccent, 11),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(width: 1, color: Grey.g100.withValues(alpha: .07)),
          Expanded(
            flex: 8,
            child: d.picture == null
                ? HomeLetter(name: d.name, index: index)
                : CustomPaint(
                    painter: _DotGrid(Grey.g26),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        Shape.s(24),
                        Shape.s(20),
                        Shape.s(24),
                        Shape.s(32),
                      ),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: f != null && f.wide > 0 && f.high > 0
                              ? f.wide / f.high
                              : 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              Image(
                                image: imageFile(d.picture!),
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.medium,
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: WindowTokens.accent,
                                    width: homeEdge,
                                  ),
                                ),
                              ),
                              ...homeHandles(),
                              // The layer's size, hung under its box as a design tool hangs it.
                              if (f != null)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: -Shape.s(30),
                                  child: Center(
                                    child: homeTag(
                                      '${f.wide} × ${f.high}',
                                      WindowTokens.accent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A canvas's grid of dots.
class _DotGrid extends CustomPainter {
  _DotGrid(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = ink;
    for (var y = 12.0; y < size.height; y += 20) {
      for (var x = 12.0; x < size.width; x += 20) {
        canvas.drawRect(Rect.fromLTWH(x, y, 1.5, 1.5), dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGrid old) => old.ink != ink;
}

/// One of the two buttons beside the preview: its label at the top, its glyph large in the far corner.
///
/// [solid] draws it as a block of colour; otherwise it is an outline.
class _ActionCard extends StatelessWidget {
  const _ActionCard({
    super.key,
    required this.glyph,
    required this.label,
    required this.solid,
    required this.onTap,
  });
  final AppGlyphs glyph;
  final String label;
  final bool solid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (context, hot) {
      final tone = WindowTokens.seiji;
      final ink = solid
          ? WindowTokens.onAccent
          : hot
          ? Grey.g100
          : Grey.g91;
      return SizedBox.expand(
        child: AnimatedContainer(
          duration: Motion.dur,
          padding: EdgeInsets.all(Shape.s(16)),
          decoration: BoxDecoration(
            borderRadius: Shape.round(20),
            // A light from the top-left corner on both; the solid one keeps its colour under it.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: solid
                  ? [
                      Color.lerp(tone, Grey.g100, hot ? .38 : .2)!,
                      Color.lerp(tone, Grey.g00, hot ? 0 : .12)!,
                    ]
                  : [hot ? Grey.g20 : Grey.g13, Grey.g07],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: homeCaps(ink)),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Glyph(glyph, size: Shape.z(34), color: ink),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The heading of the bento under a heavy rule: its title set large, the count, the sort order, and what is picked.
class _GridHeader extends StatelessWidget {
  const _GridHeader({
    required this.count,
    required this.byName,
    required this.picked,
    required this.onByDate,
    required this.onByName,
    required this.onExport,
    required this.onUnpick,
  });
  final int count, picked;
  final bool byName;
  final VoidCallback onByDate, onByName, onExport, onUnpick;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(height: 1, color: Grey.g38),
      SizedBox(height: Shape.s(14)),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Projects',
            style: TextStyles.name(
              Grey.g100,
              28,
              FontWeight.w800,
            ).copyWith(letterSpacing: -1),
          ),
          SizedBox(width: Shape.s(8)),
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(5)),
            child: Text(
              '$count',
              style: TextStyles.name(Grey.g63, 14, FontWeight.w700),
            ),
          ),
          const Spacer(),
          if (picked > 0) ...[
            homeButton('home-export', 'Export $picked', true, onExport),
            homeButton('home-unpick', 'Cancel', false, onUnpick),
            SizedBox(width: Shape.s(16)),
          ],
          Padding(
            padding: EdgeInsets.only(right: Shape.s(10), bottom: Shape.s(10)),
            child: Text('SORT', style: homeCaps(Grey.g56)),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Grey.g07,
              borderRadius: Shape.round(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Toggle(
                  key: const ValueKey('home-by-date'),
                  text: 'DATE',
                  on: !byName,
                  onTap: onByDate,
                ),
                _Toggle(
                  key: const ValueKey('home-by-name'),
                  text: 'NAME',
                  on: byName,
                  onTap: onByName,
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}

/// One of a row of choices: a pill, inverted when it is the chosen one.
class _Toggle extends StatelessWidget {
  const _Toggle({
    super.key,
    required this.text,
    required this.on,
    required this.onTap,
  });
  final String text;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    builder: (context, hot) => Container(
      padding: EdgeInsets.symmetric(
        horizontal: Shape.s(10),
        vertical: Shape.s(6),
      ),
      decoration: BoxDecoration(
        color: on
            ? Grey.g95
            : hot
            ? Grey.g20
            : Grey.g07,
        borderRadius: Shape.round(100),
      ),
      child: Text(text, style: homeCaps(on ? Grey.g00 : Grey.g76)),
    ),
  );
}

enum _SettingsPage {
  appearance,
  skin,
  display,
  autoSave,
  playback,
  audio,
  performance,
  rendering,
  timeline,
  keyboard,
  labels,
  canvas,
  scripting,
  projectDefaults,
  storage;

  String get label => switch (this) {
    appearance => 'Appearance',
    skin => 'Skin',
    display => 'Display',
    autoSave => 'Auto Save',
    playback => 'Playback',
    audio => 'Audio',
    performance => 'Performance',
    rendering => 'Export',
    timeline => 'Timeline',
    keyboard => 'Keyboard',
    labels => 'Labels',
    canvas => 'Canvas',
    scripting => 'Scripting',
    projectDefaults => 'Project Defaults',
    storage => 'Storage',
  };
}

class _SettingsPopover extends StatefulWidget {
  const _SettingsPopover({
    required this.folder,
    required this.onFolder,
    required this.onSkin,
  });
  final String folder;
  final VoidCallback? onFolder;
  final void Function(String?) onSkin;

  @override
  State<_SettingsPopover> createState() => _SettingsPopoverState();
}

class _SettingsPopoverState extends State<_SettingsPopover> {
  _SettingsPage _page = _SettingsPage.appearance;

  @override
  Widget build(BuildContext context) {
    final dark = !Grey.light;

    final theme = SettingsThemeData(
      settingsListBackground: Grey.g00.withValues(alpha: 0),
      settingsSectionBackground: dark ? Grey.g20 : Grey.g95,
      titleTextColor: Grey.g56,
      settingsTileTextColor: dark ? Grey.g91 : Grey.g13,
      tileDescriptionTextColor: Grey.g56,
      dividerColor: dark ? Grey.g26 : Grey.g91,
      leadingIconsColor: Grey.g56,
      trailingTextColor: Grey.g56,
      tileHighlightColor: dark ? Grey.g26 : Grey.g91,
      titleTextStyle: homeCaps(Grey.g56),
    );

    return Container(
      width: Shape.z(620),
      height: Shape.z(480),
      decoration: BoxDecoration(
        color: dark ? Grey.g13 : Grey.g100,
        borderRadius: Shape.round(14),
        border: Border.all(color: Grey.g26, width: 1),
        boxShadow: [
          BoxShadow(
            color: Grey.g00.withValues(alpha: .4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: Shape.round(14),
        child: mui.Theme(
          data: dark ? mui.ThemeData.dark() : mui.ThemeData.light(),
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: dark ? Brightness.dark : Brightness.light,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Left nav ──
                Container(
                  width: Shape.z(160),
                  decoration: BoxDecoration(
                    color: dark ? Grey.g10 : Grey.g95,
                    border: Border(
                      right: BorderSide(color: dark ? Grey.g26 : Grey.g91),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          Shape.s(14),
                          Shape.s(16),
                          Shape.s(14),
                          Shape.s(8),
                        ),
                        child: Text('SETTINGS', style: homeCaps(Grey.g44, 9)),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
                          children: [
                            for (final p in _SettingsPage.values)
                              _navItem(p, dark),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(Shape.s(12)),
                        child: Text(
                          'Motolii v0.1.0',
                          style: TextStyles.micro(Grey.g44),
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Right content ──
                Expanded(
                  child: SettingsList(
                    platform: DevicePlatform.macOS,
                    brightness: dark ? Brightness.dark : Brightness.light,
                    applicationType: ApplicationType.material,
                    contentPadding: EdgeInsets.all(Shape.s(10)),
                    darkTheme: theme,
                    lightTheme: theme,
                    sections: _buildSections(dark),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(_SettingsPage p, bool dark) {
    final on = _page == p;
    return Pressable(
      key: ValueKey('settings-nav-${p.name}'),
      onTap: () => setState(() => _page = p),
      builder: (context, hot) => AnimatedContainer(
        duration: Motion.dur,
        curve: Motion.ease,
        margin: EdgeInsets.only(bottom: Shape.s(2)),
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(10),
          vertical: Shape.s(8),
        ),
        decoration: BoxDecoration(
          color: on
              ? WindowTokens.accent
              : hot
              ? (dark ? Grey.g20 : Grey.g91)
              : Grey.g00.withValues(alpha: 0),
          borderRadius: Shape.round(8),
        ),
        child: Text(
          p.label,
          style: TextStyles.name(
            on
                ? WindowTokens.onAccent
                : hot
                ? (dark ? Grey.g91 : Grey.g13)
                : (dark ? Grey.g76 : Grey.g26),
            12,
            on ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<AbstractSettingsSection> _buildSections(bool dark) => switch (_page) {
    _SettingsPage.appearance => [
      SettingsSection(
        title: Text('APPEARANCE'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Dark Mode'),
            initialValue: !Grey.light,
            activeSwitchColor: WindowTokens.accent,
            onToggle: (value) {
              Grey.shade.value = value ? Shade.dark : Shade.light;
              WidgetsBinding.instance.reassembleApplication();
            },
          ),
        ],
      ),
    ],
    _SettingsPage.skin => [
      SettingsSection(
        title: Text('SKIN'),
        tiles: [
          SettingsTile(
            title: const Text('Default'),
            trailing: ColorTheme.skin == null
                ? Glyph(
                    AppGlyphs.check,
                    size: Shape.z(14),
                    color: WindowTokens.accent,
                  )
                : null,
            onPressed: (_) => widget.onSkin(null),
          ),
          for (final s in ColorTheme.skinNames())
            SettingsTile(
              title: Text(s),
              trailing: ColorTheme.skin == s
                  ? Glyph(
                      AppGlyphs.check,
                      size: Shape.z(14),
                      color: WindowTokens.accent,
                    )
                  : null,
              onPressed: (_) => widget.onSkin(s),
            ),
        ],
      ),
    ],
    _SettingsPage.display => [
      SettingsSection(
        title: Text('DISPLAY'),
        tiles: [
          CustomSettingsTile(
            child: ValueListenableBuilder<double>(
              valueListenable: WindowZoom.value,
              builder: (context, zoom, _) => Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Shape.s(10),
                  vertical: Shape.s(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'UI Zoom',
                      style: TextStyles.name(
                        dark ? Grey.g91 : Grey.g13,
                        13,
                        FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(zoom * 100).round()}%',
                      style: TextStyles.label(Grey.g56),
                    ),
                    SizedBox(width: Shape.s(10)),
                    Pressable(
                      key: const ValueKey('settings-zoom-down'),
                      onTap: () => WindowZoom.set(zoom - .01),
                      builder: (context, hot) => Text(
                        '−',
                        style: TextStyles.name(
                          hot ? Grey.g100 : Grey.g56,
                          14,
                          FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: Shape.s(6)),
                    Pressable(
                      key: const ValueKey('settings-zoom-up'),
                      onTap: () => WindowZoom.set(zoom + .01),
                      builder: (context, hot) => Text(
                        '+',
                        style: TextStyles.name(
                          hot ? Grey.g100 : Grey.g56,
                          14,
                          FontWeight.w700,
                        ),
                      ),
                    ),
                    SizedBox(width: Shape.s(8)),
                    Pressable(
                      key: const ValueKey('settings-zoom-reset'),
                      onTap: () => WindowZoom.set(WindowZoom.usual),
                      builder: (context, hot) => Text(
                        'RESET',
                        style: homeCaps(hot ? Grey.g100 : WindowTokens.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
    _SettingsPage.autoSave => [
      SettingsSection(
        title: Text('AUTO SAVE'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Enable Auto Save'),
            initialValue: (WindowFile.get('AutoSave') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) => setState(() => WindowFile.set('AutoSave', '$v')),
          ),
          SettingsTile(
            title: const Text('Interval'),
            trailing: Text(
              '${WindowFile.get('AutoSaveInterval') ?? '5'} min',
              style: TextStyles.label(Grey.g56),
            ),
            onPressed: (_) {
              const steps = ['1', '2', '5', '10', '15', '30'];
              final now = WindowFile.get('AutoSaveInterval') ?? '5';
              final i = (steps.indexOf(now) + 1) % steps.length;
              setState(() => WindowFile.set('AutoSaveInterval', steps[i]));
            },
          ),
          SettingsTile(
            title: const Text('Max Backups'),
            trailing: Text(
              WindowFile.get('AutoSaveBackups') ?? '3',
              style: TextStyles.label(Grey.g56),
            ),
            onPressed: (_) {
              const steps = ['1', '3', '5', '10'];
              final now = WindowFile.get('AutoSaveBackups') ?? '3';
              final i = (steps.indexOf(now) + 1) % steps.length;
              setState(() => WindowFile.set('AutoSaveBackups', steps[i]));
            },
          ),
        ],
      ),
    ],
    _SettingsPage.playback => [
      SettingsSection(
        title: Text('PLAYBACK'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Loop Playback'),
            initialValue: (WindowFile.get('PlaybackLoop') ?? 'false') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) =>
                setState(() => WindowFile.set('PlaybackLoop', '$v')),
          ),
          SettingsTile.switchTile(
            title: const Text('Audio During Scrub'),
            initialValue: (WindowFile.get('AudioScrub') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) => setState(() => WindowFile.set('AudioScrub', '$v')),
          ),
          SettingsTile(
            title: const Text('Preview Quality'),
            trailing: Text(switch (WindowFile.get('PreviewQuality')) {
              'half' => 'Half',
              'quarter' => 'Quarter',
              _ => 'Full',
            }, style: TextStyles.label(Grey.g56)),
            onPressed: (_) {
              final next = switch (WindowFile.get('PreviewQuality')) {
                'full' || null => 'half',
                'half' => 'quarter',
                _ => 'full',
              };
              setState(() => WindowFile.set('PreviewQuality', next));
            },
          ),
        ],
      ),
    ],
    _SettingsPage.audio => [
      SettingsSection(
        title: Text('AUDIO'),
        tiles: [
          SettingsTile(
            title: const Text('Sample Rate'),
            trailing: Text(
              '${WindowFile.get('SampleRate') ?? '44100'} Hz',
              style: TextStyles.label(Grey.g56),
            ),
            onPressed: (_) {
              final next = switch (WindowFile.get('SampleRate')) {
                '44100' || null => '48000',
                '48000' => '96000',
                _ => '44100',
              };
              setState(() => WindowFile.set('SampleRate', next));
            },
          ),
          SettingsTile(
            title: const Text('Audio Device'),
            value: const Text('System default'),
            enabled: false,
          ),
        ],
      ),
    ],
    _SettingsPage.performance => [
      SettingsSection(
        title: Text('PERFORMANCE'),
        tiles: [
          SettingsTile(
            title: const Text('Cache Size Limit'),
            trailing: Text(
              '${WindowFile.get('CacheSize') ?? '10'} GB',
              style: TextStyles.label(Grey.g56),
            ),
            onPressed: (_) {
              const steps = ['2', '5', '10', '20', '50'];
              final now = WindowFile.get('CacheSize') ?? '10';
              final i = (steps.indexOf(now) + 1) % steps.length;
              setState(() => WindowFile.set('CacheSize', steps[i]));
            },
          ),
          SettingsTile.switchTile(
            title: const Text('GPU Acceleration'),
            initialValue: (WindowFile.get('GpuAccel') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) => setState(() => WindowFile.set('GpuAccel', '$v')),
          ),
        ],
      ),
    ],
    _SettingsPage.rendering => [
      SettingsSection(
        title: Text('EXPORT'),
        tiles: [
          SettingsTile(
            title: const Text('Default Format'),
            trailing: Text(switch (WindowFile.get('ExportFormat')) {
              'mov' => '.mov',
              'gif' => '.gif',
              'png' => '.png',
              _ => '.mp4',
            }, style: TextStyles.label(Grey.g56)),
            onPressed: (_) {
              final next = switch (WindowFile.get('ExportFormat')) {
                'mp4' || null => 'mov',
                'mov' => 'gif',
                'gif' => 'png',
                _ => 'mp4',
              };
              setState(() => WindowFile.set('ExportFormat', next));
            },
          ),
          SettingsTile(
            title: const Text('Output Folder'),
            value: Text(
              _folderName(WindowFile.get('ExportFolder') ?? '~/Movies'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: (_) async {
              final f = await pickFolder(prompt: 'Choose export folder');
              if (f != null && mounted) {
                setState(() => WindowFile.set('ExportFolder', f));
              }
            },
          ),
        ],
      ),
    ],
    _SettingsPage.timeline => [
      SettingsSection(
        title: Text('TIMELINE'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Snap to Grid'),
            description: const Text('Hold ⌘ to snap freely'),
            initialValue: (WindowFile.get('SnapTimeline') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) =>
                setState(() => WindowFile.set('SnapTimeline', '$v')),
          ),
          SettingsTile.switchTile(
            title: const Text('Follow Playhead'),
            initialValue:
                (WindowFile.get('FollowPlayhead') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) =>
                setState(() => WindowFile.set('FollowPlayhead', '$v')),
          ),
        ],
      ),
    ],
    _SettingsPage.keyboard => [
      SettingsSection(
        title: Text('KEYBOARD SHORTCUTS'),
        tiles: [
          for (final (key, cmd) in defaultKeys)
            SettingsTile(
              title: Text(cmd),
              trailing: Text(
                keyLabel(activatorOf(key)),
                style: TextStyles.label(Grey.g56),
              ),
            ),
        ],
      ),
      SettingsSection(
        title: Text('CUSTOMISE'),
        tiles: [
          SettingsTile(
            title: const Text('Keybindings File'),
            value: const Text('~/.motolii/keybindings.json'),
          ),
        ],
      ),
    ],
    _SettingsPage.labels => [
      SettingsSection(
        title: Text('LABEL COLOURS'),
        tiles: [
          CustomSettingsTile(
            child: Padding(
              padding: EdgeInsets.all(Shape.s(10)),
              child: Wrap(
                spacing: Shape.s(8),
                runSpacing: Shape.s(8),
                children: [
                  for (var k = 0; k < 16; k++)
                    Container(
                      width: Shape.z(28),
                      height: Shape.z(28),
                      decoration: BoxDecoration(
                        color: labelColor(k),
                        borderRadius: Shape.round(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${k + 1}',
                        style: TextStyles.micro(Grey.g00),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SettingsTile(
            title: const Text('Override'),
            value: const Text('Skins can set Label1–Label16'),
            enabled: false,
          ),
        ],
      ),
    ],
    _SettingsPage.canvas => [
      SettingsSection(
        title: Text('CANVAS'),
        tiles: [
          SettingsTile.switchTile(
            title: const Text('Show Grid'),
            initialValue: (WindowFile.get('ShowGrid') ?? 'false') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) => setState(() => WindowFile.set('ShowGrid', '$v')),
          ),
          SettingsTile.switchTile(
            title: const Text('Show Safe Area'),
            initialValue: (WindowFile.get('ShowSafe') ?? 'false') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) => setState(() => WindowFile.set('ShowSafe', '$v')),
          ),
          SettingsTile.switchTile(
            title: const Text('Snap to Objects'),
            initialValue: (WindowFile.get('SnapStage') ?? 'true') == 'true',
            activeSwitchColor: WindowTokens.accent,
            onToggle: (v) => setState(() => WindowFile.set('SnapStage', '$v')),
          ),
        ],
      ),
    ],
    _SettingsPage.scripting => [
      SettingsSection(
        title: Text('EXPRESSION ENGINES'),
        tiles: [
          SettingsTile(
            title: const Text('QuickJS'),
            value: const Text('JavaScript expressions'),
            enabled: false,
          ),
          SettingsTile(
            title: const Text('Lua'),
            value: const Text('Lua scripting'),
            enabled: false,
          ),
          SettingsTile(
            title: const Text('Lottie Expressions'),
            value: const Text('After Effects expression subset'),
            enabled: false,
          ),
        ],
      ),
    ],
    _SettingsPage.projectDefaults => [
      SettingsSection(
        title: Text('NEW PROJECT DEFAULTS'),
        tiles: [
          SettingsTile(
            title: const Text('Frame Size'),
            trailing: Text(
              '${WindowFile.get('DefaultWidth') ?? '1920'} × '
              '${WindowFile.get('DefaultHeight') ?? '1080'}',
              style: TextStyles.label(Grey.g56),
            ),
            onPressed: (_) {
              const sizes = [
                ('1920', '1080'),
                ('3840', '2160'),
                ('1280', '720'),
                ('1080', '1080'),
                ('1080', '1920'),
              ];
              final w = WindowFile.get('DefaultWidth') ?? '1920';
              final h = WindowFile.get('DefaultHeight') ?? '1080';
              var i = sizes.indexWhere((s) => s.$1 == w && s.$2 == h);
              i = (i + 1) % sizes.length;
              setState(() {
                WindowFile.set('DefaultWidth', sizes[i].$1);
                WindowFile.set('DefaultHeight', sizes[i].$2);
              });
            },
          ),
          SettingsTile(
            title: const Text('Frame Rate'),
            trailing: Text(
              '${WindowFile.get('DefaultFrameRate') ?? '30'} fps',
              style: TextStyles.label(Grey.g56),
            ),
            onPressed: (_) {
              const steps = ['24', '25', '30', '50', '60'];
              final now = WindowFile.get('DefaultFrameRate') ?? '30';
              final i = (steps.indexOf(now) + 1) % steps.length;
              setState(() => WindowFile.set('DefaultFrameRate', steps[i]));
            },
          ),
          SettingsTile(
            title: const Text('Duration'),
            trailing: Text(
              '${WindowFile.get('DefaultDuration') ?? '240'} frames',
              style: TextStyles.label(Grey.g56),
            ),
            onPressed: (_) {
              const steps = ['60', '120', '240', '300', '600', '900'];
              final now = WindowFile.get('DefaultDuration') ?? '240';
              final i = (steps.indexOf(now) + 1) % steps.length;
              setState(() => WindowFile.set('DefaultDuration', steps[i]));
            },
          ),
        ],
      ),
    ],
    _SettingsPage.storage => [
      SettingsSection(
        title: Text('STORAGE'),
        tiles: [
          SettingsTile(
            leading: Glyph(
              AppGlyphs.folder,
              size: Shape.z(16),
              color: Grey.g56,
            ),
            title: const Text('Projects Folder'),
            value: Text(
              _folderName(widget.folder),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onPressed: widget.onFolder != null
                ? (_) => widget.onFolder!()
                : null,
          ),
        ],
      ),
    ],
  };
}

/// The collage behind the whole home screen: the marks of a design tool and of this app, many of them, at every size
/// and a little askew, each overlapping its neighbours, under a shade that keeps it in the background.
///
/// Rows are counted from the foot of the window and columns from its left, and each place draws from its own seed, so
/// a mark stays where it is when the window is resized.
class _Collage extends CustomPainter {
  _Collage({
    required this.tones,
    required this.ink,
    required this.ground,
    required this.keep,
  });

  /// The colours of [homeTones].
  final List<Color> tones;
  final Color ink, ground;

  /// The top-left corner of the window that is left empty.
  final Size keep;

  static const _wide = 112.0, _tall = 98.0;
  static const _words = [
    '⌘V',
    'PASTE',
    'RENDER',
    '.wgsl',
    'p5.js',
    '60 FPS',
    'GLSL',
    '.fs',
    'EASE',
    'LOTTIE',
    'KEYFRAME',
    'SHADER',
  ];
  static const _letters = ['Ag', '{ }', 'fx', 'Mo', '&', '</>', '01'];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.clipRect(Offset.zero & keep, clipOp: ClipOp.difference);
    final cols = (size.width / _wide).ceil() + 1,
        rows = (size.height / _tall).ceil() + 1;
    // From the top row down, so that a lower mark lies over the one above it.
    for (var row = rows - 1; row >= 0; row--) {
      for (var col = 0; col < cols; col++) {
        final r = math.Random(row * 7919 + col * 104729 + 5);
        final x =
            (col + (row.isOdd ? .5 : 0) + (r.nextDouble() - .5) * .7) * _wide;
        final y = size.height - (row + .3 + (r.nextDouble() - .5) * .7) * _tall;
        final turn = r.nextInt(3) == 0 ? 0.0 : (r.nextDouble() - .5) * .8;
        final grow = r.nextInt(8) == 0 ? 2.2 : .72 + r.nextDouble() * .8;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(turn);
        canvas.scale(grow);
        _mark(canvas, r);
        canvas.restore();
      }
    }

    // A haze of colour quiets it, in place of a black shade: indigo where the marks begin, turning teal toward the foot
    // of the window. Above that it is the ground's own colour, so nothing shows in the upper part of the window.
    final dim = Color.lerp(tones[2], ground, .82)!;
    final all = Offset.zero & size;
    final from = (keep.height / size.height).clamp(0.0, .8);
    canvas.drawRect(
      all,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ground,
            dim.withValues(alpha: .88),
            dim.withValues(alpha: .5),
          ],
          stops: [from, from + (1 - from) * .45, 1],
        ).createShader(all),
    );
  }

  /// Draws one mark about the origin, roughly a hundred across.
  void _mark(Canvas c, math.Random r) {
    final tone = tones[r.nextInt(tones.length)];
    final fill = Paint()..color = tone;
    final blank = Paint()..color = ground;
    // The line that cuts a solid shape out of whatever lies under it.
    final edge = Paint()
      ..color = ground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    void solid(Path p) {
      c.drawPath(p, fill);
      c.drawPath(p, edge);
    }

    void handle(Offset at) {
      final box = Rect.fromCenter(center: at, width: 7, height: 7);
      c.drawRect(box, blank);
      c.drawRect(box, line);
    }

    void knob(Offset at) {
      c.drawCircle(at, 3.5, blank);
      c.drawCircle(at, 3.5, line);
    }

    void key(double x, bool full) {
      final p = Path()
        ..moveTo(x, -8)
        ..lineTo(x + 8, 0)
        ..lineTo(x, 8)
        ..lineTo(x - 8, 0)
        ..close();
      c.drawPath(p, full ? fill : blank);
      if (!full) c.drawPath(p, line);
    }

    void word(String s, double size, {Color? color, Paint? outline}) {
      final t = lineText(
        s,
        TextStyle(
          fontFamily: TextStyles.sans,
          fontSize: size,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: outline == null ? 1 : -2,
          color: color,
          foreground: outline,
        ),
      );
      t.paint(c, Offset(-t.width / 2, -t.height / 2));
      t.dispose();
    }

    switch (r.nextInt(19)) {
      // A layer in its bounding box.
      case 0:
        final box = Rect.fromCenter(
          center: Offset.zero,
          width: 104,
          height: 66,
        );
        c.drawRect(box, fill);
        c.drawRect(box, line);
        for (final p in [
          box.topLeft,
          box.topRight,
          box.bottomLeft,
          box.bottomRight,
        ]) {
          handle(p);
        }
      // A burst.
      case 1:
        final p = Path();
        for (var i = 0; i < 18; i++) {
          final a = i * math.pi / 9 - math.pi / 2;
          final o = Offset(math.cos(a), math.sin(a)) * (i.isEven ? 50.0 : 37.0);
          i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
        }
        solid(p..close());
      // A stack of discs.
      case 2:
        for (var i = 0; i < 4; i++) {
          final at = Offset(-20.0 + i * 13, -5.0 + i * 3);
          c.drawCircle(at, 34, fill);
          c.drawCircle(at, 34, edge);
        }
      // A triangle.
      case 3:
        solid(
          Path()
            ..moveTo(-46, 40)
            ..lineTo(46, 40)
            ..lineTo(0, -48)
            ..close(),
        );
      // A pen path: two anchors, and the handles that bend the line between them.
      case 4:
        const from = Offset(-56, 34), to = Offset(56, -30);
        const fromPull = Offset(-18, -40), toPull = Offset(6, 22);
        c.drawLine(from, fromPull, line);
        c.drawLine(to, toPull, line);
        c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..cubicTo(
              fromPull.dx,
              fromPull.dy,
              toPull.dx,
              toPull.dy,
              to.dx,
              to.dy,
            ),
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6,
        );
        knob(fromPull);
        knob(toPull);
        handle(from);
        handle(to);
      // A row of keyframes.
      case 5:
        c.drawLine(const Offset(-62, 0), const Offset(62, 0), line);
        key(-52, true);
        key(-14, false);
        key(22, true);
        key(54, false);
      // Two clips on a timeline, and the playhead across them.
      case 6:
        c.drawRect(const Rect.fromLTWH(-54, -26, 84, 15), fill);
        c.drawRect(const Rect.fromLTWH(-12, -5, 66, 15), blank);
        c.drawRect(const Rect.fromLTWH(-12, -5, 66, 15), line);
        c.drawLine(const Offset(8, -40), const Offset(8, 30), line);
        c.drawRect(const Rect.fromLTWH(3, -46, 10, 8), Paint()..color = ink);
      // Someone else's cursor, with the block that carries their name.
      case 7:
        final p = Path()
          ..moveTo(-30, -30)
          ..lineTo(-30, 2)
          ..lineTo(-21, -6)
          ..lineTo(-8, -6)
          ..close();
        solid(p);
        c.drawRect(const Rect.fromLTWH(-12, 2, 58, 20), fill);
      // A ring.
      case 8:
        c.drawCircle(
          Offset.zero,
          36,
          Paint()
            ..color = tone
            ..style = PaintingStyle.stroke
            ..strokeWidth = 14,
        );
      // Half a disc.
      case 9:
        solid(
          Path()
            ..addArc(
              Rect.fromCircle(center: Offset.zero, radius: 48),
              math.pi,
              math.pi,
            )
            ..close(),
        );
      // A button, outlined.
      case 10:
        final pill = RRect.fromRectAndRadius(
          const Rect.fromLTWH(-56, -16, 112, 32),
          const Radius.circular(16),
        );
        c.drawRRect(pill, blank);
        c.drawRRect(pill, line);
        word(_words[r.nextInt(_words.length)], 12, color: ink);
      // A button, filled.
      case 11:
        final block = const Rect.fromLTWH(-52, -15, 104, 30);
        c.drawRect(block, fill);
        c.drawRect(block, edge);
        word(_words[r.nextInt(_words.length)], 12, color: ground);
      // A grid of dots.
      case 12:
        for (var i = 0; i < 25; i++) {
          c.drawCircle(
            Offset(-40.0 + (i % 5) * 20, -40.0 + (i ~/ 5) * 20),
            2.6,
            Paint()..color = ink,
          );
        }
      // A cross.
      case 13:
        solid(
          Path()
            ..moveTo(-12, -40)
            ..lineTo(12, -40)
            ..lineTo(12, -12)
            ..lineTo(40, -12)
            ..lineTo(40, 12)
            ..lineTo(12, 12)
            ..lineTo(12, 40)
            ..lineTo(-12, 40)
            ..lineTo(-12, 12)
            ..lineTo(-40, 12)
            ..lineTo(-40, -12)
            ..lineTo(-12, -12)
            ..close(),
        );
      // A zigzag.
      case 14:
        final p = Path()..moveTo(-54, 14);
        for (var i = 1; i <= 6; i++) {
          p.lineTo(-54.0 + i * 18, i.isOdd ? -14.0 : 14.0);
        }
        c.drawPath(
          p,
          Paint()
            ..color = tone
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8,
        );
      // A window, with something in it.
      case 15:
        const frame = Rect.fromLTWH(-52, -38, 104, 76);
        c.drawRect(frame, blank);
        c.drawRect(frame, line);
        c.drawLine(const Offset(-52, -22), const Offset(52, -22), line);
        for (var i = 0; i < 3; i++) {
          c.drawCircle(Offset(-43.0 + i * 9, -30), 2.4, Paint()..color = ink);
        }
        c.drawRect(const Rect.fromLTWH(-40, -10, 50, 34), fill);
      // Type in outline.
      case 16 || 17:
        word(
          _letters[r.nextInt(_letters.length)],
          92,
          outline: Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      // A quarter of a disc.
      default:
        solid(
          Path()
            ..moveTo(-40, 40)
            ..lineTo(-40, -40)
            ..arcToPoint(
              const Offset(40, 40),
              radius: const Radius.circular(80),
            )
            ..close(),
        );
    }
  }

  @override
  bool shouldRepaint(_Collage old) =>
      !listEquals(old.tones, tones) ||
      old.ink != ink ||
      old.ground != ground ||
      old.keep != keep;
}

/// Shown in the preview's place when there is no project to preview.
class _Empty extends StatelessWidget {
  const _Empty({required this.searching});
  final bool searching;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Shape.s(24)),
    decoration: BoxDecoration(color: Grey.g07, borderRadius: Shape.round(20)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          searching ? 'No matches' : 'No projects yet',
          style: TextStyles.name(
            Grey.g100,
            34,
            FontWeight.w800,
          ).copyWith(letterSpacing: -1.2),
        ),
        SizedBox(height: Shape.s(14)),
        Text(
          searching ? 'Try a different search.' : 'Create one to get started.',
          style: TextStyles.label(Grey.g76),
        ),
      ],
    ),
  );
}
