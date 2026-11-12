// The window's panes: panels laid out by the `docking` package.
//
// A tab can be dragged onto another strip or split off to a side, and every divider can be resized.
// A tab cannot be detached into its own window, because that needs the native shell.
// Colors come from WindowTokens, so both the light and dark shades apply.
import 'package:flutter/widgets.dart';

import 'package:docking/docking.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/workspace/state/pane.dart';
import 'package:motolii/workspace/state/workspace_aspect.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

class Panes extends StatefulWidget {
  const Panes({super.key, required this.panes, required this.workspaces});
  final List<Pane> panes;

  /// The arrangements the window switches between by name (the view state `workspace`), the first one at the start,
  /// each with the pane it brings to the front.
  final Map<
    String,
    (
      DockingArea Function(
        DockingArea Function(PaneStrip at, {double? size}) strip,
      ),
      String?,
    )
  >
  workspaces;
  @override
  State<Panes> createState() => _PanesState();
}

class _PanesState extends State<Panes> {
  late String _shown = widget.workspaces.keys.first;
  late final _layout = DockingLayout(
    root: widget.workspaces[_shown]!.$1(_strip),
  );
  WorkspaceController? _ws;

  // What the user made of each workspace left, as docking writes a layout: going back finds it as it was left, as
  // After Effects keeps the changes made to a workspace.
  final _kept = <String, String>{};
  static const _ids = _Ids();

  void _switch() {
    final name = _ws!.viewOf('workspace', widget.workspaces.keys.first);
    final to = widget.workspaces[name];
    if (name == _shown || to == null) return;
    _kept[_shown] = _layout.stringify(parser: _ids);
    _shown = name;
    if (_kept[name] case final kept?) {
      _layout.load(layout: kept, parser: _ids, builder: _Areas(this));
    } else {
      _layout.root = to.$1(_strip);
      // Only a workspace's first opening brings its pane to the front; after that it is as it was left.
      if (to.$2 case final pane?) _toFront(pane);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ws = WorkspaceScope.read(context);
    if (ws == _ws) return;
    _ws?.on[WorkspaceAspect.fronted]!.removeListener(_follow);
    _ws?.on[WorkspaceAspect.view]!.removeListener(_switch);
    _ws = ws
      ..on[WorkspaceAspect.fronted]!.addListener(_follow)
      ..on[WorkspaceAspect.view]!.addListener(_switch);
  }

  @override
  void dispose() {
    _ws?.on[WorkspaceAspect.fronted]!.removeListener(_follow);
    _ws?.on[WorkspaceAspect.view]!.removeListener(_switch);
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
    final i = [for (var k = 0; k < tabs.childrenCount; k++) tabs.childAt(k).id]
        .indexOf(s);
    if (i < 0 || tabs.selectedIndex == i) return;
    tabs.selectedIndex = i;
    _layout.rebuild();
  }

  /// The panes that start at [at], in list order: a single pane is returned as it is, several become a tab strip.
  DockingArea _strip(PaneStrip at, {double? size}) {
    final here = [
      for (final p in widget.panes)
        if (p.at == at) p,
    ];
    return here.length == 1
        ? _item(here.single, size: size)
        : DockingTabs([for (final p in here) _item(p)], size: size);
  }

  DockingItem _item(Pane p, {double? size, double? weight}) {
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
                ? Text(
                    p.name.characters.first,
                    style: TextStyles.micro(
                      status == TabStatus.selected ? Grey.g95 : Grey.g56,
                    ),
                  )
                : Glyph(
                    p.glyph!,
                    size: Shape.z(12),
                    color: status == TabStatus.selected ? Grey.g95 : Grey.g56,
                  ),
          ),
        ),
      ),
      widget: Panel(child: p.build()),
      size: size,
      weight: weight,
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
        dividerThickness: WindowTokens.gutter * 2,
        dividerPainter: DividerPainters.background(
          color: WindowTokens.ground,
          highlightedColor: WindowTokens.accentInk,
        ),
      ),
      child: Docking(
        layout: _layout,
        maximizableItem: false,
        maximizableTab: false,
        maximizableTabsArea: false,
      ),
    ),
  );
}

/// The tab strip theme: a quiet band on the gutter, with the selected tab in the panel's body color and an accent underline.
/// A form with [Forms.plainTabs] drops the tab backgrounds, so its own glyph is the only sign of which pane is selected.
TabbedViewThemeData _tabs() {
  final t = Grey.light
      ? TabbedViewThemeData.minimalist()
      : TabbedViewThemeData.dark();
  final plain = Forms.worn.plainTabs;
  t.tabsArea
    ..color = WindowTokens.ground
    ..border = null
    ..initialGap = 0
    ..middleGap = plain ? Shape.s(2) : WindowTokens.gutter
    ..gapBottomBorder = BorderSide.none
    ..dropColor = WindowTokens.accent.withValues(alpha: .35)
    ..normalButtonColor = Grey.g56
    ..hoverButtonColor = Grey.g91;
  t.tab
    // The padding is small enough for seven shelf tabs to fit a dock squeezed to 229 px by a 1280 px window.
    ..padding = EdgeInsets.fromLTRB(
      Shape.s(plain ? 4 : 8),
      Shape.s(5),
      Shape.s(plain ? 4 : 8),
      Shape.s(5),
    )
    ..margin = EdgeInsets.zero
    ..innerBottomBorder = null
    ..innerTopBorder = null
    ..textStyle = TextStyles.micro(Grey.g63)
        .copyWith(fontWeight: FontWeight.w600, letterSpacing: .6)
    ..decoration = plain
        ? const BoxDecoration()
        : BoxDecoration(color: WindowTokens.card)
    ..draggingDecoration = BoxDecoration(
      color: plain ? WindowTokens.body : WindowTokens.raised,
    )
    ..normalButtonColor = Grey.g56
    ..hoverButtonColor = Grey.g91
    ..selectedStatus = (TabStatusThemeData()
      ..decoration = plain
          ? const BoxDecoration()
          : BoxDecoration(
              color: WindowTokens.body,
              border: Border(
                bottom: BorderSide(color: WindowTokens.accentInk, width: 2),
              ),
            )
      ..fontColor = Grey.g95)
    ..highlightedStatus = (TabStatusThemeData()
      ..decoration = plain
          ? const BoxDecoration()
          : BoxDecoration(color: WindowTokens.raised)
      ..fontColor = Grey.g91);
  t.contentArea
    ..decoration = BoxDecoration(color: WindowTokens.body)
    ..padding = EdgeInsets.zero;
  return t;
}

/// A pane's name is its id in a written layout.
class _Ids with LayoutParserMixin {
  const _Ids();
}

/// Builds a written layout's panes back from their names.
class _Areas with AreaBuilderMixin {
  _Areas(this._panes);
  final _PanesState _panes;
  @override
  DockingItem buildDockingItem({
    required dynamic id,
    required double? weight,
    required bool maximized,
  }) => _panes._item(
    _panes.widget.panes.firstWhere((p) => p.name == id),
    weight: weight,
  );
}
