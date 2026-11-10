// The dock's shared pieces: what a shelf remembers, hover, chips, section heads, the detail strip at the foot of a shelf.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout, kPrimaryButton;
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import '../../skin/forms/forms.dart';
import '../../inspector/inspector_parts.dart' show Pop;
import '../../widgets/media.dart' show drawStar, glyph;
import '../../skin/tokens.dart';
import '../../widgets/controls.dart' show Badge, Hov;
export '../../widgets/controls.dart' show Badge, Chip, IconPress; // (the shared small parts the shelves use, with the dock's own)
import 'dock_glyphs.dart';
import '../window/settings_file.dart' show fileKeep, fileList;
import '../state/state.dart';
import '../../widgets/text_gestures.dart';

part 'dock_folder_row.dart';
part 'dock_search.dart';
part 'dock_stars.dart';

/// The dock's badge: a hue tile with its glyph at .62 of it (the one [Badge], dressed for a shelf).
Widget dockBadge(DockG g, Color hue, {required double size}) => Badge(
  hue,
  size: size,
  child: Glyph(g, size: size * .62, color: WsT.onAccent),
);

/// What the dock remembers per shelf while you hop between shelves (selection, chip, folds). Lives in the dock's state, never in [Ws].
class DockMem {
  final sel = <String, String>{'Media': 'coda_intro', 'Effects': 'Glow', 'Fonts': 'Avenir Next', 'Colors': 'pop-2', 'Create': 'Shape'};
  final chip = <String, String>{};
  final folded = <String>{'Time'};
  final open = <String>{'Project'};
  final starred = _starsRead(); // (what the hand starred: kept in ~/.motolii/effect_stars.json, as the Ease tool panel keeps its own)

  /// Why the last thing asked of the inside for an entry was not done (by the entry's id).
  final trouble = <String, String>{};

  /// The shelf's foot is open (DockCtx.foot).
  bool footOpen = false;
  bool mediaList = false;

  /// The shelves shown as a map, the alike near (dock_map.dart), not as tiles in rows.
  final mapped = <String>{};

  /// Program: the picked one's code rather than the list.
  bool programCode = false;

  /// Media: the folders below the open one listed with it (all at once), and where the tree lies (0 by the room, 1 left, 2 above).
  bool mediaDeep = false;

  /// Create: the sections folded away by the hand (none at first: the recipes' moving tiles are the list to look over).
  final createFolded = <String>{};
  int treeSide = 0;

  /// The Media shelf: the open folder (a [FileNode] id) and the tree band's height when the shelf is narrow.
  String folder = 'Footage';
  double treeHeight = 132;

  /// The Effects shelf: where it looks (a row of its list: All, Recent, ★, In video, /pack, @deck) and the list's height
  /// when the shelf is narrow.
  String fxPlace = 'All';
  double fxListHeight = 176;
  bool fxListOpen = false; // (narrow: else folded to the one row that says where it looks)
}

/// One build's view of the dock for a shelf body: the memory, the search text, the document, and how to change local state.
class DockCtx {
  DockCtx(this.shelf, this.mem, this.query, this.ws, this.set, this.clearSearch);
  final String shelf;
  final DockMem mem;
  final String query;
  final Ws ws;
  final void Function(VoidCallback) set;
  final VoidCallback clearSearch;

  String? get sel => mem.sel[shelf];
  void pick(String id) => set(() => mem.sel[shelf] = id);

  /// What the shelf's foot shows of its pick. A foot opening shortens the tiles, and a tile low on the shelf would leave
  /// from under the second press of a double click: a shut foot opens once that press can no longer come, as Microsoft's
  /// "How to distinguish between single and double clicks" times what a click does that a double click cannot follow.
  /// The pick does not wait ("one click usually selects an item"), nor a foot already open (golf (77)).
  P? foot<P>(P? picked) {
    mem.footOpen = picked != null && (mem.footOpen || !DockHover.secondMayCome.value);
    return mem.footOpen ? picked : null;
  }

