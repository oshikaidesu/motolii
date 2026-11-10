// The dock's shared pieces: per-shelf memory, hover, section heads, and the footer at the bottom of a shelf.
import 'package:motolii/skin/inspector_tokens.dart';
import 'package:motolii/skin/window_tokens.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout, kPrimaryButton;
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter/widgets.dart';
import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/widgets/media.dart' show drawStar, glyph;
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/controls.dart' show Badge, Hov;

// Re-exported so shelves get the shared small widgets together with the dock's own.
export '../../widgets/controls.dart' show Badge, Chip, IconPress;

import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/storage/kept_file.dart' show fileKeep, fileList;
import 'package:motolii/workspace/state/state.dart';
import 'package:motolii/widgets/text_gestures.dart';

part 'dock_folder_row.dart';
part 'dock_search.dart';
part 'dock_stars.dart';

/// A [Badge] for a shelf: a tile of [hue] with the glyph at 0.62 of its size.
Widget dockBadge(DockG g, Color hue, {required double size}) => Badge(
  hue,
  size: size,
  child: Glyph(g, size: size * .62, color: WsT.onAccent),
);

/// What the dock remembers per shelf while the user switches between shelves (selection, chip, folds).
/// It lives in the dock's state, never in [Ws].
class DockMem {
  final sel = <String, String>{'Media': 'coda_intro', 'Effects': 'Glow', 'Fonts': 'Avenir Next', 'Colors': 'pop-2', 'Create': 'Shape'};
  final chip = <String, String>{};
  final folded = <String>{'Time'};
  final open = <String>{'Project'};

  /// The ids the user has starred, stored in ~/.motolii/effect_stars.json like the Ease tool panel's stars.
  final starred = _starsRead();

  /// Why the last request to the engine for an entry failed, by the entry's id.
  final trouble = <String, String>{};

  /// Whether the shelf's footer is open (see [DockCtx.foot]).
  bool footOpen = false;
  bool mediaList = false;

  /// The shelves shown as a map with similar items close together (dock_map.dart), instead of as rows of tiles.
  final mapped = <String>{};

  /// Program: show the selected item's code instead of the list.
  bool programCode = false;

  /// Media: list the folders below the open one together with it, and where the tree sits.
  /// [treeSide] is 0 for automatic by the available room, 1 for left, 2 for above.
  bool mediaDeep = false;

  /// Create: the sections the user has folded. None at first, so the moving tiles of every recipe can be looked over.
  final createFolded = <String>{};
  int treeSide = 0;

  /// Media: the open folder (a [FileNode] id) and the height of the tree band when the shelf is narrow.
  String folder = 'Footage';
  double treeHeight = 132;

  /// Effects: which row of the list is chosen (All, Recent, ★, In video, /pack, @deck) and the list's height
  /// when the shelf is narrow.
  String fxPlace = 'All';
  double fxListHeight = 176;

  /// Effects: whether the list is open. When closed in a narrow shelf, it shows only the chosen row.
  bool fxListOpen = false;
}

/// What a shelf body needs from the dock for one build: the memory, the search text, the project, and a way to change local state.
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

  /// Returns [picked] if the footer should show it, otherwise null.
  ///
  /// Opening the footer shortens the tiles, so a tile low on the shelf could move away before the second click of a
  /// double-click. A closed footer therefore opens only once a second click can no longer come, following Microsoft's
  /// "How to distinguish between single and double clicks". The selection itself does not wait,
  /// and neither does a footer that is already open.
  P? foot<P>(P? picked) {
    mem.footOpen = picked != null && (mem.footOpen || !DockHover.secondMayCome.value);
    return mem.footOpen ? picked : null;
  }

  String get chip => mem.chip[shelf] ?? 'All';
  void pickChip(String c) => set(() => mem.chip[shelf] = c);
  bool hit(String name) => query.isEmpty || name.toLowerCase().contains(query.toLowerCase());

  /// The ids of the five closest [items], best first, for when the search text finds nothing.
  ///
  /// Each item is its id, name and description. The engine does the matching, as it does for the effects shelf:
  /// RapidFuzz for a misspelled or partial word and Japanese WordNet for a Japanese word. Every shelf uses it.
  /// Empty while nothing is typed. [least] is the score below which an item is left out (see Motolii.find).
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

/// Hover and tap handling for a tile. It rebuilds only when the pointer enters or leaves.
class DockHover extends StatefulWidget {
  const DockHover({super.key, required this.builder, this.onTap, this.onDoubleTap, this.picks = false, this.onHover, this.onMenu, this.onMove});

  /// Whether Cmd was held when the last tile was pressed.
  static bool cmdAtPress = false;

  /// True after a tile with a double-click action was pressed, while a second press may still come (see [DockCtx.foot]).
  static final secondMayCome = ValueNotifier(false);
  static Timer? _past;
  final Widget Function(BuildContext context, bool hover) builder;
  final VoidCallback? onTap;

