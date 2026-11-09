// The chip the window's headers use, and the empty list of tool-panel tools.
import 'package:flutter/widgets.dart';

import '../../inspector/inspector_parts.dart' show Hov;
import '../../skin/tokens.dart';
import '../state/state.dart';

/// One tool the tool panel can hold. Tools of your own: Workspace(tools: [PanelTool(...)]).
class PanelTool {
  const PanelTool(this.name, this.tone, this.acts, {this.build});
  final String name, acts;
  final Color tone;
  final Widget Function()? build;
}

final panelTools = <PanelTool>[];

/// A round header chip: a mark and a word. [onTap] makes it a button.
class ToolChip extends StatelessWidget {
  const ToolChip({super.key, required this.label, this.dot, this.onTap, this.on = false});
  final String label;
  final Color? dot;
  final VoidCallback? onTap;
  final bool on;
  @override
  Widget build(BuildContext context) => Hov(
    onTap: onTap,
    cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
    builder: (_, h) => Container(
      height: Shape.z(18),
      padding: EdgeInsets.symmetric(horizontal: Shape.s(6)),
      decoration: BoxDecoration(color: on ? WsT.accent : (h && onTap != null ? WsT.raised : WsT.well), borderRadius: BorderRadius.all(Shape.r(WsT.chipRadius))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: Shape.z(6),
              height: Shape.z(6),
              decoration: BoxDecoration(color: on ? WsT.onAccent : dot, shape: BoxShape.circle),
            ),
            SizedBox(width: Shape.s(5)),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: T.micro(on ? WsT.onAccent : (h && onTap != null ? Grey.g95 : Grey.g76)),
            ),
          ),
        ],
      ),
    ),
  );
}