  String get chip => mem.chip[shelf] ?? 'All';
  void pickChip(String c) => set(() => mem.chip[shelf] = c);
  bool hit(String name) => query.isEmpty || name.toLowerCase().contains(query.toLowerCase());

  /// When the words as typed find nothing, the shelf's nearest five, best first (each item its id, name and what it
  /// does): the inside's find, RapidFuzz for a word typed wrong or in part, Japanese WordNet for a Japanese word, as the
  /// effects shelf finds them (golf_noise.md (91), (96)); every shelf alike (97). None while nothing is typed.
  /// [least]: the score under which one is left out (Motolii.find).
  List<String> near(Iterable<(String, String, String)> items, {double least = 0}) =>
      query.trim().isEmpty ? const [] : ws.inside?.find(query, items, least: least) ?? const [];
  Set<String> get _stars => mem.starred;
  bool starred(String id) => _stars.contains(id);
  void star(String id) => set(() {
    _stars.contains(id) ? _stars.remove(id) : _stars.add(id);
    _starsKeep(_stars);
  });
  void unstar(Iterable<String> ids) => set(() {
    _stars.removeAll(ids);
    _starsKeep(_stars);
  });
  void toggle(Set<String> s, String id) => set(() => s.contains(id) ? s.remove(id) : s.add(id));
}

/// Hover + tap, nothing else: repaints only when the pointer enters or leaves.
class DockHover extends StatefulWidget {
  const DockHover({super.key, required this.builder, this.onTap, this.onDoubleTap, this.picks = false, this.onHover, this.onMenu, this.onMove});

  /// Whether ⌘ was held as the last tile was pressed.
  static bool cmdAtPress = false;

  /// A tile that two presses act on was pressed, and a second press may still come (DockCtx.foot).
  static final secondMayCome = ValueNotifier(false);
  static Timer? _past;
  final Widget Function(BuildContext context, bool hover) builder;
  final VoidCallback? onTap;

  /// Two presses: the item's own action at once (joined: a tile made without its foot's button).
  final VoidCallback? onDoubleTap;

  /// One press only picks it (not so a font's, which sets a role's font): told as the button goes down.
  final bool picks;

  /// The pointer came onto it (true) or went off (false), told once each; gone from the window under it, off as well
  /// (a MouseRegion unmounted under the pointer tells no exit).
  final ValueChanged<bool>? onHover;

  /// A secondary press (a right click), told with where it was on the screen.
  final ValueChanged<Offset>? onMenu;

  /// The pointer moved over it, told with where it is in the tile.
  final ValueChanged<Offset>? onMove;
  @override
  State<DockHover> createState() => _DockHoverState();
}

class _DockHoverState extends State<DockHover> {
  bool _h = false;
  Timer? _second; // (while a second press would make it two)

  @override
  void dispose() {
    _second?.cancel();
    if (_h) widget.onHover?.call(false);
    super.dispose();
  }

  void _hover(bool h) {
    setState(() => _h = h);
    widget.onHover?.call(h);
  }

  // A tile that one press picks and two act on is picked as the button goes down, as Finder picks an icon and opens it on the
  // second click: a press told only once a second could no longer come (Flutter's tap waits kDoubleTapTimeout beside
  // a double tap) left the shelf's button on the tile picked before; golf (77). The second press is the double's.
  void _down(PointerDownEvent e) {
    DockHover.cmdAtPress = HardwareKeyboard.instance.isMetaPressed;
    if (!widget.picks || widget.onDoubleTap == null || widget.onTap == null || e.buttons != kPrimaryButton) return;
    final second = _second?.isActive ?? false;
    _second?.cancel();
    _second = second ? null : Timer(kDoubleTapTimeout, () {});
    DockHover._past?.cancel();
    DockHover.secondMayCome.value = true;
    if (!second) widget.onTap!();
  }

