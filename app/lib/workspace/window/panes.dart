// The window's panes: panels laid out by the `docking` package.
//
// A tab can be dragged onto another strip or split off to a side, and every divider can be resized.
// A tab cannot be detached into its own window, because that needs the native shell.
// Colors come from WsT, so both the light and dark shades apply.
import 'package:motolii/skin/window_tokens.dart';
import 'package:docking/docking.dart';
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/state.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

class WsPanes extends StatefulWidget {
  const WsPanes({super.key, required this.panes, required this.preset});
  final List<WsPane> panes;

  /// Builds the arrangement a new window starts with.
  final DockingArea Function(DockingArea Function(WsAt at, {double? size}) strip) preset;
  @override
  State<WsPanes> createState() => _WsPanesState();
}

class _WsPanesState extends State<WsPanes> {
  late final _layout = DockingLayout(root: widget.preset(_strip));
  Ws? _ws;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WsScope.read(context);
    if (ws == _ws) return;
    _ws?.on[WsAspect.fronted]!.removeListener(_follow);
    _ws = ws..on[WsAspect.fronted]!.addListener(_follow);
  }

  @override
  void dispose() {
    _ws?.on[WsAspect.fronted]!.removeListener(_follow);
    super.dispose();
  }

  (String, int)? _fronted;
  void _follow() {
    if (_ws!.fronted case final f? when f != _fronted) {
      // A pane has asked to be brought to the front.
      _fronted = f;
      _toFront(f.$1);
    }
  }

  void _toFront(String s) {
    final tabs = _layout.findDockingTabsWithItem(s);
    if (tabs == null) return;
    final i = [for (var k = 0; k < tabs.childrenCount; k++) tabs.childAt(k).id].indexOf(s);
    if (i < 0 || tabs.selectedIndex == i) return;
    tabs.selectedIndex = i;
    _layout.rebuild();
  }

  /// The panes that start at [at], in list order: a single pane is returned as it is, several become a tab strip.
  DockingArea _strip(WsAt at, {double? size}) {
    final here = [
      for (final p in widget.panes)
        if (p.at == at) p,
    ];
    return here.length == 1 ? _item(here.single, size: size) : DockingTabs([for (final p in here) _item(p)], size: size);
  }

  DockingItem _item(WsPane p, {double? size}) {
    final name = p.name;
    return DockingItem(
      id: name,
      name: p.iconOnly ? null : name,
      leading: (context, status) => Semantics(
        label: name,
        button: true,
        child: Padding(
          padding: EdgeInsets.only(right: p.iconOnly ? Shape.s(0) : Shape.s(5)),
          child: Forms.worn.paneMark(
            context,
            selected: status == TabStatus.selected,
            mark: p.glyph == null
                ? Text(p.name.characters.first, style: T.micro(status == TabStatus.selected ? Grey.g95 : Grey.g56))
                : Glyph(p.glyph!, size: Shape.z(12), color: status == TabStatus.selected ? Grey.g95 : Grey.g56),
          ),
        ),
      ),
      widget: WsPanel(child: p.build()),
      size: size,
      minimalSize: p.minSize,
      keepAlive: true,
      // Nothing can reopen a closed pane yet, so panes cannot be closed.
      closable: false,
      maximizable: false,
    );
  }

  @override
  Widget build(BuildContext context) => TabbedViewTheme(
    data: _tabs(),
    child: MultiSplitViewTheme(
      data: MultiSplitViewThemeData(
        dividerThickness: WsT.gutter * 2,
        dividerPainter: DividerPainters.background(color: WsT.ground, highlightedColor: WsT.accentInk),
      ),
      child: Docking(layout: _layout, maximizableItem: false, maximizableTab: false, maximizableTabsArea: false),
    ),
  );
}

/// The tab strip theme: a quiet band on the gutter, with the selected tab in the panel's body color and an accent underline.
/// A form with [Forms.plainTabs] drops the tab backgrounds, so its own glyph is the only sign of which pane is selected.
TabbedViewThemeData _tabs() {
  final t = Grey.light ? TabbedViewThemeData.minimalist() : TabbedViewThemeData.dark();
  final plain = Forms.worn.plainTabs;
  t.tabsArea
    ..color = WsT.ground
    ..border = null
    ..initialGap = 0
    ..middleGap = plain ? Shape.s(2) : WsT.gutter
    ..gapBottomBorder = BorderSide.none
    ..dropColor = WsT.accent.withValues(alpha: .35)
    ..normalButtonColor = Grey.g56
    ..hoverButtonColor = Grey.g91;
  t.tab
    // The padding is small enough for seven shelf tabs to fit a dock squeezed to 229 px by a 1280 px window.
    ..padding = EdgeInsets.fromLTRB(Shape.s(plain ? 4 : 8), Shape.s(5), Shape.s(plain ? 4 : 8), Shape.s(5))
    ..margin = EdgeInsets.zero
    ..innerBottomBorder = null
    ..innerTopBorder = null
    ..textStyle = T.micro(Grey.g63).copyWith(fontWeight: FontWeight.w600, letterSpacing: .6)
    ..decoration = plain ? const BoxDecoration() : BoxDecoration(color: WsT.card)
    ..draggingDecoration = BoxDecoration(color: plain ? WsT.body : WsT.raised)
    ..normalButtonColor = Grey.g56
    ..hoverButtonColor = Grey.g91
    ..selectedStatus = (TabStatusThemeData()
      ..decoration = plain
          ? const BoxDecoration()
          : BoxDecoration(
              color: WsT.body,
              border: Border(bottom: BorderSide(color: WsT.accentInk, width: 2)),
            )
      ..fontColor = Grey.g95)
    ..highlightedStatus = (TabStatusThemeData()
      ..decoration = plain ? const BoxDecoration() : BoxDecoration(color: WsT.raised)
      ..fontColor = Grey.g91);
  t.contentArea
    ..decoration = BoxDecoration(color: WsT.body)
    ..padding = EdgeInsets.zero;
  return t;
}
