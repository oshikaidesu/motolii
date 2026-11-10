// The layer name column: a header, and one row per layer with visibility, solo and lock toggles.
import 'package:flutter/widgets.dart';

import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/widgets/forms/forms.dart';
import 'package:motolii/widgets/glyphs.dart' show Glyph;
import 'package:motolii/widgets/panel_header.dart';
import 'package:motolii/widgets/timeline_painters.dart' show TimelineGlyphs;
import 'package:motolii/workspace/timeline/timeline_metrics.dart';
import 'package:motolii/workspace/timeline/timeline_paint.dart';

/// Header of the name column: layer count and the visibility, solo and lock icons.
class TimelineLabelHeader extends StatelessWidget {
  const TimelineLabelHeader({
    super.key,
    required this.count,
    required this.solo,
  });
  final int count;
  final bool solo;
  @override
  Widget build(BuildContext context) => PanelHeader(
    '',
    height: TimelineMetrics.ruler,
    color: Grey.g10,
    padding: EdgeInsets.only(left: Shape.s(8), right: Shape.s(6)),
    leading: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('#', style: TextStyles.micro(Grey.g56)),
        SizedBox(width: Shape.s(12)),
        Text(
          'LAYER',
          style: TextStyles.micro(Grey.g63).copyWith(letterSpacing: 1),
        ),
        SizedBox(width: Shape.s(6)),
        Text(
          '$count',
          style: TextStyles.value(Grey.g56)
              .copyWith(fontSize: TextStyles.px(10)),
        ),
      ],
    ),
    trailing: [
      for (final g in const [
        TimelineGlyphs.eye,
        TimelineGlyphs.solo,
        TimelineGlyphs.lock,
      ])
        SizedBox(
          width: Shape.z(20),
          child: Center(
            child: Glyph(
              g,
              size: 10,
              color: g == TimelineGlyphs.solo && solo
                  ? WindowTokens.accent
                  : Grey.g56,
            ),
          ),
        ),
    ],
  );
}

/// One layer's row in the name column.
class TimelineLabelRow extends StatefulWidget {
  const TimelineLabelRow({
    super.key,
    required this.index,
    required this.depth,
    required this.row,
    required this.hidden,
    required this.solo,
    required this.lanes,
    required this.onLanes,
    required this.onSelect,
    required this.onEye,
    required this.onSolo,
    required this.onLock,
  });
  final int index, depth;
  final TimelineRow row;
  final bool hidden, solo;
  final bool? lanes; // Whether its keyframed properties are expanded; null if the layer has no keyframes.
  final VoidCallback onLanes, onSelect, onEye, onSolo, onLock;
  @override
  State<TimelineLabelRow> createState() => _LabelRowState();
}

class _LabelRowState extends State<TimelineLabelRow> {
  bool _h = false;
  @override
  Widget build(BuildContext context) {
    final r = widget.row, sel = r.selected;
    return MouseRegion(
      onEnter: (_) => setState(() => _h = true),
      onExit: (_) => setState(() => _h = false),
      child: Forms.worn.track(
        context,
        TrackSpec(
          index: widget.index,
          name: r.name,
          selected: sel,
          dim: r.dim,
          hot: _h,
          onSelect: widget.onSelect,
          kind: Row(
            // A small thumbnail as in Alight Motion's rows, preceded by the expand triangle (After Effects' twirl) if the layer has keyframes.
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: Shape.z(10) * widget.depth), // Indent layers inside a group, as in Apple Motion's Layers list and Cavalry's tree.
              if (widget.lanes case final open?)
                _Toggle(
                  open ? TimelineGlyphs.caretD : TimelineGlyphs.caretR,
                  on: false,
                  lit: true,
                  onTap: widget.onLanes,
                )
              else
                SizedBox(width: Shape.z(20)),
              TimelineThumbnail(r),
            ],
          ),
          eye: _Toggle(
            widget.hidden ? TimelineGlyphs.eyeOff : TimelineGlyphs.eye,
            on: false,
            lit: !widget.hidden,
            onTap: widget.onEye,
          ),
          solo: _Toggle(
            TimelineGlyphs.solo,
            on: widget.solo,
            lit: _h || sel,
            onTap: widget.onSolo,
          ),
          lock: _Toggle(
            r.locked ? TimelineGlyphs.lock : TimelineGlyphs.unlock,
            on: false,
            lit: r.locked || _h || sel,
            strong: r.locked,
            onTap: widget.onLock,
          ),
        ),
      ),
    );
  }
}

/// A row toggle shown as a bare icon. [on] puts it on an accent chip, [strong] on a raised grey one.
class _Toggle extends StatelessWidget {
  const _Toggle(
    this.g, {
    required this.on,
    required this.lit,
    this.strong = false,
    required this.onTap,
  });
  final TimelineGlyphs g;
  final bool on, lit, strong;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => NakedButton(
    enableFeedback: false,
    onPressed: onTap,
    mouseCursor: MouseCursor.defer,
    child: SizedBox(
      width: Shape.z(20),
      height: TimelineMetrics.row - 1,
      child: Center(
        child: Container(
          width: Shape.z(17),
          height: Shape.z(17),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? WindowTokens.accent : (strong ? Grey.g26 : null),
            borderRadius: BorderRadius.all(Shape.r(WindowTokens.chipRadius)),
          ),
          child: Glyph(
            g,
            size: 10,
            color: on
                ? WindowTokens.onAccent
                : (strong ? Grey.g95 : (lit ? Grey.g76 : Grey.g38)),
          ),
        ),
      ),
    ),
  );
}
