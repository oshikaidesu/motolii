// Counts slow frames and engine errors, and lists them from the top bar.
import 'dart:async';
import 'dart:developer' show log;
import 'dart:math' as math;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart'
    show
        GestureBinding,
        PointerEvent,
        PointerPanZoomUpdateEvent,
        PointerScrollEvent;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/widgets.dart';

import 'package:naked_ui/naked_ui.dart';

import 'package:motolii/skin/theme.dart';
import 'package:motolii/skin/tokens.dart';
import 'package:motolii/skin/window_tokens.dart';
import 'package:motolii/workspace/state/document/document_reads.dart';
import 'package:motolii/workspace/state/workspace_scope.dart';

/// A red dot with a count of problems, shown only when there are any.
///
/// It counts frames longer than 1/60 s while something moved (in the app or the engine) and times the app waited
/// for the engine, which should never happen. A click lists the latest, each with its clock time and slow part.
class Waited extends StatefulWidget {
  const Waited({super.key});
  @override
  State<Waited> createState() => _WaitedState();
}

class _WaitedState extends State<Waited> {
  final _m = MenuController();
  late final Timer _look;
  final _born = Stopwatch()..start();
  // The number shown on the dot.
  int _count = 0,
          // The engine's error count as last read.
          _inside =
          0,
          // Engine errors that happened while the window was shown.
          _insideSeen =
          0,
          // Slow app frames counted so far.
          _lateCount =
          0,
          // Raster finish time of the previous frame, in microseconds.
          _lastFinish =
          0;
  // How many problems the list has already shown. The dot counts only newer ones, like an unread badge.
  int _seen = 0;
  // The engine whose errors are counted. A different engine starts counting again from 0.
  int _of = 0;
  // The project whose problems are counted. A different project starts again from 0.
  String? _doc;
  // True if playback ran, or a pointer was down or scrolling, since the last frame timings arrived.
  bool _moved = false;
  // The app's own slow frames, each with a time stamp. Only the last 200 are kept.
  final _late = <String>[];

