part of 'dock_widgets.dart';

/// The shelves' list row (Media's folder, Effects' place): [depth] indent, a chevron slot ([open] null: none; [onToggle]: the chevron itself
/// presses), [glyph] or a [cover] picture (a taller row, [sub] under the name), [name] given the ink and weight, [field] in its place, [count].
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