  // (counted from the release, as Flutter's own double tap: multitap.dart _registerFirstTap)
  void _up(PointerEvent e) {
    if (!DockHover.secondMayCome.value) return;
    DockHover._past?.cancel();
    DockHover._past = Timer(kDoubleTapTimeout, () => DockHover.secondMayCome.value = false);
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
    onEnter: (_) => _hover(true),
    onExit: (_) => _hover(false),
    onHover: widget.onMove == null ? null : (e) => widget.onMove!(e.localPosition),
    child: _carried(
      Listener(
        // (the press as it comes, before the gestures settle which it is)
        onPointerDown: _down,
        onPointerUp: _up,
        onPointerCancel: _up,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.picks && widget.onDoubleTap != null ? null : widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          onSecondaryTapDown: widget.onMenu == null ? null : (d) => widget.onMenu!(d.globalPosition),
          child: widget.builder(context, _h),
        ),
      ),
    ),
  );

  /// A tile that has an action of its own can be carried to the stage: dropped there, it does what two presses do.
  Widget _carried(Widget tile) => widget.onDoubleTap == null
      ? tile
      : Draggable<VoidCallback>(
          data: widget.onDoubleTap!,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: IgnorePointer(
            child: Container(
              width: Shape.z(22),
              height: Shape.z(22),
              decoration: BoxDecoration(color: WsT.accent, borderRadius: BorderRadius.all(Shape.r(4))),
            ),
          ),
          child: tile,
        );
}

/// Pop selection colours: a picked item is the accent with dark ink; hover is one grey step up.
Color dockFill(bool sel, bool hover, [Color? rest]) => sel ? WsT.accent : (hover ? WsT.card : rest ?? WsT.body);
Color dockInk(bool sel, [Color? rest]) => sel ? WsT.onAccent : rest ?? Grey.g91;

/// A section head inside a shelf body: a flat hue block, the name in caps, a count; optional fold chevron.
class DockSection extends StatelessWidget {
  const DockSection(this.title, {super.key, this.count, this.hue, this.folded, this.onTap, this.trailing});
  final String title;
  final int? count;
  final Color? hue;
  final bool? folded;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => DockHover(
    onTap: onTap,
    builder: (context, h) => Container(
      height: Shape.z(24),
      color: h && onTap != null ? WsT.raised : WsT.card,
      padding: EdgeInsets.symmetric(horizontal: WsT.inset),
      child: Row(
        children: [
          if (folded != null) ...[
            AnimatedRotation(
              turns: folded! ? 0 : .25,
              duration: Mo.dur,
              curve: Mo.ease,
              child: Glyph(DockG.chevron, size: Shape.z(8), color: Grey.g63),
            ),
            SizedBox(width: Shape.s(6)),
          ],
          Container(
            width: Shape.z(8),
            height: Shape.z(8),
            decoration: BoxDecoration(color: hue ?? Grey.g56, borderRadius: BorderRadius.all(Shape.r(2))),
          ),
          SizedBox(width: Shape.s(6)),
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: T.micro(Grey.g91).copyWith(fontWeight: FontWeight.w700, letterSpacing: .9),
            ),
          ),
          if (trailing case final w?)
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: w),
              ),
            ), // (drawn smaller in a narrow shelf, never cut)
          if (count != null) Text('$count', style: T.value(Grey.g56).copyWith(fontSize: T.px(10))),
        ],
      ),
    ),
  );
}

/// The glyph of an [IconPress] in the dock's header: 11 wide, in the ink the press gives.
Widget Function(Color) dockMark(DockG g) =>
    (ink) => Glyph(g, size: Shape.z(11), color: ink);

/// The foot of a shelf: what is picked (preview, name, facts), where it would go (the selected layer), and the one action, in the accent.
class DockFooter extends StatelessWidget {
  const DockFooter({
    super.key,
    this.preview,
    required this.title,
    required this.meta,
    required this.action,
    this.onAction,
    this.done = false,
    this.doneLabel = 'Added',
    this.fresh = false,
    this.lasts,
    this.more,
  });

