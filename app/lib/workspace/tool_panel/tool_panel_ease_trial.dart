// Plays an easing when there is no segment to apply it to.
//
// It runs once when the easing changes, and repeatedly while the pointer is over the graph, as the curves on easings.net do.
// It stops by itself, so a panel left alone with nothing picked uses no frames.
import 'package:flutter/widgets.dart';

/// Calls [builder] with the progress of a looping preview of [way].
class EaseTrial extends StatefulWidget {
  const EaseTrial({super.key, required this.way, required this.builder});

  /// The easing to preview. A change restarts the run.
  final String way;

  /// Builds the child. The argument is the progress from 0 to 1 along the easing, or null when no run is playing.
  final Widget Function(double? at) builder;
  @override
  State<EaseTrial> createState() => _EaseTrialState();
}

class _EaseTrialState extends State<EaseTrial>
    with SingleTickerProviderStateMixin {
  late final _run = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..addStatusListener(_ended);
  bool _over = false;

  void _ended(AnimationStatus s) {
    if (s == AnimationStatus.completed && _over) _run.forward(from: 0);
  }

  void _start() => _run.forward(from: 0);

  @override
  void didUpdateWidget(EaseTrial old) {
    super.didUpdateWidget(old);
    if (old.way != widget.way) _start();
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      _over = true;
      if (!_run.isAnimating) _start();
    },
    onExit: (_) => _over = false,
    // The progress is scaled by 1.2 and clamped, so the end value is held briefly before the run stops.
    child: AnimatedBuilder(
      animation: _run,
      builder: (_, _) => widget.builder(
        _run.isAnimating ? (_run.value * 1.2).clamp(0.0, 1.0) : null,
      ),
    ),
  );
}