  // One frame's budget at 60 fps, in microseconds, as Flutter's performance overlay judges it.
  static const _beat = 1000000 ~/ 60;
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
    _look = Timer.periodic(const Duration(milliseconds: 500), (_) {
      // Read the engine's error count without waiting for it.
      final ws = WorkspaceScope.read(context);
      _moved |= ws.playing;
      final n = engineBrokenCount(ws) ?? 0;
      if (engineIdOf(ws) != _of) {
        // The project was opened or reopened. Errors recorded before it was seen here are not counted.
        final doc = '${ws.documentFolder}/${ws.document}';
        if (doc != _doc) {
          // A different project: start again from 0.
          _doc = doc;
          _insideSeen = _lateCount = _seen = 0;
          _late.clear();
        }
        _of = engineIdOf(ws);
        _inside = n;
      }
      final shown = switch (WidgetsBinding.instance.lifecycleState) {
        AppLifecycleState.hidden || AppLifecycleState.paused => false,
        _ => true,
      };
      // Count engine errors only while the window is shown.
      final newBroken = math.max(0, n - _inside);
      if (shown && newBroken > 0) {
        log(engineBroken(ws) ?? '', name: 'engine.waited');
      }
      if (shown) _insideSeen += newBroken;
      _inside = n;
      _recount();
    });
  }

  void _pointer(PointerEvent e) {
    if (e.down || e is PointerScrollEvent || e is PointerPanZoomUpdateEvent) {
      _moved = true;
    }
  }

  /// Handles Flutter's per-frame timings ([FrameTiming]).
  ///
  /// A frame whose build (UI thread) or raster (raster thread) took longer than one frame budget missed 60 fps.
  /// A frame is counted only while something moves: it must start within two budgets of the previous frame's raster
  /// end while playing or while the user is interacting, and not in the first 3 seconds after launch.
  void _timings(List<FrameTiming> timings) {
    if (!mounted) return;
    final moved = _moved || WorkspaceScope.read(context).playing;
    _moved = false;
    if (timings.isEmpty) return;
    final now = DateTime.now(),
        last = timings.last.timestampInMicroseconds(FramePhase.rasterFinish);
    for (final f in timings) {
      final start = f.timestampInMicroseconds(FramePhase.vsyncStart),
          finish = f.timestampInMicroseconds(FramePhase.rasterFinish);
      final going = _lastFinish > 0 && start - _lastFinish <= 2 * _beat;
      _lastFinish = finish;
      final build = f.buildDuration.inMicroseconds,
          raster = f.rasterDuration.inMicroseconds;
      if (!moved ||
          !going ||
          _born.elapsed.inSeconds < 3 ||
          (build <= _beat && raster <= _beat)) {
        continue;
      }
      final at = now.subtract(Duration(microseconds: last - finish));
      String ms(int us) => (us / 1000).toStringAsFixed(1);
      final slow = [
        if (build > _beat) "the window's build ${ms(build)} ms",
        if (raster > _beat) "the window's raster ${ms(raster)} ms",
      ].join(', ');
      final line =
          '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}.${at.millisecond.toString().padLeft(3, '0')} '
          '$slow (build ${ms(build)}, raster ${ms(raster)}, all ${ms(f.totalSpan.inMicroseconds)})${kDebugMode ? ', a debug build: slower than the app' : ''}';
      _late.add(line);
      log(line, name: 'timings.slow');
      if (_late.length > 200) _late.removeAt(0);
      _lateCount++;
    }
    _recount();
  }

  void _recount() {
    final all = _insideSeen + _lateCount;
    // While the list is open, every line in it counts as seen.
    if (_m.isOpen) _seen = all;
    final n = all - _seen;
    // While the list is open, rebuild so new lines appear as they come.
    if ((n != _count || _m.isOpen) && mounted) setState(() => _count = n);
  }

  @override
  void dispose() {
    _look.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointer);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0 && !_m.isOpen) return const SizedBox.shrink();
    // naked_ui's NakedPopover owns the open and shut state: a press on the dot toggles it, a press elsewhere or Esc closes it,
    // and a tap elsewhere still reaches what is under it, like a transient NSPopover on macOS.
    return NakedPopover(
      controller: _m,
      consumeOutsideTaps: false,
      positioning: OverlayPositionConfig(
        side: OverlaySide.bottom,
        alignment: OverlayAlignment.end,
        sideOffset: Shape.s(6),
      ),
      onOpen: _recount,
      onClose: _recount,
      popoverBuilder: (context, info) {
        // The engine's and the app's lines, newest first. Each line starts with its clock time.
        final lines = ([
          ...(engineBroken(WorkspaceScope.read(context)) ?? '')
              .split('\n')
              .where((l) => l.isNotEmpty),
          ..._late,
        ]..sort((a, b) => b.compareTo(a))).take(40).toList();
        return Container(
          width: Shape.z(520),
          constraints: BoxConstraints(
            maxHeight: info.overlaySize.height * .7,
          ), // Lines wrap rather than being cut, and a long list scrolls.
          padding: EdgeInsets.all(Shape.s(10)),
          decoration: BoxDecoration(
            color: WindowTokens.card,
            borderRadius: BorderRadius.all(Shape.r(6)),
            border: Border.all(color: Grey.g26),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final l in lines)
                  Padding(
                    padding: EdgeInsets.only(bottom: Shape.s(3)),
                    child: Text(
                      l,
                      softWrap: true,
                      style: TextStyles.micro(Grey.g76),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      builder: (_, st, _) => Padding(
        padding: EdgeInsets.only(right: Shape.s(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Shape.z(6),
              height: Shape.z(6),
              decoration: BoxDecoration(
                color: ColorTheme.of('Alert', const Color(0xFFE5484D)),
                shape: BoxShape.circle,
              ),
            ),
            if (_count > 0) ...[
              SizedBox(width: Shape.s(5)),
              Text(
                '$_count',
                style: TextStyles.label(st.isHovered ? Grey.g91 : Grey.g63),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
