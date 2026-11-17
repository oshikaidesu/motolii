// The home screen: a sidebar, a preview of the chosen project, and a bento of every project.
//
// It is drawn flat, in the manner of a design tool's concept art: solid blocks, one outline width, very large type, and
// the tool's own marks (a bounding box with handles, a tag beside a cursor, a pen path) used as the decoration.
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
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

    return ColoredBox(
      key: const ValueKey('ws-home'),
      color: Grey.g07,
      child: Row(
        children: [
          SizedBox(
            width: Shape.z(232),
            child: _Sidebar(
              docs: _docs,
              folder: widget.folder,
              selected: hero?.path,
              find: _findText,
              onChoose: _choose,
              onClose: widget.onClose,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                const _Decorations(),
                LayoutBuilder(
                  builder: (context, box) {
                    final pad = Shape.s(24), gap = Shape.s(12);
                    // The cards keep room on every side for the chosen one's handles.
                    final sides = EdgeInsets.only(left: homeReach, right: pad);
                    final heroTall = (box.maxHeight * .38).clamp(264.0, 400.0);
                    final rowTall = ((box.maxWidth - pad) * .15).clamp(
                      110.0,
                      190.0,
                    );
                    return Padding(
                      padding: EdgeInsets.only(top: pad),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: sides,
                            child: SizedBox(
                              height: heroTall,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: hero == null
                                        ? _Empty(searching: _find.isNotEmpty)
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
                                    width: Shape.z(200),
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
                          ),
                          SizedBox(height: Shape.s(28)),
                          Padding(
                            padding: sides,
                            child: _GridHeader(
                              count: shown.length,
                              byName: byName,
                              picked: _picked.length,
                              onByDate: () => setState(() => byName = false),
                              onByName: () => setState(() => byName = true),
                              onExport: () => widget.onExport([..._picked]),
                              onUnpick: () => setState(_picked.clear),
                            ),
                          ),
                          SizedBox(height: Shape.s(10)),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.fromLTRB(
                                homeReach,
                                homeReach,
                                pad,
                                Shape.s(24),
                              ),
                              children: _bento(
                                [
                                  for (final (i, d) in shown.indexed)
                                    card(d, i),
                                ],
                                rowTall,
                                gap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lays [cards] out as bento blocks of up to six: a tall card beside two rows of unequal ones.
///
/// Every other block is mirrored. A card fills whatever cell it gets, so its picture is cropped, not stretched.
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
  });
  final List<HomeProject> docs;
  final String folder;
  final String? selected;
  final TextEditingController find;
  final void Function(String path) onChoose;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final recent = [...docs]..sort((a, b) => b.changed.compareTo(a.changed));
    final bytes = docs.fold(0, (sum, d) => sum + d.bytes);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        Shape.s(16),
        Shape.s(24),
        Shape.s(16) - homeReach,
        Shape.s(20),
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
                color: WindowTokens.accent,
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
          Padding(
            padding: EdgeInsets.only(left: Shape.s(8)),
            child: Row(
              children: [
                Glyph(AppGlyphs.folder, size: Shape.z(14), color: Grey.g56),
                SizedBox(width: Shape.s(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _folderName(folder),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.label(Grey.g76),
                      ),
                      SizedBox(height: Shape.s(4)),
                      Text(
                        '${docs.length} projects · ${homeBytes(bytes)}',
                        style: TextStyles.micro(Grey.g56),
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
            ? Grey.g91
            : hot
            ? Grey.g13
            : Grey.g07,
        borderRadius: Shape.round(3),
      ),
      child: Row(
        children: [
          Container(
            width: Shape.z(44),
            height: Shape.z(28),
            color: Grey.g13,
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
                        ? Grey.g07
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
                  style: TextStyles.micro(selected ? Grey.g20 : Grey.g56),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// The preview of the chosen project: its name set very large on one side, its picture on the other.
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
    return Container(
      decoration: BoxDecoration(
        color: Grey.g10,
        borderRadius: Shape.round(4),
        border: Border.all(color: Grey.g26, width: homeEdge),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: EdgeInsets.all(Shape.s(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  homeTag(note, WindowTokens.usuki),
                  const Spacer(),
                  Text(
                    d.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.name(
                      Grey.g100,
                      46,
                      FontWeight.w800,
                    ).copyWith(letterSpacing: -1.8),
                  ),
                  SizedBox(height: Shape.s(14)),
                  Text(
                    [
                      homeAge(d.changed),
                      if (f != null && f.seconds > 0) homeLength(f.seconds),
                      ...homeFacts(d),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.label(Grey.g76),
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
                      color: hot ? WindowTokens.accentHot : WindowTokens.accent,
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
          Container(width: homeEdge, color: Grey.g26),
          Expanded(
            flex: 8,
            child: d.picture != null
                ? Image(
                    image: imageFile(d.picture!),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  )
                : HomeLetter(name: d.name, index: index),
          ),
        ],
      ),
    );
  }
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
          ? Grey.g95
          : Grey.g76;
      return SizedBox.expand(
        child: AnimatedContainer(
          duration: Motion.dur,
          padding: EdgeInsets.all(Shape.s(16)),
          decoration: BoxDecoration(
            color: solid
                ? (hot ? Color.lerp(tone, Grey.g100, .16) : tone)
                : (hot ? Grey.g13 : Grey.g10),
            borderRadius: Shape.round(4),
            border: Border.all(
              width: homeEdge,
              color: solid
                  ? tone
                  : hot
                  ? Grey.g63
                  : Grey.g26,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(label, style: homeCaps(ink)),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Glyph(glyph, size: Shape.z(30), color: ink),
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
      Container(height: 2, color: Grey.g91),
      SizedBox(height: Shape.s(14)),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Projects',
            style: TextStyles.name(
              Grey.g100,
              36,
              FontWeight.w800,
            ).copyWith(letterSpacing: -1.4),
          ),
          SizedBox(width: Shape.s(8)),
          Padding(
            padding: EdgeInsets.only(bottom: Shape.s(4)),
            child: Text(
              '$count',
              style: TextStyles.name(Grey.g63, 13, FontWeight.w700),
            ),
          ),
          const Spacer(),
          if (picked > 0) ...[
            homeButton('home-export', 'Export $picked', true, onExport),
            homeButton('home-unpick', 'Cancel', false, onUnpick),
            SizedBox(width: Shape.s(12)),
          ],
          homeButton('home-by-date', 'Date', !byName, onByDate),
          homeButton('home-by-name', 'Name', byName, onByName),
        ],
      ),
    ],
  );
}

/// The marks of a design tool and of this app, drawn flat along the foot of the window behind the bento:
/// a layer in its bounding box, a burst, a pen path, a triangle, a timeline with its keyframes, and a stack of discs.
class _Decorations extends StatelessWidget {
  const _Decorations();
  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: CustomPaint(
      painter: _DecorationPainter(
        tones: homeTones(),
        ink: Grey.g91,
        ground: Grey.g07,
      ),
    ),
  );
}

class _DecorationPainter extends CustomPainter {
  _DecorationPainter({
    required this.tones,
    required this.ink,
    required this.ground,
  });

  /// The colours of [homeTones], in its order.
  final List<Color> tones;
  final Color ink, ground;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final [usuki, nadeshiko, seiji, orange, violet] = tones;
    canvas.clipRect(Offset.zero & size);

    Paint solid(Color c) => Paint()..color = c;
    Paint stroke(Color c, [double wide = homeEdge]) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = wide;

    // A bounding box's square handle, and a pen handle's round one.
    void handle(Offset at) {
      final r = Rect.fromCenter(center: at, width: 8, height: 8);
      canvas.drawRect(r, solid(ground));
      canvas.drawRect(r, stroke(ink));
    }

    void knob(Offset at) {
      canvas.drawCircle(at, 4, solid(ground));
      canvas.drawCircle(at, 4, stroke(ink));
    }

    // A keyframe: filled when [fill] is given, hollow otherwise.
    void key(Offset at, [Color? fill]) {
      const r = 8.0;
      final p = Path()
        ..moveTo(at.dx, at.dy - r)
        ..lineTo(at.dx + r, at.dy)
        ..lineTo(at.dx, at.dy + r)
        ..lineTo(at.dx - r, at.dy)
        ..close();
      canvas.drawPath(p, solid(fill ?? ground));
      if (fill == null) canvas.drawPath(p, stroke(ink));
    }

    // Someone else's cursor, with the block that carries their name.
    void cursor(Offset at, Color c, double tagWide) {
      final p = Path()
        ..moveTo(at.dx, at.dy)
        ..lineTo(at.dx, at.dy + 20)
        ..lineTo(at.dx + 5.5, at.dy + 15)
        ..lineTo(at.dx + 14, at.dy + 15)
        ..close();
      canvas.drawPath(p, solid(c));
      canvas.drawPath(p, stroke(ground, 1));
      canvas.drawRect(
        Rect.fromLTWH(at.dx + 12, at.dy + 20, tagWide, 16),
        solid(c),
      );
    }

    // A layer in its bounding box.
    final layer = Rect.fromLTWH(w * .03, h - 150, 168, 104);
    canvas.drawRect(layer, solid(usuki));
    canvas.drawRect(layer, stroke(ink));
    for (final corner in [
      layer.topLeft,
      layer.topRight,
      layer.bottomLeft,
      layer.bottomRight,
    ]) {
      handle(corner);
    }

    // A burst, with a cursor on it.
    final mid = Offset(w * .22, h - 86);
    final burst = Path();
    const points = 9;
    for (var i = 0; i < points * 2; i++) {
      final a = i * math.pi / points - math.pi / 2;
      final o =
          mid + Offset(math.cos(a), math.sin(a)) * (i.isEven ? 62.0 : 45.0);
      i == 0 ? burst.moveTo(o.dx, o.dy) : burst.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(burst..close(), solid(nadeshiko));
    cursor(mid + const Offset(30, 26), orange, 46);

    // A pen path: two anchors, and the handles that bend the line between them.
    final from = Offset(w * .31, h - 44), to = Offset(w * .46, h - 134);
    final fromPull = from + const Offset(64, -96),
        toPull = to + const Offset(-86, 58);
    canvas.drawLine(from, fromPull, stroke(ink, 1));
    canvas.drawLine(to, toPull, stroke(ink, 1));
    canvas.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(fromPull.dx, fromPull.dy, toPull.dx, toPull.dy, to.dx, to.dy),
      stroke(ink, 2.5),
    );
    knob(fromPull);
    knob(toPull);
    handle(from);
    handle(to);

    // A triangle.
    final foot = Offset(w * .52, h - 28);
    canvas.drawPath(
      Path()
        ..moveTo(foot.dx, foot.dy)
        ..lineTo(foot.dx + 104, foot.dy)
        ..lineTo(foot.dx + 52, foot.dy - 128)
        ..close(),
      solid(violet),
    );

    // A timeline: two clips, a row of keyframes, and the playhead across them.
    final track = Offset(w * .63, h - 62);
    canvas.drawRect(
      Rect.fromLTWH(track.dx + 26, track.dy - 62, 150, 18),
      solid(orange),
    );
    canvas.drawRect(
      Rect.fromLTWH(track.dx + 96, track.dy - 36, 118, 18),
      solid(seiji),
    );
    canvas.drawLine(track, track + const Offset(230, 0), stroke(ink, 1));
    key(track + const Offset(8, 0), usuki);
    key(track + const Offset(84, 0));
    key(track + const Offset(160, 0), usuki);
    key(track + const Offset(222, 0));
    canvas.drawLine(
      track + const Offset(122, -78),
      track + const Offset(122, 24),
      stroke(ink),
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: track + const Offset(122, -82),
        width: 11,
        height: 9,
      ),
      solid(ink),
    );

    // A stack of discs, the top one a play button.
    var disc = Offset(w * .86, h - 88);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(disc, 46, solid(seiji));
      canvas.drawCircle(disc, 46, stroke(ground, 2.5));
      if (i < 4) disc += const Offset(18, 5);
    }
    canvas.drawPath(
      Path()
        ..moveTo(disc.dx - 9, disc.dy - 13)
        ..lineTo(disc.dx + 14, disc.dy)
        ..lineTo(disc.dx - 9, disc.dy + 13)
        ..close(),
      solid(ground),
    );
  }

  @override
  bool shouldRepaint(_DecorationPainter old) =>
      !listEquals(old.tones, tones) || old.ink != ink || old.ground != ground;
}

/// Shown in the preview's place when there is no project to preview.
class _Empty extends StatelessWidget {
  const _Empty({required this.searching});
  final bool searching;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(Shape.s(24)),
    decoration: BoxDecoration(
      color: Grey.g10,
      borderRadius: Shape.round(4),
      border: Border.all(color: Grey.g26, width: homeEdge),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          searching ? 'No matches' : 'No projects yet',
          style: TextStyles.name(
            Grey.g100,
            46,
            FontWeight.w800,
          ).copyWith(letterSpacing: -1.8),
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