  /// What the action does is make a new thing (not change the selected one): 'to new layer'.
  final bool fresh;
  final Widget? more; // (beside the action: Spotify's three dots)
  final Widget? lasts; // (how long the new thing lasts, chosen before it is placed: beside where it goes)
  final Widget? preview;
  final String title, meta, action, doneLabel;
  final VoidCallback? onAction;
  final bool done;
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked}), l = fresh ? null : ws.layer;
    return Container(
      constraints: BoxConstraints(
        minHeight: Shape.z(52),
      ), // (as tall as what it says, 52 at least: two lines of words overflowed a fixed 52 by a point, Flutter's RenderFlex overflow; golf (95))
      padding: EdgeInsets.symmetric(horizontal: WsT.inset),
      decoration: BoxDecoration(
        color: WsT.card,
        border: Border(
          top: BorderSide(color: WsT.ground, width: WsT.gutter),
        ),
      ),
      child: Row(
        children: [
          if (preview case final p?) ...[SizedBox.square(dimension: Shape.z(34), child: p), SizedBox(width: Shape.s(8))],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: T.name(Grey.g95).copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: Shape.s(4)),
                Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.label(Grey.g63)), // (two lines of whole words before anything is left out)
                SizedBox(height: Shape.s(4)),
                Row(
                  children: [
                    Text('to ', style: T.label(Grey.g56)),
                    if (l != null) ...[
                      Container(
                        width: Shape.z(6),
                        height: Shape.z(6),
                        decoration: BoxDecoration(color: wsTone(l.kind), borderRadius: BorderRadius.all(Shape.r(1))),
                      ),
                      SizedBox(width: Shape.s(4)),
                      Flexible(
                        child: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g91)),
                      ),
                    ] else
                      Flexible(
                        child: Text('new layer', maxLines: 1, overflow: TextOverflow.ellipsis, style: T.label(Grey.g91)),
                      ),
                    if (lasts case final w?) ...[
                      SizedBox(width: Shape.s(8)),
                      Flexible(
                        flex: 3,
                        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: w),
                      ),
                    ], // (smaller rather than cut, when the shelf is narrow)
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: Shape.s(6)),
          ?more,
          DockHover(
            onTap: done ? null : onAction,
            builder: (context, h) => AnimatedContainer(
              duration: Mo.dur,
              curve: Mo.ease,
              height: Shape.z(24),
              padding: EdgeInsets.symmetric(horizontal: Shape.s(10)),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? WsT.raised : WsT.accent,
                borderRadius: BorderRadius.all(Shape.r(WsT.radius)),
                border: Border.all(color: h && !done ? Grey.g95 : const Color(0x00000000)),
              ),
              child: Text(done ? doneLabel : action, style: T.name(done ? Grey.g76 : WsT.onAccent).copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

/// What a shelf shows when the search finds nothing.
class DockEmpty extends StatelessWidget {
  const DockEmpty(this.query, {super.key, this.said});
  final String query;
  final String? said; // (nothing typed: what is empty here, and what to do)
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(Shape.s(24)),
    child: Text(said ?? 'Nothing matches “$query”', textAlign: TextAlign.center, style: T.label(Grey.g63)),
  );
}

/// A shelf's sections as cards: one column while the shelf is narrow; as it widens, columns of at least 300 px stand side by side
/// and each section goes to the shortest column so far ([weights] estimate the heights, in rows). A shelf made wider shows more at once.
class DockMasonry extends StatelessWidget {
  const DockMasonry({super.key, required this.children, required this.weights});
  final List<Widget> children;
  final List<double> weights;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final n = wsCols(box.maxWidth, 300, max: 4);
      if (n == 1) return ListView(padding: EdgeInsets.zero, children: children);
      final cols = List.generate(n, (_) => <Widget>[]), h = List.filled(n, 0.0);
      for (final (i, w) in children.indexed) {
        var k = 0;
        for (var j = 1; j < n; j++) {
          if (h[j] < h[k]) k = j;
        }
        cols[k].add(w);
        h[k] += weights[i];
      }
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, col) in cols.indexed) ...[
                if (i > 0) const SizedBox(width: WsT.gutter),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: col),
                ),
              ],
            ],
          ),
        ],
      );
    },
  );
}
