// The middle of the Ease tool: the easing graph, with the text of where it is (the stretch it edits, or that it is only trying), why a
// write failed, the numbers of the card, and the two buttons that step to the previous and the next stretch.
import 'package:flutter/widgets.dart';

import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/easing/ease.dart';
import 'package:motolii/workspace/easing/ease_text.dart';
import 'package:motolii/workspace/state/workspace_controller.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_numbers.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_side.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_tool.dart';
import 'package:motolii/workspace/tool_panel/ease/ease_trial.dart';

class EaseGraphPanel extends StatelessWidget {
  const EaseGraphPanel({
    super.key,
    required this.ws,
    required this.span,
    required this.ease,
    required this.graph,
    required this.trouble,
    required this.numbersCard,
    required this.onChanged,
    required this.overshoot,
    required this.onOvershoot,
  });
  final WorkspaceController ws;

  /// The stretch being edited, or null when the panel only tries an easing.
  final EaseSpan? span;

  /// The easing, to try on the graph when there is no stretch.
  final Ease ease;

  /// The graph for a frame (and, when only trying, for the moment of the trial).
  final Widget Function(int frame, [double? trial]) graph;

  /// Why the last write failed, or null.
  final String? trouble;

  /// The card whose numbers are shown, and what to do when one is changed or overshoot is turned on or off.
  final Ease numbersCard;
  final ValueChanged<Ease> onChanged;
  final bool overshoot;
  final VoidCallback onOvershoot;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: WindowTokens.well,
    child: Stack(
      children: [
        Positioned.fill(
          child: span == null
              ? EaseTrial(
                  way: said(ease),
                  builder: (trial) => graph(ws.frame, trial),
                )
              : ValueListenableBuilder<int>(
                  valueListenable: ws.moment,
                  builder: (_, frame, _) => graph(frame),
                ),
        ),
        if (span == null && ws.inside != null)
          Positioned(
            left: Shape.s(6),
            top: Shape.s(4),
            right: Shape.s(6),
            child: IgnorePointer(
              child: Text(
                'Trying here. Pick a key to go on a stretch',
                key: const ValueKey('ease-no-span'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.micro(Grey.g63),
              ),
            ),
          ),
        if (trouble case final why?)
          Positioned(
            left: Shape.s(4),
            right: Shape.s(4),
            top: Shape.s(2),
            child: Text(
              why,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.label(Grey.g63),
            ),
          ),
        if (span case final s?)
          Positioned(
            left: Shape.s(6),
            top: Shape.s(4),
            right: Shape.s(6),
            child: IgnorePointer(
              child: Text(
                '${s.layer.name}  ${s.from} → ${s.to}',
                key: const ValueKey('ease-span'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.micro(Grey.g63),
              ),
            ),
          ),
        Positioned.fill(
          child: EaseNumbers(
            card: numbersCard,
            onChanged: onChanged,
            overshoot: overshoot,
            onOvershoot: onOvershoot,
          ),
        ),
        Positioned(
          left: Shape.s(2),
          bottom: Shape.s(2),
          child: EaseStep(span: span, back: true),
        ),
        Positioned(
          right: Shape.s(2),
          bottom: Shape.s(2),
          child: EaseStep(span: span, back: false),
        ),
      ],
    ),
  );
}