  /// Called on a double-click. It runs the item's own action directly, for a tile that has no footer button.
  final VoidCallback? onDoubleTap;

  /// Whether a single press only selects the tile. [onTap] is called as soon as the button goes down.
  /// A font tile does not do this, because its tap sets the font of a role.
  final bool picks;

  /// Called with true when the pointer enters and false when it leaves.
  ///
  /// It is also called with false if the tile is removed while the pointer is over it,
  /// because a MouseRegion that is unmounted under the pointer sends no exit event.
  final ValueChanged<bool>? onHover;

  /// Called on a secondary press (right click) with its position on the screen.
  final ValueChanged<Offset>? onMenu;

  /// Called when the pointer moves over the tile, with its position in the tile.
  final ValueChanged<Offset>? onMove;
  @override
  State<DockHover> createState() => _DockHoverState();
}

class _DockHoverState extends State<DockHover> {
  bool _h = false;
  // Active while a second press would make a double-click.
  Timer? _second;

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

  // A tile that is selected by one press and acted on by two is selected as the button goes down, as Finder does with an icon.
  // Waiting until a second press could no longer come (Flutter's tap waits kDoubleTapTimeout beside a double tap)
  // left the shelf's button acting on the previously selected tile. The second press belongs to the double-click.
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

  // The window is counted from the release, as in Flutter's own double tap (multitap.dart, _registerFirstTap).
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
        // Sees the press as it arrives, before the gesture arena decides what it is.
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

  /// Lets a tile with an action of its own be dragged to the preview, where dropping it does what a double-click does.
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

/// Fill and ink colors: a selected item uses the accent with dark ink, and hover is one grey step lighter.
Color dockFill(bool sel, bool hover, [Color? rest]) => sel ? WsT.accent : (hover ? WsT.card : rest ?? WsT.body);
Color dockInk(bool sel, [Color? rest]) => sel ? WsT.onAccent : rest ?? Grey.g91;

/// A section header inside a shelf body: a hue swatch, the title in capitals, an optional count, and an optional fold chevron.
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
          // The trailing widget is scaled down in a narrow shelf, never clipped.
          if (trailing case final w?)
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: w),
              ),
            ),
          if (count != null) Text('$count', style: T.value(Grey.g56).copyWith(fontSize: T.px(10))),
        ],
      ),
    ),
  );
}

/// The glyph of an [IconPress] in the dock's header: 11 wide, in the ink color the press gives.
Widget Function(Color) dockMark(DockG g) =>
    (ink) => Glyph(g, size: Shape.z(11), color: ink);

/// The footer of a shelf: the selected item (preview, name, facts), where it would go (the selected layer), and its one action.
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

  /// Whether the action creates a new layer instead of changing the selected one. The target then reads 'to new layer'.
  final bool fresh;

  /// A widget beside the action button, such as a three-dot menu as in Spotify.
  final Widget? more;

  /// A widget beside the target saying how long the new layer lasts. The user chooses it before the layer is placed.
  final Widget? lasts;

  /// A small preview of the selected item.
  final Widget? preview;

  /// The item's name, a line of facts about it, the action button's label, and the label shown once [done].
  final String title, meta, action, doneLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onAction;

  /// Whether the action has been done. The button then shows [doneLabel] and does nothing.
  final bool done;
  @override
  Widget build(BuildContext context) {
    final ws = WsScope.of(context, {WsAspect.document, WsAspect.picked}), l = fresh ? null : ws.layer;
    return Container(
      // At least 52 high and as tall as its content. A fixed 52 overflowed by a point (RenderFlex overflow) with two lines of text.
      constraints: BoxConstraints(minHeight: Shape.z(52)),
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
                // Up to two lines of whole words before anything is cut off.
                Text(meta, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.label(Grey.g63)),
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
                    // Scaled down rather than clipped when the shelf is narrow.
                    if (lasts case final w?) ...[
                      SizedBox(width: Shape.s(8)),
                      Flexible(
                        flex: 3,
                        child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: w),
                      ),
                    ],
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

/// What a shelf shows when the search finds nothing, or when the shelf is empty.
class DockEmpty extends StatelessWidget {
  const DockEmpty(this.query, {super.key, this.said});
  final String query;

  /// Shown instead of the default message when nothing is typed: what is empty here and what to do.
  final String? said;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(Shape.s(24)),
    child: Text(said ?? 'Nothing matches “$query”', textAlign: TextAlign.center, style: T.label(Grey.g63)),
  );
}

/// A shelf's sections as cards in one column while the shelf is narrow.
///
/// As the shelf widens, columns of at least 300 px stand side by side, and each section goes to the shortest column so far.
/// [weights] estimate the section heights, in rows.
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
