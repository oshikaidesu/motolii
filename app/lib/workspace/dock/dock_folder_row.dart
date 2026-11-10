import 'package:flutter/widgets.dart';

import 'package:motolii/skin/forms/forms.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/app_glyphs.dart';
import 'package:motolii/widgets/controls.dart' show Hov;
import 'package:motolii/workspace/shelf/tile_colors.dart';
import 'package:motolii/workspace/shelf/tile_hover.dart';

/// A list row for the shelves, such as a folder in Media or a place in Effects.
///
/// [depth] indents the row. [open] shows a chevron (null shows none) and [onToggle] is called when the chevron is clicked.
/// A [glyph] or a [cover] image leads the row, and a [cover] makes the row taller with [sub] under the name.
/// [name] builds the name from the ink and weight the row chooses. [field] replaces the name, and [count] is shown at the end.
Widget dockFolderRow({
  Key? key,
  required bool here,
  required DockG glyph,
  required Widget Function(TextStyle) name,
  VoidCallback? onTap,
  ValueChanged<Offset>? onMenu,
  int depth = 0,
  bool? open,
  VoidCallback? onToggle,
  Color? glyphInk,
  Color? rest,
  bool bold = false,
  int? count,
  Widget? cover,
  String? sub,
  Widget? field,
}) => DockHover(
  key: key,
  onMenu: onMenu,
  onTap: onTap,
  builder: (context, h) {
    final style = T.name(dockInk(here, rest)).copyWith(fontWeight: bold || here ? FontWeight.w600 : FontWeight.w400);
    final slot = SizedBox(
      width: Shape.z(14),
      height: Shape.z(22),
      child: open == null
          ? null
          : AnimatedRotation(
              turns: open ? .25 : 0,
              duration: Mo.dur,
              curve: Mo.ease,
              child: Glyph(DockG.chevron, size: Shape.z(7), color: dockInk(here, Grey.g63)),
            ),
    );
    return AnimatedContainer(
      duration: Mo.dur,
      curve: Mo.ease,
      height: Shape.z(cover == null ? 22 : 34),
      padding: EdgeInsets.only(left: Shape.s(4) + depth * Shape.s(12.0), right: WsT.inset),
      color: dockFill(here, h),
      child: Row(
        children: [
          onToggle == null ? slot : Hov(cursor: MouseCursor.defer, onTap: onToggle, builder: (_, _) => slot),
          if (cover != null)
            SizedBox.square(dimension: Shape.z(28), child: cover)
          else
            Glyph(glyph, size: Shape.z(12), color: here ? WsT.onAccent : glyphInk ?? Grey.g63),
          SizedBox(width: Shape.s(6)),
          Expanded(
            child:
                field ??
                (cover == null
                    ? name(style)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          name(style),
                          Text(sub ?? '', maxLines: 1, style: T.micro(dockInk(here, Grey.g56))),
                        ],
                      )),
          ),
          if (count != null && cover == null) Text('$count', style: T.value(dockInk(here, Grey.g56)).copyWith(fontSize: T.px(10))),
        ],
      ),
    );
  },
);

/// A row of round filter chips with counts; the active one is the accent. Scrolls sideways when the shelf is narrow.
class DockChips extends StatelessWidget {
  const DockChips(this.chips, {super.key, required this.active, required this.onPick});
  final List<(String, int?)> chips;
  final String active;
  final ValueChanged<String> onPick;
  @override
  Widget build(BuildContext context) => Forms.worn.chips(context, ChipsSpec(chips: chips, active: active, onPick: onPick));
}
