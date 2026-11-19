// The engine's load in the top bar, as a mixer shows its CPU: how much of a frame's time the render thread and the
// GPU each take.
import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/workspace/state/document/document_reads.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// Two bars, CPU and GPU, each the part of one frame's time the engine took, read twice a second.
class LoadMeter extends StatefulWidget {
  const LoadMeter({super.key});
  @override
  State<LoadMeter> createState() => _LoadMeterState();
}

class _LoadMeterState extends State<LoadMeter> {
  late final Timer _look;
  // Whole per cents as shown (the render thread's mean and most, the GPU's): built again only when one differs.
  (int, int, int) _shown = (0, 0, 0);

  @override
  void initState() {
    super.initState();
    _look = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final load = engineLoadTaken(WorkspaceScope.read(context));
      // No frame drawn since the last look: the engine is at rest.
      final next = load == null
          ? (0, 0, 0)
          : (
              (load.cpu * 100).round(),
              (load.cpuMost * 100).round(),
              (load.gpu * 100).round(),
            );
      if (next != _shown && mounted) setState(() => _shown = next);
    });
  }

  @override
  void dispose() {
    _look.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(right: Shape.s(10)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadBar(label: 'CPU', percent: _shown.$1, most: _shown.$2),
        SizedBox(width: Shape.s(8)),
        LoadBar(label: 'GPU', percent: _shown.$3),
      ],
    ),
  );
}

/// One load: its name, a bar filled to [percent] of a frame's time with a tick at [most], and the number.
/// At 100 the frame's time is used up, and the bar and number turn to the alert colour.
class LoadBar extends StatelessWidget {
  const LoadBar({
    super.key,
    required this.label,
    required this.percent,
    this.most,
  });
  final String label;
  final int percent;
  final int? most;

  static double get numberWide => Shape.z(32);

  @override
  Widget build(BuildContext context) {
    final over = percent >= 100 || (most ?? 0) >= 100;
    final ink = over
        ? ColorTheme.of('Alert', const Color(0xFFE5484D))
        : Grey.g63;
    final wide = Shape.z(28), high = Shape.z(4);
    return Semantics(
      label: '$label $percent%',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyles.label(Grey.g63)),
          SizedBox(width: Shape.s(4)),
          SizedBox(
            width: wide,
            height: high,
            child: Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: Grey.g26)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: wide * (percent / 100).clamp(0, 1),
                  child: ColoredBox(color: ink),
                ),
                if (most case final most? when most > percent)
                  Positioned(
                    left: (wide - 1) * (most / 100).clamp(0, 1),
                    top: 0,
                    bottom: 0,
                    width: 1,
                    child: ColoredBox(color: Grey.g91),
                  ),
              ],
            ),
          ),
          SizedBox(width: Shape.s(4)),
          // As wide as three digits, so the bar keeps its place while the number changes.
          SizedBox(
            width: numberWide,
            child: Text(
              '$percent%',
              textAlign: TextAlign.right,
              maxLines: 1,
              softWrap: false,
              style: TextStyles.label(ink),
            ),
          ),
        ],
      ),
    );
  }
}
