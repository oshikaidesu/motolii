// The home screen: sidebar, hero preview, and a bento grid of projects.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/storage/disk.dart' show existsFile, imageFile;
import 'package:motolii/storage/open_in_host.dart' show pickFolder;
import 'package:motolii/storage/project_files.dart';
import 'package:motolii/storage/thumbnail_folder.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show IconPress;
import 'package:motolii/widgets/picks.dart' show clickKeys, pickOnClick;
import 'package:motolii/workspace/dock/common/shelf_search_field.dart';
import 'package:motolii/workspace/state/project_facts.dart';
import 'package:motolii/workspace/window/home_card.dart';
import 'package:motolii/workspace/window/home_project.dart';

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
  String? _selected;

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

    // The hero shows the clicked project, else the last-opened, else the newest.
    final sel = _selected ?? widget.lastProject;
    final hero =
        shown.where((d) => d.path == sel).firstOrNull ?? shown.firstOrNull;

    Widget card(HomeProject d, int i, List<HomeProject> docs) => HomeCard(
      d,
      index: i,
      open: d.path == widget.open,
      picked: _picked.contains(d.path),
      selected: d.path == hero?.path,
      menu: _menu == d.path,
      asking: _asking == d.path,
      onTap: () {
        final k = clickKeys();
        if (_picked.isNotEmpty || k.add || k.span) {
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
          return;
        }
        setState(() => _selected = d.path);
      },
      onDoubleTap: () => widget.onOpen(d.path),
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
          // ── Sidebar ──
          SizedBox(
            width: Shape.z(220),
            child: _Sidebar(
              shown: shown,
              selected: hero?.path,
              picked: _picked,
              byName: byName,
              find: _findText,
              onSelect: (path) => setState(() => _selected = path),
              onOpen: widget.onOpen,
              onNew: widget.onNew,
              onClose: widget.onClose,
              onFolder: widget.onFolder != null ? _pickFolder : null,
              onExport: () => widget.onExport([..._picked]),
              onUnpick: () => setState(_picked.clear),
              onByDate: () => setState(() => byName = false),
              onByName: () => setState(() => byName = true),
            ),
          ),
          Container(width: 1, color: Grey.g15),
          // ── Main: hero + bento ──
          Expanded(
            child: Stack(
              children: [
                const _Decorations(),
                Column(
                  children: [
                    // Hero preview
                    if (hero != null)
                      _Hero(
                        d: hero,
                        isOpen: hero.path == widget.open,
                        onOpen: () => widget.onOpen(hero.path),
                      ),
                    if (hero != null) Container(height: 1, color: Grey.g15),
                    // Bento grid
                    Expanded(
                      child: shown.isEmpty
                          ? _Empty(searching: _find.isNotEmpty)
                          : LayoutBuilder(
                              builder: (context, box) {
                                final pad = Shape.s(16);
                                final gap = Shape.s(10);
                                final w = box.maxWidth - pad * 2;
                                final cols = (w / 200).floor().clamp(2, 6);
                                final tileW = (w - gap * (cols - 1)) / cols;
                                final tileH = tileW * 0.6;
                                final items = <Widget>[];
                                for (final (i, d) in shown.indexed) {
                                  final span = _bentoSpan(
                                    i,
                                    shown.length,
                                    cols,
                                  );
                                  items.add(
                                    SizedBox(
                                      width: tileW * span + gap * (span - 1),
                                      height: tileH,
                                      child: card(d, i, shown),
                                    ),
                                  );
                                }
                                return ListView(
                                  padding: EdgeInsets.fromLTRB(
                                    pad,
                                    Shape.s(12),
                                    pad,
                                    Shape.s(32),
                                  ),
                                  children: [
                                    Wrap(
                                      spacing: gap,
                                      runSpacing: gap,
                                      children: items,
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final _findText = TextEditingController();
}

/// Bento pattern: some cards span 2 columns for visual variety.
int _bentoSpan(int i, int total, int cols) {
  if (cols < 3 || total <= 2) return 1;
  if (i == 0) return 2;
  // Every 5th card after the first gets a wide span, if there's room.
  if (i >= 3 && (i - 3) % 5 == 0) return math.min(2, cols - 1);
  return 1;
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar
// ─────────────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.shown,
    required this.selected,
    required this.picked,
    required this.byName,
    required this.find,
    required this.onSelect,
    required this.onOpen,
    required this.onNew,
    required this.onClose,
    required this.onFolder,
    required this.onExport,
    required this.onUnpick,
    required this.onByDate,
    required this.onByName,
  });
  final List<HomeProject> shown;
  final String? selected;
  final Set<String> picked;
  final bool byName;
  final TextEditingController find;
  final void Function(String path) onSelect;
  final void Function(String path) onOpen;
  final VoidCallback onNew, onClose, onExport, onUnpick, onByDate, onByName;
  final VoidCallback? onFolder;

  @override
  Widget build(BuildContext context) {
    // Show the 6 most recent projects in the sidebar list.
    final recent = [...shown]..sort((a, b) => b.changed.compareTo(a.changed));
    final top = recent.take(6).toList();

    return ColoredBox(
      color: Grey.g07,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Wordmark + close
          Padding(
            padding: EdgeInsets.fromLTRB(
              Shape.s(16),
              Shape.s(12),
              Shape.s(8),
              Shape.s(4),
            ),
            child: Row(
              children: [
                Container(
                  width: Shape.z(20),
                  height: Shape.z(20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: WindowTokens.accent,
                    borderRadius: Shape.round(5),
                  ),
                  child: Text(
                    'M',
                    style: TextStyles.title(WindowTokens.onAccent).copyWith(
                      fontSize: TextStyles.px(11),
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
                SizedBox(width: Shape.s(6)),
                Text(
                  'Motolii',
                  style: TextStyles.name(
                    Grey.g76,
                  ).copyWith(fontWeight: FontWeight.w700, letterSpacing: -.3),
                ),
                const Spacer(),
                IconPress(
                  (c) => Glyph(AppGlyphs.close, size: Shape.z(12), color: c),
                  key: const ValueKey('home-close'),
                  tip: 'Close',
                  onTap: onClose,
                  size: Shape.z(24),
                  ink: Grey.g38,
                ),
              ],
            ),
          ),

          // + New
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Shape.s(12),
              vertical: Shape.s(8),
            ),
            child: _NewButton(onTap: onNew),
          ),

          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Shape.s(12)),
            child: SizedBox(
              height: Shape.z(28),
              child: ShelfSearchField(controller: find, hint: 'Search'),
            ),
          ),
          SizedBox(height: Shape.s(8)),

          // Sort
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Shape.s(12)),
            child: Row(
              children: [
                homeButton('home-by-date', 'Date', !byName, onByDate),
                homeButton('home-by-name', 'Name', byName, onByName),
                if (picked.isNotEmpty) ...[
                  const Spacer(),
                  homeButton(
                    'home-export',
                    'Export ${picked.length}',
                    true,
                    onExport,
                  ),
                  homeButton('home-unpick', '×', false, onUnpick),
                ],
              ],
            ),
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: Shape.s(10),
              horizontal: Shape.s(12),
            ),
            child: Container(height: 1, color: Grey.g15),
          ),

          // Recent list label
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Shape.s(16)),
            child: Text('Recent', style: TextStyles.micro(Grey.g38)),
          ),
          SizedBox(height: Shape.s(4)),

          // Recent project list
          for (final d in top)
            _SidebarItem(
              d: d,
              selected: d.path == selected,
              onTap: () => onSelect(d.path),
              onDoubleTap: () => onOpen(d.path),
            ),

          const Spacer(),

          // Folder
          if (onFolder != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                Shape.s(12),
                0,
                Shape.s(12),
                Shape.s(12),
              ),
              child: NakedButton(
                enableFeedback: false,
                onPressed: onFolder!,
                child: Row(
                  children: [
                    Glyph(AppGlyphs.folder, size: Shape.z(12), color: Grey.g38),
                    SizedBox(width: Shape.s(6)),
                    Expanded(
                      child: Text(
                        '~/Movies/Motolii',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.micro(Grey.g38),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.d,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
  });
  final HomeProject d;
  final bool selected;
  final VoidCallback onTap, onDoubleTap;
  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onDoubleTap: widget.onDoubleTap,
      child: NakedButton(
        enableFeedback: false,
        onPressed: widget.onTap,
        child: AnimatedContainer(
          duration: Motion.dur,
          padding: EdgeInsets.symmetric(
            horizontal: Shape.s(16),
            vertical: Shape.s(5),
          ),
          color: widget.selected
              ? WindowTokens.accent.withValues(alpha: .1)
              : _h
              ? Grey.g10
              : null,
          child: Row(
            children: [
              // Tiny thumbnail
              Container(
                width: Shape.z(32),
                height: Shape.z(20),
                decoration: BoxDecoration(
                  color: Grey.g13,
                  borderRadius: Shape.round(3),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.d.picture != null
                    ? Image(
                        image: imageFile(widget.d.picture!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              SizedBox(width: Shape.s(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.d.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.label(
                        widget.selected
                            ? WindowTokens.accentInk
                            : (_h ? Grey.g91 : Grey.g63),
                      ),
                    ),
                    Text(
                      homeAge(widget.d.changed),
                      style: TextStyles.micro(Grey.g38),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero preview
// ─────────────────────────────────────────────────────────────────────────────

class _Hero extends StatefulWidget {
  const _Hero({required this.d, required this.isOpen, required this.onOpen});
  final HomeProject d;
  final bool isOpen;
  final VoidCallback onOpen;
  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  @override
  Widget build(BuildContext context) {
    final f = widget.d.facts;
    return LayoutBuilder(
      builder: (context, box) {
        final tall = box.maxWidth * 0.32;
        return GestureDetector(
          onDoubleTap: widget.onOpen,
          child: SizedBox(
            width: double.infinity,
            height: tall.clamp(160.0, 320.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Thumbnail background
                if (widget.d.picture != null)
                  Image(image: imageFile(widget.d.picture!), fit: BoxFit.cover)
                else
                  _HeroPlaceholder(name: widget.d.name),
                // Gradient overlay so text reads
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Grey.g07.withValues(alpha: .2),
                        Grey.g07.withValues(alpha: .85),
                      ],
                    ),
                  ),
                ),
                // Info
                Positioned(
                  left: Shape.s(24),
                  bottom: Shape.s(20),
                  right: Shape.s(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.d.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.title(Grey.g95).copyWith(
                                fontSize: TextStyles.px(22),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: Shape.s(4)),
                            Text(
                              [
                                homeAge(widget.d.changed),
                                if (f != null && f.seconds > 0)
                                  homeLength(f.seconds),
                                ...homeFacts(widget.d),
                              ].join(' · '),
                              style: TextStyles.label(Grey.g63),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: Shape.s(16)),
                      _OpenButton(
                        label: widget.isOpen ? 'Continue editing →' : 'Open →',
                        onTap: widget.onOpen,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          WindowTokens.seiji.withValues(alpha: .12),
          Grey.g10,
          WindowTokens.nadeshiko.withValues(alpha: .08),
        ],
      ),
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w200,
          color: Grey.g20,
        ),
      ),
    ),
  );
}

class _OpenButton extends StatefulWidget {
  const _OpenButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  State<_OpenButton> createState() => _OpenButtonState();
}

class _OpenButtonState extends State<_OpenButton> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: NakedButton(
      enableFeedback: false,
      onPressed: widget.onTap,
      child: AnimatedContainer(
        duration: Motion.dur,
        padding: EdgeInsets.symmetric(
          horizontal: Shape.s(16),
          vertical: Shape.s(8),
        ),
        decoration: BoxDecoration(
          color: _h ? WindowTokens.accentHot : WindowTokens.accent,
          borderRadius: Shape.round(6),
        ),
        child: Text(
          widget.label,
          style: TextStyles.label(WindowTokens.onAccent)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// New button
// ─────────────────────────────────────────────────────────────────────────────

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
        padding: EdgeInsets.symmetric(vertical: Shape.s(8)),
        decoration: BoxDecoration(
          color: _h ? WindowTokens.accent : null,
          border: Border.all(
            color: _h ? WindowTokens.accent : Grey.g20,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: Shape.round(6),
        ),
        child: Center(
          child: Text(
            '+ New Project',
            style: TextStyles.label(_h ? WindowTokens.onAccent : Grey.g63)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Background decorations (brand-coloured shapes scattered behind the grid)
// ─────────────────────────────────────────────────────────────────────────────

class _Decorations extends StatelessWidget {
  const _Decorations();
  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: CustomPaint(
      painter: _DecorationPainter(
        c1: WindowTokens.seiji,
        c2: WindowTokens.nadeshiko,
        c3: WindowTokens.usuki,
      ),
    ),
  );
}

class _DecorationPainter extends CustomPainter {
  _DecorationPainter({required this.c1, required this.c2, required this.c3});
  final Color c1, c2, c3;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    void circle(double x, double y, double r, Color c, double a) {
      canvas.drawCircle(
        Offset(w * x, h * y),
        r,
        Paint()..color = c.withValues(alpha: a),
      );
    }

    void triangle(double cx, double cy, double r, Color c, double a) {
      final path = Path();
      for (var i = 0; i < 3; i++) {
        final angle = (i * 2 * math.pi / 3) - math.pi / 2;
        final p = Offset(
          w * cx + r * math.cos(angle),
          h * cy + r * math.sin(angle),
        );
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = c.withValues(alpha: a));
    }

    void diamond(double cx, double cy, double r, Color c, double a) {
      canvas.save();
      canvas.translate(w * cx, h * cy);
      canvas.rotate(math.pi / 4);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r, height: r),
        Paint()..color = c.withValues(alpha: a),
      );
      canvas.restore();
    }

    // Large blobs
    circle(0.85, 0.15, w * 0.06, c2, .06);
    circle(0.12, 0.72, w * 0.045, c3, .05);
    circle(0.55, 0.88, w * 0.03, c1, .07);

    // Small shapes
    triangle(0.92, 0.55, 18, c3, .08);
    triangle(0.08, 0.35, 12, c1, .06);
    diamond(0.78, 0.82, 16, c2, .07);
    diamond(0.18, 0.18, 10, c1, .05);

    // Dots
    circle(0.3, 0.12, 3, c1, .12);
    circle(0.7, 0.35, 2.5, c2, .1);
    circle(0.45, 0.65, 4, c3, .1);
    circle(0.88, 0.75, 2.5, c1, .08);
    circle(0.25, 0.52, 2, c2, .08);
    circle(0.62, 0.22, 3, c3, .1);

    // Bezier curve accent
    final curve = Path()
      ..moveTo(w * 0.15, h * 0.92)
      ..cubicTo(w * 0.3, h * 0.86, w * 0.45, h * 0.95, w * 0.6, h * 0.88);
    canvas.drawPath(
      curve,
      Paint()
        ..color = c2.withValues(alpha: .06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_DecorationPainter old) =>
      old.c1 != c1 || old.c2 != c2 || old.c3 != c3;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

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
